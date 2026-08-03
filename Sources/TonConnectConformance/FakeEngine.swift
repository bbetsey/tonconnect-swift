import Foundation
import TonConnectCore

/// Deterministic hand-rolled test double: canned responses, call recording,
/// event injection. Deliberately no mocking framework.
public final class FakeEngine: TonConnectEngine, @unchecked Sendable {
    public let events: AsyncStream<TonConnectEvent>

    private let eventContinuation: AsyncStream<TonConnectEvent>.Continuation
    private let lock = NSLock()
    private var _recordedCalls: [String] = []
    private var _hasSavedSession = false
    private var _lastConnectSource: WalletConnectionSource?
    private var _lastConnectItems: [ConnectItem] = []
    private var _lastSentTransaction: SendTransactionPayload?

    /// Canned responses — set before use; a test double is single-threaded per test.
    public var cannedConnectEvent: ConnectEvent
    public var cannedSendTransactionResponse: WalletResponse
    public var cannedSignDataResponse: WalletResponse

    public var recordedCalls: [String] {
        lock.lock(); defer { lock.unlock() }
        return _recordedCalls
    }

    public var hasSavedSession: Bool {
        lock.lock(); defer { lock.unlock() }
        return _hasSavedSession
    }

    /// The payload of the most recent sendTransaction — lets a test tell a resent
    /// payload apart from a rebuilt one.
    public var lastSentTransaction: SendTransactionPayload? {
        lock.lock(); defer { lock.unlock() }
        return _lastSentTransaction
    }

    public var lastConnectSource: WalletConnectionSource? {
        lock.lock(); defer { lock.unlock() }
        return _lastConnectSource
    }

    public var lastConnectItems: [ConnectItem] {
        lock.lock(); defer { lock.unlock() }
        return _lastConnectItems
    }

    public init(
        cannedConnectEvent: ConnectEvent = FakeEngine.defaultConnectEvent,
        cannedSendTransactionResponse: WalletResponse = .success(result: "te6ccFakeBoc", id: "1"),
        cannedSignDataResponse: WalletResponse = .error(code: .userDeclined, message: "user declined", id: "2")
    ) {
        var continuation: AsyncStream<TonConnectEvent>.Continuation!
        self.events = AsyncStream { continuation = $0 }
        self.eventContinuation = continuation
        self.cannedConnectEvent = cannedConnectEvent
        self.cannedSendTransactionResponse = cannedSendTransactionResponse
        self.cannedSignDataResponse = cannedSignDataResponse
    }

    /// Spec-shaped default: one ton_addr reply + minimal DeviceInfo (testnet).
    public static let defaultConnectEvent = ConnectEvent.success(
        id: 1,
        payload: ConnectSuccessPayload(
            items: [.tonAddress(TonAddressItemReply(
                address: "0:fake",
                network: "-3",
                publicKey: "deadbeef",
                walletStateInit: "te6ccFakeInit"
            ))],
            device: DeviceInfo(
                platform: .iphone,
                appName: "FakeWallet",
                appVersion: "1.0.0",
                maxProtocolVersion: 2,
                features: [.sendTransaction(maxMessages: 4, extraCurrencySupported: nil, itemTypes: nil)]
            )
        ),
        response: nil
    )

    /// Event injection: pushes a wallet-initiated event into the stream.
    public func inject(_ event: TonConnectEvent) {
        eventContinuation.yield(event)
    }

    public func connect(source: WalletConnectionSource, items: [ConnectItem]) async throws -> ConnectEvent {
        lock.lock()
        _recordedCalls.append("connect")
        _lastConnectSource = source
        _lastConnectItems = items
        _hasSavedSession = true
        lock.unlock()
        if let url = URL(string: source.universalLink) {
            eventContinuation.yield(.connectLinkGenerated(url))
        }
        return cannedConnectEvent
    }
    
    public func connectUniversal(bridgeURLs: [String], items: [ConnectItem]) async throws -> ConnectEvent {
        lock.lock()
        _recordedCalls.append("connectUniversal")
        _hasSavedSession = true
        lock.unlock()
        eventContinuation.yield(.connectLinkGenerated(URL(string: "tc://fake-universal")!))
        return cannedConnectEvent
    }

    public func restoreConnection() async throws {
        lock.lock()
        _recordedCalls.append("restore")
        let hasSession = _hasSavedSession
        lock.unlock()
        guard hasSession else {
            throw TonConnectError.decodeFailure("no saved session to restore")
        }
    }

    public func sendTransaction(_ payload: SendTransactionPayload) async throws -> WalletResponse {
        lock.lock()
        _recordedCalls.append("sendTransaction")
        _lastSentTransaction = payload
        lock.unlock()
        return cannedSendTransactionResponse
    }

    public func signData(_ payload: SignDataPayload) async throws -> WalletResponse {
        lock.lock()
        _recordedCalls.append("signData")
        lock.unlock()
        return cannedSignDataResponse
    }

    public func disconnect() async throws {
        lock.lock()
        _recordedCalls.append("disconnect")
        _hasSavedSession = false
        lock.unlock()
        eventContinuation.yield(.disconnected)
    }
}
