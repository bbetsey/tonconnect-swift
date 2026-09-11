import Foundation
import Combine

/// The public TON Connect facade. Engine-agnostic: holds an injected
/// any TonConnectEngine (swapping the core is a one-line composition-root change).
/// Calls restore itself on creation (state passes through .restoring).
/// A single observable enum state. Methods are Task-cancellable; every wallet
/// round trip also takes an optional `timeout:`, nil by default (no deadline).
@MainActor
public final class TonConnect: ObservableObject {
    @Published public private(set) var state: ConnectionState = .disconnected
    /// Observable state of the current send/sign operation. nil — no operation.
    @Published public private(set) var operation: OperationState? = nil
    /// True once the current operation's request reached the bridge. The UI must
    /// not wake the wallet before this (SDK parity: onRequestSent).
    @Published public private(set) var isOperationRequestSent = false
    /// The connect link of the current connection attempt (for QR). nil outside a connect.
    @Published public private(set) var connectLink: URL? = nil
    /// The connected wallet's app name (DeviceInfo.appName from the reply) — for the UI.
    @Published public private(set) var connectedWalletName: String? = nil
    private var lastOperation: (@Sendable () async -> Void)? = nil

    /// Shorthand for `state`: is a wallet connected right now?
    public var isConnected: Bool { state.isConnected }
    /// The connected wallet's account, or nil when there is no live session.
    public var account: Account? { state.account }
    /// Where the wallet should send the user after approving or rejecting a
    /// request. Note that on iOS a wallet is free to ignore this.
    public let returnStrategy: ReturnStrategy
    /// Whether the UI opens the wallet itself once the bridge accepted a request
    /// (SDK parity: onRequestSent → redirectAfterRequestSent). Wallets of the
    /// MyTonWallet family (My Wallet, Gram Wallet) mishandle that wake: a deeplink
    /// without a connect payload puts them into a "waiting for request"
    /// placeholder that replaces the real request screen, so the user sees a
    /// skeleton and eventually "Dapp Not Responding" (observed on a live wallet; the same
    /// flow completes cleanly when the user switches to the wallet by hand).
    /// A consumer targeting those wallets can turn this off — the request still
    /// reaches the bridge and the wallet picks it up on its own terms.
    public let opensWalletAutomatically: Bool

    private let engine: any TonConnectEngine
    private var eventTask: Task<Void, Never>?

    /// Builds the facade around an engine.
    ///
    /// - Parameters:
    ///   - engine: the protocol implementation to drive. `TonConnectSDK` offers
    ///     `init(manifestUrl:)`, which builds the default engine for you.
    ///   - returnStrategy: where a wallet should return the user after a request.
    ///   - autoRestore: restore a stored session on creation (the default). Turn
    ///     it off in tests and previews, where a live session is not wanted.
    ///   - opensWalletAutomatically: whether the UI jumps into the wallet itself
    ///     once the bridge has accepted a request.
    public init(
        engine: any TonConnectEngine,
        returnStrategy: ReturnStrategy = .back,
        autoRestore: Bool = true,
        opensWalletAutomatically: Bool = true
    ) {
        self.engine = engine
        self.returnStrategy = returnStrategy
        self.opensWalletAutomatically = opensWalletAutomatically
        subscribeToEvents()
        if autoRestore { Task { await self.restore() } }
    }

    deinit { eventTask?.cancel() }

    /// Restore at startup. Success WITHOUT an event leaves .restoring — the
    /// account arrives via the engine's .connected event pump; failure → .disconnected.
    public func restore() async {
        state = .restoring
        do {
            try await engine.restoreConnection()
        } catch {
            // Race (observed in practice): the .connected event from the pump may land
            // EARLIER than restore finishes — do not clobber the winning state.
            if !state.isConnected { state = .disconnected }
        }
    }

    /// Connects to one chosen wallet: opens it with a connect link and waits for
    /// the reply over the bridge. Throws if the wallet refuses, the attempt is
    /// cancelled or `timeout` passes; on success `state` becomes `.connected`
    /// and `account` is filled.
    ///
    /// - Parameters:
    ///   - source: the wallet to open — its universal link and bridge URL.
    ///   - items: what to ask the wallet for; `.tonAddress` at the least.
    ///   - timeout: how long to wait for the wallet, counted from this call and
    ///     including the time the user spends in the wallet app. `nil`, the
    ///     default, waits as long as it takes. See ``sendTransaction(_:timeout:)``.
    public func connect(source: WalletConnectionSource, items: [ConnectItem],
                        timeout: Duration? = nil) async throws {
        connectLink = nil
        state = .connecting
        do {
            let event = try await Self.withTimeout(timeout) { [engine] in
                try await engine.connect(source: source, items: items)
            }
            state = Self.stateFromConnectEvent(event) ?? .disconnected
            connectedWalletName = Self.walletName(from: event) ?? connectedWalletName
            connectLink = nil
        } catch {
            state = .disconnected
            connectLink = nil
            throw error
        }
    }
    
