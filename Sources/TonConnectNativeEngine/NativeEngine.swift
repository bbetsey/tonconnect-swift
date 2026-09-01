import Foundation
import os
import TonConnectCore
import TonConnectTransport
#if canImport(UIKit)
import UIKit
#endif

/// Stage 2 native engine: TonConnectEngine WITHOUT JavaScriptCore —
/// a thin composition of this phase's building blocks: ReconnectGateway
/// (SSE + reconnect), RPCEnvelope (codec), SessionCrypto (NaCl box),
/// NativeSessionStore (persistence), NativeErrorMapper (error boundary).
/// Discipline mirrors JSCoreEngine: synchronous connect prefix,
/// continuation-under-lock with honest cancellation, single event stream.
public final class NativeEngine: TonConnectEngine, @unchecked Sendable {

    public let events: AsyncStream<TonConnectEvent>
    private let eventContinuation: AsyncStream<TonConnectEvent>.Continuation

    private let manifestUrl: String
    private let store: NativeSessionStore
    /// One subsystem for everything this package logs, so a consumer can filter
    /// our noise out of theirs in one predicate.
    private static let log = Logger(subsystem: "tonconnect-swift", category: "Session")
    private let opener: any WalletOpener
    private let returnStrategy: ReturnStrategy
    private let sessionConfiguration: URLSessionConfiguration
    private let clock: any ReconnectClock
    /// One session for every bridge POST: a fresh URLSession per request forces a
    /// new DNS+TLS handshake each time, which costs seconds on mobile links.
    private let fetch: NativeFetch

    private let lock = NSLock()
    private var pendingConnect: CheckedContinuation<ConnectEvent, Error>?
    private var sessionCrypto: SessionCrypto?
    private var gateway: ReconnectGateway?
    /// The wallet's session client_id = envelope `from` (bundle.js:4017), NOT the account key.
    private var walletPublicKey: [UInt8]?
    /// Account address (ton_addr reply) of the active session — used to auto-fill
    /// `from` in sendTransaction (JS SDK parity, bundle.js:6009).
    private var accountAddress: String?
    private var currentBridgeUrl: String?
    private var lastWalletEventId: Int?
    private var lifecycleObservers: [NSObjectProtocol] = []

    /// FIFO persistence chain: store writes execute strictly in enqueue order.
    /// Independent Tasks would race each other: clear() could land between an
    /// update operation's load and save — and the save would "resurrect" the
    /// deleted session (a lost-update race, observed in practice).
    private var persistChain: Task<Void, Never> = Task {}

    private func enqueuePersist(_ operation: @escaping @Sendable () async -> Void) {
        lock.lock()
        let previous = persistChain
        persistChain = Task {
            await previous.value
            await operation()
        }
        lock.unlock()
    }

    /// Enqueues a store write on the same FIFO chain and REPORTS a failure
    /// instead of swallowing it.
    ///
    /// A failed write is not fatal on its own — the session lives in memory and
    /// the next event rewrites it — but silence here was indistinguishable from
    /// success. A Keychain that refuses to store meant a session that vanished at
    /// the next launch with nothing, anywhere, to explain why. The log line is the
    /// minimum a consumer needs to see that it happened; filter it in Console with
    /// subsystem `tonconnect-swift`.
    private func persist(_ what: String,
                         _ write: @escaping @Sendable (NativeSessionStore) async throws -> Void) {
        let store = store
        enqueuePersist {
            do {
                try await write(store)
            } catch {
                Self.log.error("""
                    session store failed (\(what, privacy: .public)): \
                    \(String(describing: error), privacy: .public)
                    """)
            }
        }
    }

    /// Enqueue a RESULT-returning operation on the FIFO chain. The RPC-id
    /// increment is load-modify-save; merely awaiting the chain tail BEFORE a
    /// direct increment only fixes the read race: two PARALLEL sends, having
    /// awaited the chain, still read the same counter and took the same id —
    /// the second ticket overwrote the first, hanging forever.
    /// So the increment itself is serialized.
    private func enqueuePersistReturning<T: Sendable>(
        _ operation: @escaping @Sendable () async -> T
    ) async -> T {
        lock.lock()
        let previous = persistChain
        let task = Task<T, Never> {
            await previous.value
            return await operation()
        }
        persistChain = Task { _ = await task.value }
        lock.unlock()
        return await task.value
    }

    /// Tickets awaiting wallet RPC responses, keyed by AppRequest.id.
    private var pendingRPC: [String: CheckedContinuation<WalletResponse, Error>] = [:]
    private var pendingRPCTasks: [String: NativeFetchTask] = [:]
    /// connectUniversal race: participants and the winner.
    private var universalGateways: [ReconnectGateway] = []
    private var universalWinner: ReconnectGateway?
    /// Bridges of the active universal race — unpause recreates the batch on
    /// wake while the race is still pending.
    private var universalBridgeURLs: [String] = []

