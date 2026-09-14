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
    /// The connect attempt waiting for the wallet: its ticket, and WHICH attempt
    /// it belongs to (the attempt's sessionId). A cancel or a failure must tear
    /// down its own attempt and nothing else — a fast connect A → cancel A →
    /// connect B must not let A's cancellation take down B.
    private struct PendingConnect {
        let attempt: String
        let continuation: CheckedContinuation<ConnectEvent, Error>
    }
    private var pendingConnect: PendingConnect?
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
        let task: Task<T, Never> = lock.withLock {
            let previous = persistChain
            let task = Task<T, Never> {
                await previous.value
                return await operation()
            }
            persistChain = Task { _ = await task.value }
            return task
        }
        return await task.value
    }

    /// Tickets awaiting wallet RPC responses, keyed by AppRequest.id.
    private var pendingRPC: [String: CheckedContinuation<WalletResponse, Error>] = [:]
    private var pendingRPCTasks: [String: NativeFetchTask] = [:]
    /// Tombstones: ids of requests cancelled (or timed out) after they may have
    /// reached the bridge. Cancellation is local — the bridge has no "recall" —
    /// so the wallet can still answer them. A reply WITH an id for a tombstone is
    /// simply dropped; a reply WITHOUT an id is the problem: it used to be
    /// adopted by whatever single request was in flight, i.e. a late answer to
    /// the cancelled A resolved the unrelated B. While a tombstone exists, id-less
    /// frames are not adopted at all. Cleared at every session boundary.
    private var retiredRPCIDs: Set<String> = []
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

        lock.withLock {
            sessionCrypto = crypto
            currentBridgeUrl = source.bridgeUrl
            lastWalletEventId = nil // new session — wallet-event count restarts (otherwise the replay guard would reject id=1)
            universalBridgeURLs = []
            universalWinner = nil
            // The previous wallet's identity ends here. Left in place, a request
            // issued while this connect waits passed the "active session" guard and
            // went to the NEW bridge, encrypted to the OLD wallet's key, under the
            // new client_id — a ticket nothing could ever answer.
            walletPublicKey = nil
            accountAddress = nil
        }
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
        return try await awaitConnectEvent(attempt: crypto.sessionId) { [self] in
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
    private func awaitConnectEvent(attempt: String,
                                   afterRegistering register: @escaping () -> Void = {}) async throws -> ConnectEvent {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                lock.lock()
                let previous = pendingConnect
                pendingConnect = PendingConnect(attempt: attempt, continuation: continuation)
                lock.unlock()
                // The superseded attempt's state was already replaced by ours under
                // the lock in connect(); only its ticket is left to settle.
                previous?.continuation.resume(throwing: CancellationError())
                register()
                // Race: cancellation may arrive BEFORE the ticket is registered — re-check the flag.
                if Task.isCancelled {
                    resolvePendingConnect(.failure(CancellationError()), attempt: attempt)
                }
            }
        } onCancel: {
            resolvePendingConnect(.failure(CancellationError()), attempt: attempt)
        }
    }

    /// Exactly one resume: the pending ticket is taken under the lock and nilled
    /// before resolving. `attempt` restricts the resolution to one attempt's
    /// ticket (cancellation paths); nil resolves whichever attempt is current
    /// (a wallet frame — by construction it can only be for the current one).
    ///
    /// A failure is a session boundary for the attempt: whatever it set up —
    /// the SSE line, the keypair, the pending record in the store — is torn
    /// down, so a wallet that answers AFTER a cancel, a timeout or a decline
    /// finds nothing to complete. Until this, cancellation only settled the
    /// ticket: the line stayed open, unpause re-opened it, and a late Approve
    /// silently produced a connected, persisted session the app had given up on.
    private func resolvePendingConnect(_ result: Result<ConnectEvent, Error>, attempt: String? = nil) {
        let pending: PendingConnect? = lock.withLock {
            guard let current = pendingConnect else { return nil }
            if let attempt, current.attempt != attempt { return nil }
            pendingConnect = nil
            return current
        }
        guard let pending else { return }
        switch result {
        case .success(let event):
            pending.continuation.resume(returning: event)
        case .failure(let error):
            abandonAttempt(pending.attempt)
            pending.continuation.resume(throwing: error)
        }
    }

    /// Tears down one connect attempt, if it is still the current state: closes
    /// its gateways, forgets its keypair and bridge, and removes its pending
    /// record from the store — only that record (matched by sessionId and still
    /// unanswered), so a newer attempt's record is never touched. Runs on the
    /// FIFO chain like every store write.
    private func abandonAttempt(_ attempt: String) {
        let (g, universal): (ReconnectGateway?, [ReconnectGateway]) = lock.withLock {
            guard sessionCrypto?.sessionId == attempt else { return (nil, []) }
            let g = gateway
            gateway = nil
            let universal = universalGateways
            universalGateways = []
            universalBridgeURLs = []
            universalWinner = nil
            sessionCrypto = nil
            currentBridgeUrl = nil
            walletPublicKey = nil
            accountAddress = nil
            lastWalletEventId = nil
            return (g, universal)
        }
        g?.close()
        for stale in universal { stale.close() }
        persist("discard the abandoned pending session") { store in
            guard let record = try await store.load(),
                  record.sessionId == attempt, record.walletPublicKeyHex == nil else { return }
            try await store.clear()
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
        let (crypto, pinnedWallet) = lock.withLock { (sessionCrypto, walletPublicKey) }
        guard let crypto else { return }
        do {
            // Once a wallet is pinned, only its frames get past this line (see
            // RPCEnvelope.decodeIncoming) — a stranger who knows the public
            // client_id cannot answer our requests, re-pin the session or end it.
            let incoming = try RPCEnvelope.decodeIncoming(sseData: data, sessionCrypto: crypto,
                                                          expectedSender: pinnedWallet)
            dispatch(json: incoming.json, sseId: sseId, senderHex: incoming.senderPublicKeyHex,
                     walletPinned: pinnedWallet != nil)
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

    /// Before a wallet is pinned (a connect in flight) the only meaningful frame
    /// is the wallet's connect reply; a disconnect or an RPC reply from a key we
    /// have not accepted yet has nobody to speak for and is dropped.
    private func dispatch(json: String, sseId: String?, senderHex: String, walletPinned: Bool) {
        let probe = try? JSONDecoder().decode(IncomingProbe.self, from: Data(json.utf8))
        switch probe?.event {
        case "connect", "connect_error":
            handleConnectEvent(json: json, sseId: sseId, senderHex: senderHex)
        case "disconnect":
            // Wallet-initiated teardown (BLOCKER 1): the ConnectEvent decoder does
            // not understand this event — an explicit branch is mandatory.
            guard walletPinned else { return }
            handleWalletDisconnect(eventId: probe?.id)
        default:
            guard walletPinned else { return }
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
        // A connect event is an answer, and there has to be a question: with no
        // connect in flight it is ignored. Otherwise a second "connect" — from
        // the pinned wallet or, before pinning existed, from anyone — re-pinned
        // the session and switched the account under the app's feet.
        guard lock.withLock({ pendingConnect != nil }) else { return }
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
        // Pinning the wallet and taking the ticket happen under ONE lock: a cancel
        // racing this frame either finds the ticket gone (we won: the session
        // stands) or takes it first (it won: sessionCrypto is nil by the time we
        // look, and the frame is dropped). No state is ever half-pinned.
        let taken: (ticket: PendingConnect, crypto: SessionCrypto, bridgeUrl: String?, walletEventId: Int?)? =
            lock.withLock {
                guard let pending = pendingConnect, let crypto = sessionCrypto,
                      crypto.sessionId == pending.attempt else { return nil }
                pendingConnect = nil
                walletPublicKey = try? HexCoding.hexToByteArray(senderHex)
                accountAddress = Self.accountAddress(from: connectEvent)
                return (pending, crypto, currentBridgeUrl, lastWalletEventId)
            }
        guard let taken else { return }
        let keypair = taken.crypto.stringifyKeypair()
        let session = NativeSession(
            publicKeyHex: keypair.publicKey,
            secretKeyHex: keypair.secretKey,
            sessionId: taken.crypto.sessionId,
            walletPublicKeyHex: senderHex,
            bridgeUrl: taken.bridgeUrl,
            lastEventId: sseId,
            nextRpcRequestId: 1,
            lastWalletEventId: taken.walletEventId,
            connectEventJSON: json
        )
        persist("save the connected session") { try await $0.save(session) }
        eventContinuation.yield(.connected(connectEvent))
        taken.ticket.continuation.resume(returning: connectEvent)
    }

    /// Address from the ton_addr reply of a successful ConnectEvent (raw "wc:hex" form).
    private static func accountAddress(from event: ConnectEvent) -> String? {
        guard case .success(_, let payload, _) = event else { return nil }
        for item in payload.items {
            if case .tonAddress(let reply) = item { return reply.address }
        }
        return nil
    }

    /// Wallet-initiated end of session (BLOCKER 1). Reaches here only from the
    /// pinned wallet's key (handleIncoming refuses every other sender before
    /// decrypting) and only past the monotonicity check — so neither a stranger
    /// who knows the client_id nor a replayed frame can tear the session down.
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
        let chain = lock.withLock { persistChain }
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
            lock.withLock {
                sessionCrypto = crypto
                currentBridgeUrl = bridgeUrl
                lastWalletEventId = session.lastWalletEventId
                walletPublicKey = session.walletPublicKeyHex.flatMap { try? HexCoding.hexToByteArray($0) }
                accountAddress = Self.accountAddress(from: restoredEvent)
            }
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
        let account = lock.withLock { accountAddress }
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

    /// Tells the wallet, then ends the session locally — and the second half
    /// does not depend on the first. The notice to the wallet is delivered to
    /// the bridge (wallets are not required to reply, so awaiting an SSE reply
    /// would hang forever); if the bridge is unreachable or answers 5xx, the
    /// notice is lost, but the session still ends here: the record is cleared,
    /// the line is closed, `.disconnected` is emitted, and the delivery error is
    /// thrown AFTER all that, so the caller knows the wallet may still think it
    /// is connected. Until this, a failed POST threw before any teardown: the
    /// secret stayed in the Keychain, the next launch restored the session, and
    /// a bridge that refused disconnects (or was simply down) made the session
    /// impossible to end from this side at all. The vendored JS SDK removes the
    /// session in both `catch` and `finally`; this now matches it.
    public func disconnect() async throws {
        let (crypto, walletKey, bridgeUrl) = lock.withLock {
            (sessionCrypto, walletPublicKey, currentBridgeUrl)
        }
        guard let crypto, let walletKey, let bridgeUrl else {
            throw TonConnectError.internalError(message: "no active session to disconnect")
        }
        var deliveryError: Error?
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
        } catch { deliveryError = NativeErrorMapper.map(error) }

        // Local teardown, unconditionally. The clear goes through the same FIFO
        // chain as every write, but its failure is REPORTED, not logged: a
        // Keychain that keeps the secret after "disconnect succeeded" is worse
        // than an error.
        let clearResult: Result<Void, Error> = await enqueuePersistReturning { [store] in
            do { try await store.clear(); return .success(()) }
            catch { return .failure(error) }
        }
        let g: ReconnectGateway? = lock.withLock {
            let g = gateway
            gateway = nil
            sessionCrypto = nil
            currentBridgeUrl = nil
            walletPublicKey = nil
            accountAddress = nil
            lastWalletEventId = nil
            return g
        }
        failAllPendingRPC(Self.sessionEndedError)
        g?.close()
        eventContinuation.yield(.disconnected) // the conformance suite expects the event on the stream
        if case .failure(let error) = clearResult { throw NativeErrorMapper.map(error) }
        if let deliveryError { throw deliveryError }
    }

    /// Shared RPC path: a monotonic id from the store (persisted BEFORE sending —
    /// so a crash cannot reuse an id), encrypt→base64→POST; the wallet's reply arrives as an SSE
    /// frame → handleWalletResponse.
    private func performRPC(method: String, paramsJSON: [String]) async throws -> WalletResponse {
        let (crypto, walletKey, bridgeUrl) = lock.withLock {
            (sessionCrypto, walletPublicKey, currentBridgeUrl)
        }
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
        // ...and only while no cancelled request could still be answered: after a
        // cancel, an id-less frame may be the late answer to THAT request, and
        // handing it to the one still in flight would resolve the wrong operation.
        let soleID: String? = lock.withLock {
            pendingRPC.count == 1 && retiredRPCIDs.isEmpty ? pendingRPC.keys.first : nil
        }
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
        let pending: CheckedContinuation<WalletResponse, Error>? = lock.withLock {
            pendingRPCTasks.removeValue(forKey: id)
            let pending = pendingRPC.removeValue(forKey: id)
            // An answer WITH an id for a retired request settles it: the wallet
            // has spoken, and id-less adoption may resume.
            if pending == nil { retiredRPCIDs.remove(id) }
            return pending
        }
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
        retiredRPCIDs = [] // the boundary ends those requests for good
        lock.unlock()
        for task in tasks.values { task.cancel() }
        for continuation in pending.values { continuation.resume(throwing: error) }
    }

    /// The error every ticket orphaned by a session boundary resolves with.
    private static var sessionEndedError: TonConnectError {
        .internalError(message: "session ended before the wallet replied")
    }

    private func cancelPendingRPC(id: String) {
        let task: NativeFetchTask? = lock.withLock {
            // Cancellation is local; the request may already sit in the bridge,
            // and the wallet may still answer it. Remember the id (see retiredRPCIDs).
            if pendingRPC[id] != nil { retiredRPCIDs.insert(id) }
            return pendingRPCTasks.removeValue(forKey: id)
        }
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

        let (oldGateway, oldUniversal): (ReconnectGateway?, [ReconnectGateway]) = lock.withLock {
            let oldGateway = gateway
            gateway = nil
            let oldUniversal = universalGateways
            universalGateways = []
            sessionCrypto = crypto
            currentBridgeUrl = nil
            lastWalletEventId = nil
            universalWinner = nil
            universalBridgeURLs = bridgeURLs
            walletPublicKey = nil // the previous wallet's identity ends here (see connect)
            accountAddress = nil
            return (oldGateway, oldUniversal)
        }
        failAllPendingRPC(Self.sessionEndedError) // same session boundary as connect
        oldGateway?.close() // tear down the old, same as connect
        for stale in oldUniversal { stale.close() }

        eventContinuation.yield(.connectLinkGenerated(link)) // for QR; the opener is NOT called

        // Gateways start after the ticket is registered (same race as in connect):
        // the first bridge's synchronous frame must not outrun pendingConnect.
        return try await awaitConnectEvent(attempt: crypto.sessionId) { [self] in
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
        // A batch may already be running — two wakes in a row during a pending
        // race, with no pause between them. Left unreferenced, the old batch kept
        // its streams open for the life of the process: one more subscription per
        // bridge under the same client_id, closed by nobody, not even deinit.
        let stale: [ReconnectGateway] = lock.withLock {
            let stale = universalGateways
            universalGateways = opened.map(\.gateway)
            return stale
        }
        for old in stale { old.close() }
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
    /// message). What this cannot do is tell a wallet from an impostor: before the
    /// first connect event nothing is pinned, and the client_id is public, so any
    /// party that can reach one of the bridges — including the bridge itself —
    /// can answer first with its own key. That is the protocol's shape, not a
    /// gap this code can close; the list of bridges IS the list of parties
    /// trusted to answer. Once the winner is pinned, every other key is refused.
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
            let (crypto, bridgeUrl, hasPending, universalURLs) = self.lock.withLock {
                (self.sessionCrypto, self.currentBridgeUrl,
                 self.pendingConnect != nil, self.universalBridgeURLs)
            }

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
            let active = self.lock.withLock { self.sessionCrypto != nil }
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