    /// "Second device" QR connect: the link is published to connectLink, no wallet
    /// is opened on this device. The reply arrives over the bridge.
    ///
    /// - Parameters:
    ///   - bridgeURLs: the bridges of every wallet the QR should reach; the first
    ///     one to answer wins.
    ///   - items: what to ask the wallet for; `.tonAddress` at the least.
    ///   - timeout: how long to keep the QR offer open. `nil`, the default,
    ///     waits as long as it takes. See ``sendTransaction(_:timeout:)``.
    public func connectWithQR(bridgeURLs: [String], items: [ConnectItem],
                              timeout: Duration? = nil) async throws {
        connectLink = nil
        state = .connecting
        do {
            let event = try await Self.withTimeout(timeout) { [engine] in
                try await engine.connectUniversal(bridgeURLs: bridgeURLs, items: items)
            }
            state = Self.stateFromConnectEvent(event) ?? .disconnected
            connectedWalletName = Self.walletName(from: event) ?? connectedWalletName
            connectLink = nil
        } catch {
            state = .disconnected
            connectLink = nil
            throw error
        }
    }

    /// Asks the wallet to send a transaction, and waits for the user's answer.
    ///
    /// A refusal is NOT thrown: it comes back as `WalletResponse.error`, because
    /// "the user said no" is an outcome, not a failure. Throwing is reserved for
    /// the request never getting an answer at all. `operation` tracks the whole
    /// round trip for the UI.
    /// A retry repeats THIS payload verbatim, `validUntil` included. When the
    /// payload carries an expiry, take the closure overload below instead.
    ///
    /// - Parameters:
    ///   - payload: the transaction, sent as is; `from` is filled from the
    ///     connected account when left `nil`.
    ///   - timeout: how long to wait for the wallet's answer, counted from this
    ///     call. `nil`, the default, waits as long as it takes — a wallet request
    ///     has no natural deadline, and only cancelling the calling Task ends the
    ///     wait. With a deadline, the clock covers the whole round trip: reaching
    ///     the bridge, the user switching to the wallet, reading and approving the
    ///     request, and the reply coming back. So it is a budget for a person, not
    ///     for a network call — minutes, not seconds. When it passes, the request
    ///     is cancelled and ``TonConnectError/timeout(after:)`` is thrown;
    ///     `operation` shows a connection problem with a Retry, which repeats the
    ///     request under the same deadline.
    public func sendTransaction(_ payload: SendTransactionPayload,
                                timeout: Duration? = nil) async throws -> WalletResponse {
        try await sendTransaction(timeout: timeout) { payload }
    }

    /// Same request, but the payload is built at the moment of sending — including
    /// when ``retryLastOperation()`` sends it again.
    ///
    /// Reach for this overload whenever the payload holds anything time-dependent,
    /// `validUntil` above all. A retry can land minutes after the first attempt:
    /// the user has to notice the failure, and a connection problem is exactly the
    /// situation where they put the phone down and come back. Replaying a captured
    /// `validUntil` then sends a transaction the wallet is obliged to reject as
    /// expired — and the user is told "declined" with no way to guess why.
    ///
    /// ```swift
    /// try await tonConnect.sendTransaction {
    ///     SendTransactionPayload(validUntil: Int(Date().timeIntervalSince1970) + 300,
    ///                            network: account.network, from: nil, messages: messages)
    /// }
    /// ```
    ///
    /// `timeout` is the same optional deadline as on ``sendTransaction(_:timeout:)``.
    public func sendTransaction(
        timeout: Duration? = nil,
        _ makePayload: @escaping @Sendable () -> SendTransactionPayload
    ) async throws -> WalletResponse {
        operation = .pending(kind: .sendTransaction)
        isOperationRequestSent = false
        lastOperation = { [weak self] in
            _ = try? await self?.sendTransaction(timeout: timeout, makePayload)
        }
        do {
            let response = try await Self.withTimeout(timeout) { [engine] in
                try await engine.sendTransaction(makePayload())
            }
            if case .error(let code, let message, _) = response {
                operation = .failure(fromWalletResponseError: code, message: message)
            } else {
                operation = .success(kind: .sendTransaction)
            }
            return response
        } catch {
            operation = .failure(from: error)
            throw error
        }
    }