    public convenience init(manifestUrl: String,
                            storage: any TonConnectStorage,
                            opener: any WalletOpener,
                            returnStrategy: ReturnStrategy = .back,
                            sessionConfiguration: URLSessionConfiguration = .ephemeral) {
        self.init(manifestUrl: manifestUrl, storage: storage, opener: opener,
                  returnStrategy: returnStrategy, sessionConfiguration: sessionConfiguration,
                  clock: SystemReconnectClock())
    }

    /// Designated init — internal: clock (an internal type) is a seam for deterministic tests.
    init(manifestUrl: String,
         storage: any TonConnectStorage,
         opener: any WalletOpener,
         returnStrategy: ReturnStrategy = .back,
         sessionConfiguration: URLSessionConfiguration = .ephemeral,
         clock: any ReconnectClock) {
        var continuation: AsyncStream<TonConnectEvent>.Continuation!
        self.events = AsyncStream { continuation = $0 }
        self.eventContinuation = continuation
        self.manifestUrl = manifestUrl
        self.store = NativeSessionStore(storage: storage)
        self.opener = opener
        self.returnStrategy = returnStrategy
        self.sessionConfiguration = sessionConfiguration
        self.fetch = NativeFetch(session: URLSession(configuration: sessionConfiguration))
        self.clock = clock
        subscribeToAppLifecycle()
    }

    deinit {
        eventContinuation.finish()
        for observer in lifecycleObservers { NotificationCenter.default.removeObserver(observer) }
        // An orphaned gateway would keep living on its own: its watchdog Task
        // holds it strongly through a 30s sleep, and a live SSE stream is a
        // CFNetwork connection; after a pause it would RE-subscribe to the
        // bridge on behalf of a dead engine.
        gateway?.close()
        for stale in universalGateways { stale.close() }
    }

    // MARK: - connect (synchronous prefix)

    public func connect(source: WalletConnectionSource, items: [ConnectItem]) async throws -> ConnectEvent {
        // Fresh session keypair; sessionId = hex(pk) = our client_id.
        let crypto = SessionCrypto()
        let link: URL
        do {
            link = try Self.buildConnectLink(universalLink: source.universalLink,
                                             manifestUrl: manifestUrl,
                                             sessionId: crypto.sessionId,
                                             items: items)
        } catch { throw NativeErrorMapper.map(error) }

        lock.lock()
        sessionCrypto = crypto
        currentBridgeUrl = source.bridgeUrl
        lastWalletEventId = nil // new session — wallet-event count restarts (otherwise the replay guard would reject id=1)
        universalBridgeURLs = []
        lock.unlock()
        // The previous session's tickets can never be answered, and its id counter
        // restarts here — leaving them would let a new request overwrite a live ticket.
        failAllPendingRPC(Self.sessionEndedError)

        // SDK parity: the pending session is persisted ALREADY at connect —
        // walletPublicKey arrives with the wallet's reply. Otherwise pausing while
        // the wallet is open (and opening it ALWAYS backgrounds us) lost the
        // subscription forever: the store held either nothing or an old session
        // with a foreign client_id. As a bonus, the old record stops being
        // corrupted by foreign lastEventIds.
        let keypair = crypto.stringifyKeypair()
        let pendingSession = NativeSession(
            publicKeyHex: keypair.publicKey,
            secretKeyHex: keypair.secretKey,
            sessionId: crypto.sessionId,
            walletPublicKeyHex: nil,
            bridgeUrl: source.bridgeUrl,
            lastEventId: nil,
            nextRpcRequestId: 1,
            lastWalletEventId: nil
        )
        persist("save the pending session") { try await $0.save(pendingSession) }

        eventContinuation.yield(.connectLinkGenerated(link)) // clean, no ret (for QR/UI)
        // ret=back goes only into the opened link; NO await between the tap and open
        opener.open(appendingReturnStrategy(to: link))

        // Subscription happens INSIDE awaitConnectEvent, strictly after the ticket
        // is registered: a fake transport delivers its frame synchronously, and if
        // preempted between opening the gateway and registering the ticket,
        // resolvePendingConnect found nil and silently dropped the result — the
        // ticket waited forever (same "ticket before request" discipline as performRPC).
        return try await awaitConnectEvent { [self] in
            openGateway(bridgeUrl: source.bridgeUrl, clientId: crypto.sessionId, lastEventId: nil)
        }
    }

    /// The wallet's tc:// link: universalLink + v=2, id=<our client_id>, r=<ConnectRequest JSON>.
    /// Pure Swift — fast and synchronous; ConnectRequest is a Core DTO.
    private static func buildConnectLink(universalLink: String, manifestUrl: String,
                                         sessionId: String, items: [ConnectItem]) throws -> URL {
        let request = ConnectRequest(manifestUrl: manifestUrl, items: items)
        
        let requestJSON = String(decoding: try JSONEncoder().encode(request), as: UTF8.self)
        // Telegram Mini App wallets (t.me / tg://) cannot receive arbitrary query
        // parameters — the connect payload must travel inside `startapp` with
        // Telegram's substitution encoding (SDK parity: universal-link.ts,
        // generateTGUniversalLink). A regular v/id/r query is silently dropped by
        // Telegram and the wallet opens on its default screen (observed on a live wallet).
        if WalletLink.isTelegram(universalLink) {
            return try buildTelegramConnectLink(universalLink: universalLink,
                                                sessionId: sessionId,
                                                requestJSON: requestJSON)
        }
        guard var components = URLComponents(string: universalLink) else {
            throw TonConnectError.internalError(message: "invalid wallet universal link")
        }
        components.queryItems = (components.queryItems ?? []) + [
            URLQueryItem(name: "v", value: "2"),
            URLQueryItem(name: "id", value: sessionId),
            URLQueryItem(name: "r", value: requestJSON),
        ]
        guard let url = components.url else {
            throw TonConnectError.internalError(message: "connect link generation failed")
        }
        return url
    }
    
    /// SDK parity (universal-link.ts generateTGUniversalLink):
    /// `t.me/wallet?attach=wallet` → direct `t.me/wallet/start`, and the v/id/r
    /// params ride inside `startapp=tonconnect-<telegram-encoded>`.
    private static func buildTelegramConnectLink(universalLink: String,
                                                 sessionId: String,
                                                 requestJSON: String) throws -> URL {
        let params = "v=2&id=\(sessionId)&r=\(WalletLink.strictPercentEncode(requestJSON))"
        let payload = "tonconnect-" + WalletLink.encodeTelegramParameters(params)
        guard var components = URLComponents(string: universalLink) else {
            throw TonConnectError.internalError(message: "invalid wallet universal link")
        }
        WalletLink.convertToDirectLink(&components)
        components.queryItems = (components.queryItems ?? []) +
            [URLQueryItem(name: "startapp", value: payload)]
        guard let url = components.url else {
            throw TonConnectError.internalError(message: "connect link generation failed")
        }
        return url
    }

    /// Appends ret=<strategy> to the opened link (auto-return from the wallet);
    /// the Telegram special case lives in WalletLink.
    private func appendingReturnStrategy(to url: URL) -> URL {
        WalletLink.appendingReturnStrategy(returnStrategy.queryValue, to: url)
    }

    /// Recreates the SSE layer (connect/restore/wake): close the old gateway, open a new one.
    private func openGateway(bridgeUrl: String, clientId: String, lastEventId: String?) {
        lock.lock()
        let old = gateway
        let staleUniversal = universalGateways
        universalGateways = []
        let next = ReconnectGateway(bridgeUrl: bridgeUrl,
                                    clientId: clientId,
                                    initialLastEventId: lastEventId,
                                    sessionConfiguration: sessionConfiguration,
                                    clock: clock)
        gateway = next
        lock.unlock()
        old?.close()
        for stale in staleUniversal where stale !== old { stale.close() }
        next.onMessage = { [weak self] id, data in self?.handleIncoming(sseId: id, data: data) }
        next.start()
    }