    /// Asks the wallet to sign text, raw bytes or a cell. Same contract as
    /// ``sendTransaction(_:timeout:)``: a refusal arrives as `WalletResponse.error`,
    /// and `timeout` is the same optional deadline.
    public func signData(_ payload: SignDataPayload,
                         timeout: Duration? = nil) async throws -> WalletResponse {
        try await signData(timeout: timeout) { payload }
    }

    /// Same request, but the payload is built at the moment of signing — including
    /// on a retry. See the closure overload of `sendTransaction` for why a
    /// captured payload can go stale between the first attempt and the second.
    public func signData(
        timeout: Duration? = nil,
        _ makePayload: @escaping @Sendable () -> SignDataPayload
    ) async throws -> WalletResponse {
        operation = .pending(kind: .signData)
        isOperationRequestSent = false
        lastOperation = { [weak self] in
            _ = try? await self?.signData(timeout: timeout, makePayload)
        }
        do {
            let response = try await Self.withTimeout(timeout) { [engine] in
                try await engine.signData(makePayload())
            }
            if case .error(let code, let message, _) = response {
                operation = .failure(fromWalletResponseError: code, message: message)
            } else {
                operation = .success(kind: .signData)
            }
            return response
        } catch {
            operation = .failure(from: error)
            throw error
        }
    }

    /// Toast swipe/tap/auto-hide.
    public func clearOperation() { operation = nil }

    /// NetworkProblem's "Retry" button repeats the last operation.
    /// operation is NOT reset: the sheet lives continuously networkProblem → pending,
    /// without a dismissal blink (sheet dismiss/present across a nil gap).
    public func retryLastOperation() {
        let op = lastOperation
        connectLink = nil
        Task { await op?() }
    }
    
    /// Ends the session from our side: tells the wallet, drops the stored session
    /// and resets every observable property to the disconnected state.
    public func disconnect() async throws {
        try await engine.disconnect()
        state = .disconnected
        operation = nil // the operation dies with the session — no dangling toast
        isOperationRequestSent = false
        lastOperation = nil // a retry without a session is meaningless
        connectLink = nil // the QR link is dead without a session too
        connectedWalletName = nil
    }

    // MARK: - deadline

    /// Runs one wallet round trip under an optional deadline.
    ///
    /// `nil` is the old contract unchanged: the engine call is awaited directly
    /// and only cancelling the calling Task ends it. With a deadline the call
    /// races a timer in a task group; the first to finish wins and the other is
    /// cancelled. Both engines honour cancellation by resolving their pending
    /// ticket, so a timed-out request does not linger — a wallet that answers
    /// after the deadline is ignored, exactly as after a cancel. Cancelling the
    /// calling Task still works: the group's children are cancelled with it.
    private static func withTimeout<T: Sendable>(
        _ timeout: Duration?,
        _ operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        guard let timeout else { return try await operation() }
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw TonConnectError.timeout(after: timeout)
            }
            defer { group.cancelAll() } // the loser, whichever it is
            // Two children were added, so the first result cannot be nil.
            return try await group.next()!
        }
    }

    // MARK: - events (the single source of wallet-initiated events)
    private func subscribeToEvents() {
        eventTask = Task { [weak self] in
            guard let events = self?.engine.events else { return }
            for await event in events {
                self?.handle(event)
            }
        }
    }
    private func handle(_ event: TonConnectEvent) {
        switch event {
        case .connected(let connectEvent):
            state = Self.stateFromConnectEvent(connectEvent) ?? state
            connectedWalletName = Self.walletName(from: connectEvent) ?? connectedWalletName
        case .disconnected:
            state = .disconnected // wallet-initiated — no method call involved
            operation = nil
            isOperationRequestSent = false
            lastOperation = nil
            connectLink = nil
            connectedWalletName = nil
        case .transactionResponse:
            break
        case .connectLinkGenerated(let url):
            connectLink = url
        case .requestSent:
            isOperationRequestSent = true
        }
    }

    /// ConnectEvent.success with ton_addr → .connected(Account); connect_error → nil.
    static func stateFromConnectEvent(_ event: ConnectEvent) -> ConnectionState? {
        guard case .success(_, let payload, _) = event else { return nil }
        for item in payload.items {
            if case .tonAddress(let reply) = item {
                return .connected(Account(
                    address: reply.address, network: reply.network,
                    publicKey: reply.publicKey, walletStateInit: reply.walletStateInit))
            }
        }
        return nil
    }
    
    /// Wallet name from ConnectEvent.success (spec: DeviceInfo.appName).
    /// An empty name (sparse DeviceInfo) yields nil so the UI keeps its fallback.
    static func walletName(from event: ConnectEvent) -> String? {
        guard case .success(_, let payload, _) = event else { return nil }
        return payload.device.appName.isEmpty ? nil : payload.device.appName
    }
}