    /// Waiting ticket under the lock: exactly one resume; cancel resolves with
    /// CancellationError; a repeated connect resolves the OLD ticket
    /// (JSCoreEngine lesson, on-device 2026-07-19).
    /// afterRegistering is the subscription start point: it runs AFTER the ticket
    /// is registered so a synchronously delivered frame cannot outrun the ticket
    /// (which would mean an eternal await).
    private func awaitConnectEvent(afterRegistering register: @escaping () -> Void = {}) async throws -> ConnectEvent {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                lock.lock()
                let previous = pendingConnect
                pendingConnect = continuation
                lock.unlock()
                previous?.resume(throwing: CancellationError())
                register()
                // Race: cancellation may arrive BEFORE the ticket is registered — re-check the flag.
                if Task.isCancelled {
                    resolvePendingConnect(.failure(CancellationError()))
                }
            }
        } onCancel: {
            resolvePendingConnect(.failure(CancellationError()))
        }
    }

    /// Exactly one resume: the pending ticket is taken under the lock and nilled before resolving.
    private func resolvePendingConnect(_ result: Result<ConnectEvent, Error>) {
        lock.lock()
        let pending = pendingConnect
        pendingConnect = nil
        lock.unlock()
        guard let pending else { return }
        switch result {
        case .success(let event): pending.resume(returning: event)
        case .failure(let error): pending.resume(throwing: error)
        }
    }

    // MARK: - incoming frames (dispatch)

    private func handleIncoming(sseId: String?, data: String) {
        // W2: re-persist the id of EVERY frame — a frame id requires no trust in the
        // frame's content, and reconnect after a cold restart must resume from the
        // last frame, not from connect.
        if let sseId, !sseId.isEmpty {
            persist("update last event id") { try await $0.updateLastEventId(sseId) }
        }
        // Bridge heartbeat — a service "I'm alive" frame (data: heartbeat), NOT an
        // envelope. JS SDK parity (bundle.js: e.data === "heartbeat" → ignore);
        // without the filter decodeIncoming throws on it and kills pendingConnect
        // (observed on a live wallet).
        if data == "heartbeat" { return }
        lock.lock()
        let crypto = sessionCrypto
        lock.unlock()
        guard let crypto else { return }
        do {
            let incoming = try RPCEnvelope.decodeIncoming(sseData: data, sessionCrypto: crypto)
            dispatch(json: incoming.json, sseId: sseId, senderHex: incoming.senderPublicKeyHex)
        } catch {
            // An undecodable frame is IGNORED and
            // the engine keeps listening. Resolving the pending connect with an error
            // turned every bridge service frame and any attacker-posted garbage (the
            // client_id is public in a QR) into a connect killer. Ignoring still meets
            // The real goal — no hang, no crash: the genuine wallet frame
            // arrives next and resolves the ticket; the UI keeps its cancel/retry.
            return
        }
    }

    private struct IncomingProbe: Decodable {
        let event: String?
        let id: Int?
    }

    private func dispatch(json: String, sseId: String?, senderHex: String) {
        let probe = try? JSONDecoder().decode(IncomingProbe.self, from: Data(json.utf8))
        switch probe?.event {
        case "connect", "connect_error":
            handleConnectEvent(json: json, sseId: sseId, senderHex: senderHex)
        case "disconnect":
            // Wallet-initiated teardown (BLOCKER 1): the ConnectEvent decoder does
            // not understand this event — an explicit branch is mandatory.
            handleWalletDisconnect(eventId: probe?.id)
        default:
            handleWalletResponse(json: json) // "result"/"error" + "id" — a reply to our AppRequest
        }
    }

    /// Strict monotonicity of incoming wallet events:
    /// id ≤ already seen — a replay, rejected; a valid one is re-persisted (W2).
    private func acceptWalletEventId(_ id: Int) -> Bool {
        lock.lock()
        if let seen = lastWalletEventId, id <= seen {
            lock.unlock()
            return false
        }
        lastWalletEventId = id
        lock.unlock()
        let store = store
        persist("update last wallet event id") { try await $0.updateLastWalletEventId(id) }
        return true
    }

    private func handleConnectEvent(json: String, sseId: String?, senderHex: String) {
        let connectEvent: ConnectEvent
        do { connectEvent = try JSONDecoder().decode(ConnectEvent.self, from: Data(json.utf8)) }
        catch {
            resolvePendingConnect(.failure(NativeErrorMapper.map(error)))
            return
        }
        let eventId: Int
        switch connectEvent {
        case .success(let id, _, _): eventId = id
        case .error(let id, _, _): eventId = id
        }
        guard acceptWalletEventId(eventId) else { return } // replay rejected

        switch connectEvent {
        case .success:
            completeConnect(connectEvent, json: json, sseId: sseId, senderHex: senderHex)
        case .error(_, let code, let message):
            // Typed rejection by code (300 = userDeclined) — no string sniffing.
            resolvePendingConnect(.failure(NativeErrorMapper.walletDeclined(code: code.rawValue,
                                                                            message: message)))
        }
    }

    private func completeConnect(
        _ connectEvent: ConnectEvent,
        json: String,
        sseId: String?,
        senderHex: String
    ) {
        lock.lock()
        walletPublicKey = try? HexCoding.hexToByteArray(senderHex)
        accountAddress = Self.accountAddress(from: connectEvent)
        let crypto = sessionCrypto
        let bridgeUrl = currentBridgeUrl
        let walletEventId = lastWalletEventId
        lock.unlock()
        if let crypto {
            let keypair = crypto.stringifyKeypair()
            let session = NativeSession(
                publicKeyHex: keypair.publicKey,
                secretKeyHex: keypair.secretKey,
                sessionId: crypto.sessionId,
                walletPublicKeyHex: senderHex,
                bridgeUrl: bridgeUrl,
                lastEventId: sseId,
                nextRpcRequestId: 1,
                lastWalletEventId: walletEventId,
                connectEventJSON: json
            )
            persist("save the connected session") { try await $0.save(session) }
        }
        eventContinuation.yield(.connected(connectEvent))
        resolvePendingConnect(.success(connectEvent))
    }

    /// Address from the ton_addr reply of a successful ConnectEvent (raw "wc:hex" form).
    private static func accountAddress(from event: ConnectEvent) -> String? {
        guard case .success(_, let payload, _) = event else { return nil }
        for item in payload.items {
            if case .tonAddress(let reply) = item { return reply.address }
        }
        return nil
    }

    /// Wallet-initiated end of session (BLOCKER 1). Same monotonicity and E2E
    /// decryption as any wallet event — a forged frame cannot tear the session down.
    /// Order: yield → clear → close (the event reaches observers before state teardown).
    private func handleWalletDisconnect(eventId: Int?) {
        guard let eventId, acceptWalletEventId(eventId) else { return }
        eventContinuation.yield(.disconnected)
        let store = store
        persist("clear the session") { try await $0.clear() } // only our own native key
        lock.lock()
        let g = gateway
        gateway = nil
        universalBridgeURLs = []
        sessionCrypto = nil
        walletPublicKey = nil
        accountAddress = nil
        lock.unlock()
        failAllPendingRPC(Self.sessionEndedError)
        g?.close()
    }

    // MARK: - restore

    public func restoreConnection() async throws {
        // Await the tail of the FIFO persistence chain: connect may have just
        // enqueued a save (a consumer may legitimately call restore right after connect).
        lock.lock()
        let chain = persistChain
        lock.unlock()
        await chain.value

        let session: NativeSession?
        do { session = try await store.load() }
        catch { throw NativeErrorMapper.map(error) }
        guard let session, let bridgeUrl = session.bridgeUrl,
              session.walletPublicKeyHex != nil,
              let connectEventJSON = session.connectEventJSON else {
            // A pending session (connect without a wallet reply) OR a record without
            // a saved ConnectEvent (pre-Phase-8 format) is not a restorable
            // connection: an honest throw → the facade goes .disconnected
            // (re-connect), not into an eternal .restoring (observed on a live wallet).
            throw TonConnectError.decodeFailure("no saved session to restore")
        }
        // After a successful restore the facade WAITS for .connected from the
        // event pump — JSCore delivered it via the JS SDK (onStatusChange);
        // the native engine replays the saved ConnectEvent. Decode BEFORE side effects.
        let restoredEvent: ConnectEvent
        do { restoredEvent = try JSONDecoder().decode(ConnectEvent.self, from: Data(connectEventJSON.utf8)) }
        catch { throw NativeErrorMapper.map(error) }
        do {
            let crypto = try SessionCrypto(keyPair: (session.publicKeyHex, session.secretKeyHex))
            lock.lock()
            sessionCrypto = crypto
            currentBridgeUrl = bridgeUrl
            lastWalletEventId = session.lastWalletEventId
            walletPublicKey = session.walletPublicKeyHex.flatMap { try? HexCoding.hexToByteArray($0) }
            accountAddress = Self.accountAddress(from: restoredEvent)
            lock.unlock()
            // Reopen SSE with the saved last_event_id — monotonicity continues.
            openGateway(bridgeUrl: bridgeUrl, clientId: session.sessionId,
                        lastEventId: session.lastEventId)
        } catch { throw NativeErrorMapper.map(error) }
        eventContinuation.yield(.connected(restoredEvent))
    }

    // MARK: - RPC (sendTransaction / signData / disconnect)

    public func sendTransaction(_ payload: SendTransactionPayload) async throws -> WalletResponse {
        // JS SDK parity (bundle.js:6009): from ?? account.address. Tonkeeper
        // REQUIRES from/source (SendTransactionParam.init throws without them) and
        // silently drops the request — tonkeeper/ios sources, observed on a live wallet.
        lock.lock()
        let account = accountAddress
        lock.unlock()
        let filled: SendTransactionPayload
        if payload.from == nil, let account {
            filled = SendTransactionPayload(validUntil: payload.validUntil,
                                            network: payload.network,
                                            from: account,
                                            messages: payload.messages)
        } else {
            filled = payload
        }
        let json: String
        do { json = try Self.encodeJSON(filled) }
        catch { throw NativeErrorMapper.map(error) }
        return try await performRPC(method: "sendTransaction", paramsJSON: [json])
    }

    public func signData(_ payload: SignDataPayload) async throws -> WalletResponse {
        let json: String
        do { json = try Self.encodeJSON(payload) }
        catch { throw NativeErrorMapper.map(error) }
        return try await performRPC(method: "signData", paramsJSON: [json])
    }

    /// SDK parity: disconnect resolves on DELIVERY of the request to the bridge
    /// (wallets are not required to reply) — awaiting an SSE reply here would hang
    /// forever. Then local teardown: clear (native key only) → close → .disconnected.
    public func disconnect() async throws {
        lock.lock()
        let crypto = sessionCrypto
        let walletKey = walletPublicKey
        let bridgeUrl = currentBridgeUrl
        lock.unlock()
        guard let crypto, let walletKey, let bridgeUrl else {
            throw TonConnectError.internalError(message: "no active session to disconnect")
        }
        do {
            // Serialized increment through the FIFO chain (see performRPC).
            let idResult: Result<Int, Error> = await enqueuePersistReturning { [store] in
                do { return .success(try await store.incrementNextRpcRequestId()) }
                catch { return .failure(error) }
            }
            let id = String(try idResult.get())
            let body = try RPCEnvelope.rpcBody(DisconnectRequest(id: id),
                                               sessionCrypto: crypto, walletPublicKey: walletKey)
            let url = RPCEnvelope.messageURL(bridgeUrl: bridgeUrl,
                                             myClientId: crypto.sessionId,
                                             to: HexCoding.toHexString(walletKey),
                                             ttl: 300, topic: "disconnect")
            try await postToBridge(url: url, body: body)
        } catch { throw NativeErrorMapper.map(error) }

        let store = store
        persist("clear the session") { try await $0.clear() }
        lock.lock()
        let chain = persistChain
        let g = gateway
        gateway = nil
        sessionCrypto = nil
        walletPublicKey = nil
        accountAddress = nil
        lock.unlock()
        failAllPendingRPC(Self.sessionEndedError)
        g?.close()
        await chain.value // clear has landed: restore after disconnect will throw
        eventContinuation.yield(.disconnected) // the conformance suite expects the event on the stream
    }

    /// Shared RPC path: a monotonic id from the store (persisted BEFORE sending —
    /// so a crash cannot reuse an id), encrypt→base64→POST; the wallet's reply arrives as an SSE
    /// frame → handleWalletResponse.
    private func performRPC(method: String, paramsJSON: [String]) async throws -> WalletResponse {
        lock.lock()
        let crypto = sessionCrypto
        let walletKey = walletPublicKey
        let bridgeUrl = currentBridgeUrl
        lock.unlock()
        guard let crypto, let walletKey, let bridgeUrl else {
            throw TonConnectError.internalError(message: "no active session for RPC \(method)")
        }
        let id: String
        let body: Data
        do {
            // The increment goes THROUGH the chain — it cannot outrun the
            // session save and is serialized against parallel sends (no duplicate ids).
            let idResult: Result<Int, Error> = await enqueuePersistReturning { [store] in
                do { return .success(try await store.incrementNextRpcRequestId()) }
                catch { return .failure(error) }
            }
            id = String(try idResult.get())
            body = try RPCEnvelope.rpcBody(AppRequest(method: method, params: paramsJSON, id: id),
                                           sessionCrypto: crypto, walletPublicKey: walletKey)
        } catch { throw NativeErrorMapper.map(error) }
        let url = RPCEnvelope.messageURL(bridgeUrl: bridgeUrl,
                                         myClientId: crypto.sessionId,
                                         to: HexCoding.toHexString(walletKey),
                                         ttl: 300, topic: method)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<WalletResponse, Error>) in
                lock.lock()
                pendingRPC[id] = continuation
                lock.unlock()
                let task = fetch.post(url: url, body: body) { [weak self] result in
                    switch result {
                    case .failure(let error):
                        self?.resolvePendingRPC(id: id, .failure(NativeErrorMapper.map(error)))
                    case .success(let response) where !response.ok:
                        self?.resolvePendingRPC(id: id, .failure(TonConnectError.network(
                            message: "bridge POST /message failed: \(response.status)")))
                    case .success:
                        // Delivered to the bridge; the wallet's reply arrives as an
                        // SSE frame. This is the signal the UI waits for before
                        // waking the wallet (SDK parity: onRequestSent).
                        self?.eventContinuation.yield(.requestSent)
                    }
                }
                lock.lock()
                pendingRPCTasks[id] = task
                lock.unlock()
                if Task.isCancelled { cancelPendingRPC(id: id) }
            }
        } onCancel: { [weak self] in
            self?.cancelPendingRPC(id: id)
        }
    }

    /// A wallet reply from SSE: find the ticket by id and resolve it. A rejection
    /// (code 300 et al.) is a TYPED WalletResponse.error, NOT a throw
    /// (contract).
    private func handleWalletResponse(json: String) {
        if let response = try? JSONDecoder().decode(WalletResponse.self, from: Data(json.utf8)) {
            resolvePendingRPC(id: Self.responseID(of: response), .success(response))
            return
        }
        // Wire tolerance: a wallet that answers without `id`. Such a frame cannot be
        // correlated, so it is adopted only when exactly one request is in flight —
        // then there is nothing to confuse it with. With two or more it is dropped:
        // resolving the wrong operation is worse than resolving none. Before this,
        // every such frame was dropped and the operation simply never returned.
        lock.lock()
        let soleID = pendingRPC.count == 1 ? pendingRPC.keys.first : nil
        lock.unlock()
        guard let soleID,
              let response = Self.decode(json: json, adoptingID: soleID) else { return }
        resolvePendingRPC(id: soleID, .success(response))
    }

    private static func responseID(of response: WalletResponse) -> String {
        switch response {
        case .success(_, let id): return id
        case .error(_, _, let id): return id
        }
    }

    /// Re-decodes a frame that carries no `id` by inserting one and handing it to the
    /// same WalletResponse decoder — so every other wire tolerance (an object result,
    /// an error without a message, a numeric id) keeps applying, with no second copy
    /// of that logic. An `id` that is present but unusable is NOT repaired: absence is
    /// a wallet habit, a malformed value is corruption.
    private static func decode(json: String, adoptingID id: String) -> WalletResponse? {
        guard var object = (try? JSONSerialization.jsonObject(with: Data(json.utf8))) as? [String: Any],
              object["id"] == nil,
              object["result"] != nil || object["error"] != nil
        else { return nil }
        object["id"] = id
        guard let repaired = try? JSONSerialization.data(withJSONObject: object) else { return nil }
        return try? JSONDecoder().decode(WalletResponse.self, from: repaired)
    }

    /// Exactly one resume per ticket (same discipline as resolvePendingConnect).
    private func resolvePendingRPC(id: String, _ result: Result<WalletResponse, Error>) {
        lock.lock()
        let pending = pendingRPC.removeValue(forKey: id)
        pendingRPCTasks.removeValue(forKey: id)
        lock.unlock()
        guard let pending else { return }
        switch result {
        case .success(let response): pending.resume(returning: response)
        case .failure(let error): pending.resume(throwing: error)
        }
    }

    /// Ends every in-flight RPC with a typed error. A session boundary (disconnect,
    /// wallet-initiated disconnect, or a fresh connect) makes pending tickets
    /// unanswerable: their wallet session is gone and the request-id counter
    /// restarts at 1, so a later request would overwrite a live ticket and leak its
    /// continuation ("SWIFT TASK CONTINUATION MISUSE", observed).
    private func failAllPendingRPC(_ error: Error) {
        lock.lock()
        let pending = pendingRPC
        let tasks = pendingRPCTasks
        pendingRPC = [:]
        pendingRPCTasks = [:]
        lock.unlock()
        for task in tasks.values { task.cancel() }
        for continuation in pending.values { continuation.resume(throwing: error) }
    }

    /// The error every ticket orphaned by a session boundary resolves with.
    private static var sessionEndedError: TonConnectError {
        .internalError(message: "session ended before the wallet replied")
    }

    private func cancelPendingRPC(id: String) {
        lock.lock()
        let task = pendingRPCTasks.removeValue(forKey: id)
        lock.unlock()
        task?.cancel()
        resolvePendingRPC(id: id, .failure(CancellationError()))
    }

    /// POST awaiting delivery to the bridge (not a wallet reply) — for disconnect.
    private func postToBridge(url: String, body: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            fetch.post(url: url, body: body) { result in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: NativeErrorMapper.map(error))
                case .success(let response) where !response.ok:
                    continuation.resume(throwing: TonConnectError.network(
                        message: "bridge POST /message failed: \(response.status)"))
                case .success:
                    continuation.resume()
                }
            }
        }
    }

    private static func encodeJSON<T: Encodable>(_ value: T) throws -> String {
        String(decoding: try JSONEncoder().encode(value), as: UTF8.self)
    }

    // MARK: - connectUniversal (bridge race, first-writer-wins)

    /// "Second device" QR connect: N gateways to N bridges with a SINGLE
    /// client_id; the wallet on THIS device is NOT opened (opensWallet=false) —
    /// the link leaves only via the .connectLinkGenerated event. Dead bridges
    /// quietly retry in the background on the cadence and cannot spoil the result
    ///; no overall timeout is introduced (JS SDK parity —
    /// decision_notes; the UI communicates "no connection").
    public func connectUniversal(bridgeURLs: [String], items: [ConnectItem]) async throws -> ConnectEvent {
        guard !bridgeURLs.isEmpty else { // WR-02: an empty list would hang forever
            throw TonConnectError.internalError(message: "connectUniversal requires at least one bridge URL")
        }
        let crypto = SessionCrypto() // one keypair/client_id for all bridges
        let link: URL
        do {
            link = try Self.buildConnectLink(universalLink: "tc://",
                                             manifestUrl: manifestUrl,
                                             sessionId: crypto.sessionId,
                                             items: items)
        } catch { throw NativeErrorMapper.map(error) }

        lock.lock()
        let oldGateway = gateway
        gateway = nil
        let oldUniversal = universalGateways
        universalGateways = []
        sessionCrypto = crypto
        currentBridgeUrl = nil
        lastWalletEventId = nil
        universalWinner = nil
        universalBridgeURLs = bridgeURLs
        lock.unlock()
        failAllPendingRPC(Self.sessionEndedError) // same session boundary as connect
        oldGateway?.close() // tear down the old, same as connect
        for stale in oldUniversal { stale.close() }

        eventContinuation.yield(.connectLinkGenerated(link)) // for QR; the opener is NOT called

        // Gateways start after the ticket is registered (same race as in connect):
        // the first bridge's synchronous frame must not outrun pendingConnect.
        return try await awaitConnectEvent { [self] in
            startUniversalGateways(bridgeURLs: bridgeURLs, clientId: crypto.sessionId)
        }
    }

    /// The race's gateway batch (connectUniversal + unpause during a pending race).
    private func startUniversalGateways(bridgeURLs: [String], clientId: String) {
        var opened: [(url: String, gateway: ReconnectGateway)] = []
        for bridgeUrl in bridgeURLs {
            let g = ReconnectGateway(bridgeUrl: bridgeUrl,
                                     clientId: clientId,
                                     sessionConfiguration: sessionConfiguration,
                                     clock: clock)
            opened.append((bridgeUrl, g))
        }
        lock.lock()
        universalGateways = opened.map(\.gateway)
        lock.unlock()
        for (bridgeUrl, g) in opened {
            g.onMessage = { [weak self, weak g] id, data in
                guard let g else { return }
                self?.handleUniversalIncoming(gateway: g, bridgeUrl: bridgeUrl, sseId: id, data: data)
            }
            g.start()
        }
    }

    /// first-writer-wins: the FIRST gateway whose frame SUCCESSFULLY decrypts into
    /// a valid ConnectEvent.success wins. Corrupted ciphertext (decode throws) does
    /// NOT win — stricter than the JS SDK (which closes the others on any first
    /// message); a deliberate hardening against spoofing in the race.
    private func handleUniversalIncoming(gateway: ReconnectGateway, bridgeUrl: String,
                                         sseId: String?, data: String) {
        lock.lock()
        let crypto = sessionCrypto
        let winner = universalWinner
        lock.unlock()
        if let winner {
            // The window between winning and re-pointing onMessage: the WINNER's
            // frames are routed into the normal path; the rest are ignored.
            if gateway === winner { handleIncoming(sseId: sseId, data: data) }
            return
        }
        guard let crypto else { return }
        guard let incoming = try? RPCEnvelope.decodeIncoming(sseData: data, sessionCrypto: crypto),
              let connectEvent = try? JSONDecoder().decode(ConnectEvent.self,
                                                           from: Data(incoming.json.utf8)),
              case .success = connectEvent else {
            return // not a valid success — the race continues, this gateway keeps listening
        }

        lock.lock()
        guard universalWinner == nil else { lock.unlock(); return } // a single winner
        universalWinner = gateway
        currentBridgeUrl = bridgeUrl // the winning bridge is pinned in the session
        self.gateway = gateway // from here on we live like a regular connect (RPC/pause/wake)
        universalBridgeURLs = [] // race over — unpause takes the session path
        let losers = universalGateways.filter { $0 !== gateway }
        universalGateways = []
        lock.unlock()
        for loser in losers { loser.close() } // immediately: one subscription per client_id
        gateway.onMessage = { [weak self] id, frame in self?.handleIncoming(sseId: id, data: frame) }

        // Same path as a regular connect: monotonicity + persist + yield + resolve.
        handleConnectEvent(json: incoming.json, sseId: sseId, senderHex: incoming.senderPublicKeyHex)
    }

    // MARK: - lifecycle (mirror)

    private func subscribeToAppLifecycle() {
        #if canImport(UIKit)
        let center = NotificationCenter.default
        lifecycleObservers = [
            center.addObserver(forName: UIApplication.willResignActiveNotification,
                               object: nil, queue: .main) { [weak self] _ in
                self?.pause()
            },
            center.addObserver(forName: UIApplication.didBecomeActiveNotification,
                               object: nil, queue: .main) { [weak self] _ in
                self?.unpause()
            },
        ]
        #endif
    }

    /// Going to sleep — close the line: the regular gateway AND the universal-race batch.
    private func pause() {
        lock.lock()
        let g = gateway
        gateway = nil
        let universal = universalGateways
        universalGateways = []
        lock.unlock()
        g?.close()
        for u in universal { u.close() }
    }

    /// Waking up. Order matters: if connect is still PENDING, the session
    /// may not have reached the store yet — reopen from the CURRENT state
    /// (crypto/bridge or the race batch). Only an established session is restored
    /// from the store.
    private func unpause() {
        Task { [weak self] in
            guard let self else { return }
            self.lock.lock()
            let crypto = self.sessionCrypto
            let bridgeUrl = self.currentBridgeUrl
            let hasPending = self.pendingConnect != nil
            let universalURLs = self.universalBridgeURLs
            self.lock.unlock()

            if hasPending, let crypto {
                if !universalURLs.isEmpty {
                    self.startUniversalGateways(bridgeURLs: universalURLs, clientId: crypto.sessionId)
                } else if let bridgeUrl {
                    self.openGateway(bridgeUrl: bridgeUrl, clientId: crypto.sessionId, lastEventId: nil)
                }
                return
            }

            guard let session = try? await self.store.load(),
                  let savedBridge = session.bridgeUrl else { return }
            self.lock.lock()
            let active = self.sessionCrypto != nil
            self.lock.unlock()
            guard active else { return }
            self.openGateway(bridgeUrl: savedBridge, clientId: session.sessionId,
                             lastEventId: session.lastEventId)
        }
    }

    /// Test seams (the counterpart of lifecycle.simulateWake in JSCoreEngine):
    /// UIKit notifications are unavailable in unit tests on macOS.
    func pauseForTesting() { pause() }
    func wakeForTesting() { unpause() }
}
