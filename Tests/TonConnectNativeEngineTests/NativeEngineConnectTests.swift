import Foundation
import Testing
import TonConnectCore
import TonConnectTestSupport
@testable import TonConnectNativeEngine

/// This suite's isolated scenario (fake v3 — per-class state).
private final class ConnectFakeBridge: FakeBridgeURLProtocol {}

/// Records opened wallet links (WalletOpener lives in Core).
private final class SpyOpener: WalletOpener, @unchecked Sendable {
    private let lock = NSLock()
    private var urls: [URL] = []
    func open(_ url: URL) { lock.lock(); urls.append(url); lock.unlock() }
    var openedURLs: [URL] { lock.lock(); defer { lock.unlock() }; return urls }
}

/// A PER-client_id subscription counter: a late GET /events of a closed gateway
/// under load used to steal the global `calls == 1` from the next test (eternal await).
private final class PerClientCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var counts: [String: Int] = [:]
    func next(_ clientId: String) -> Int {
        lock.lock(); defer { lock.unlock() }
        counts[clientId, default: 0] += 1
        return counts[clientId]!
    }
}

/// The stream's event collector (AsyncStream — one consumer, the collector is it).
private final class EventCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [TonConnectEvent] = []
    func append(_ event: TonConnectEvent) { lock.lock(); items.append(event); lock.unlock() }
    var all: [TonConnectEvent] { lock.lock(); defer { lock.unlock() }; return items }
    var connectedCount: Int {
        all.filter { if case .connected = $0 { return true } else { return false } }.count
    }
    var sawDisconnected: Bool { all.contains(.disconnected) }
}

/// A Swift wallet simulator WITHOUT a JSContext: a second SessionCrypto plays
/// the wallet (native crypto — simpler than 's JS counterpart).
private struct WalletSimulator {
    let crypto = SessionCrypto()
    var publicKeyHex: String { HexCoding.toHexString(crypto.keyPair.publicKey) }

    /// Encrypts an event to the dApp's client_id and wraps it in a BridgeMessage envelope.
    func frame(_ json: String, to clientIdHex: String) -> String {
        let clientKey = (try? HexCoding.hexToByteArray(clientIdHex)) ?? []
        let cipher = (try? crypto.encrypt(json, to: clientKey)) ?? []
        return "{\"from\":\"\(publicKeyHex)\",\"message\":\"\(Data(cipher).base64EncodedString())\"}"
    }

    /// A valid envelope with one ciphertext byte flipped — a forgery .
    func tamperedFrame(_ json: String, to clientIdHex: String) -> String {
        let clientKey = (try? HexCoding.hexToByteArray(clientIdHex)) ?? []
        var cipher = (try? crypto.encrypt(json, to: clientKey)) ?? []
        if !cipher.isEmpty { cipher[cipher.count - 1] ^= 0xFF }
        return "{\"from\":\"\(publicKeyHex)\",\"message\":\"\(Data(cipher).base64EncodedString())\"}"
    }

    /// The wallet's side: decrypt the body of our POST /message.
    func decryptRPCBody(_ base64Body: String, from clientIdHex: String) -> String? {
        guard let clientKey = try? HexCoding.hexToByteArray(clientIdHex),
              let data = Data(base64Encoded: base64Body) else { return nil }
        return try? crypto.decrypt(Array(data), from: clientKey)
    }
}

/// A thread-safe box for one text (captures params from messageHandler).
private final class CapturedText: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: String?
    func set(_ value: String) { lock.lock(); _value = value; lock.unlock() }
    var value: String? { lock.lock(); defer { lock.unlock() }; return _value }
}

@Suite(.serialized) struct NativeEngineConnectTests {

    static let connectSuccessJSON = """
    {"event":"connect","id":1,"payload":{"items":[{"name":"ton_addr","address":"0:fake","network":"-3","publicKey":"deadbeef","walletStateInit":"te6ccFakeInit"}],"device":{"platform":"iphone","appName":"FakeWallet","appVersion":"1.0.0","maxProtocolVersion":2,"features":[{"name":"SendTransaction","maxMessages":4},{"name":"SignData","types":["text","binary","cell"]}]}}}
    """

    /// The same event with id=5 — verifies the monotonic-id re-persist (W2).
    static let connectSuccessJSONId5 =
        connectSuccessJSON.replacingOccurrences(of: "\"id\":1", with: "\"id\":5")

    static let walletDisconnectJSON = """
    {"event":"disconnect","id":2,"payload":{}}
    """

    private static let bridgeUrl = "https://bridge.native/bridge"
    private static let source = WalletConnectionSource(universalLink: "https://wallet.native/tc",
                                                       bridgeUrl: bridgeUrl)

    // MARK: - helpers

    /// Bounded condition wait (2s ceiling): a silent engine fails the assert instead of hanging the run.
    private func waitUntil(_ condition: @escaping @Sendable () -> Bool,
                           timeoutNanoseconds: UInt64 = 2_000_000_000) async -> Bool {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return condition()
    }

    /// Polls the store with a ceiling: the engine's fire-and-forget persists land asynchronously.
    private func pollSession(_ store: NativeSessionStore,
                             until predicate: (NativeSession?) -> Bool) async -> NativeSession? {
        for _ in 0..<200 {
            let session = try? await store.load()
            if predicate(session) { return session }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return try? await store.load()
    }

    /// reset + script + an engine with the fake transport. The provider is set AFTER makeEngine.
    private func makeEngine(storage: InMemoryStorage, opener: SpyOpener = SpyOpener()) -> NativeEngine {
        ConnectFakeBridge.reset()
        var script = ConnectFakeBridge.Script()
        script.keepEventsStreamOpen = true
        ConnectFakeBridge.script = script
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ConnectFakeBridge.self]
        // ManualReconnectClock (never ticks): the 30s watchdog does not fire in
        // tests — otherwise on a slow CI machine a live engine would re-subscribe
        // to the fake by itself and lose frames (determinism, the designated-init seam).
        return NativeEngine(manifestUrl: "https://example.com/tonconnect-manifest.json",
                            storage: storage, opener: opener, sessionConfiguration: config,
                            clock: ManualReconnectClock())
    }

    /// The /events scenario: 1st subscription → connect-success (SSE id "1",
    /// wallet id 1); subsequent subscriptions → followUp frames (empty by default).
    private func installProvider(wallet: WalletSimulator,
                                 followUp: [(id: String?, json: String)] = []) {
        let calls = PerClientCounter()
        ConnectFakeBridge.eventsFrameProvider = { url in
            guard let clientId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "client_id" })?.value else { return [] }
            if calls.next(clientId) == 1 {
                return [(id: "1", data: wallet.frame(Self.connectSuccessJSON, to: clientId))]
            }
            return followUp.map { (id: $0.id, data: wallet.frame($0.json, to: clientId)) }
        }
    }

    // MARK: - connect happy path

    @Test func testConnectHappyPathReturnsSuccessEvent() async throws {
        let storage = InMemoryStorage()
        let opener = SpyOpener()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage, opener: opener)
        installProvider(wallet: wallet)
        let collector = EventCollector()
        // The handle + cancel are mandatory: an unnamed Task would hold the engine
        // strongly forever (the stream finishes only in deinit — which would never come).
        let collectorTask = Task { for await event in engine.events { collector.append(event) } }
        defer { collectorTask.cancel() }

        let result = try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)])

        guard case .success = result else {
            Issue.record("expected ConnectEvent.success, got \(result)")
            return
        }
        #expect(await waitUntil { collector.connectedCount == 1 }) // the single source 
        #expect(opener.openedURLs.count == 1) // EXACTLY one open
        let link = opener.openedURLs.first?.absoluteString ?? ""
        #expect(link.contains("id="))
        #expect(link.contains("ret=back"))
    }

    @Test func testConnectPersistsSessionWithWalletSessionKey() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        installProvider(wallet: wallet)

        _ = try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)])

        let store = NativeSessionStore(storage: storage)
        let session = await pollSession(store) { $0?.walletPublicKeyHex != nil }
        #expect(session != nil)
        // The wallet's session key = the envelope's from (bundle.js:4017), NOT the payload's "deadbeef"
        #expect(session?.walletPublicKeyHex == wallet.publicKeyHex)
        #expect(session?.bridgeUrl == Self.bridgeUrl)
        #expect(session?.lastEventId == "1")
        _ = engine // the engine stays alive until the checks finish
    }

    // MARK: - forgery and replay

    @Test func testStaleWalletEventIDIsRejected() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        installProvider(wallet: wallet)
        let collector = EventCollector()
        // The handle + cancel are mandatory: an unnamed Task would hold the engine
        // strongly forever (the stream finishes only in deinit — which would never come).
        let collectorTask = Task { for await event in engine.events { collector.append(event) } }
        defer { collectorTask.cancel() }
        _ = try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)])
        let store = NativeSessionStore(storage: storage)
        let session = await pollSession(store) { $0 != nil }
        let clientId = try #require(session?.sessionId)

        // replay: the same wallet event id=1 again (a new SSE id — the event id is what matters)
        ConnectFakeBridge.pushFrame(id: "2", data: wallet.frame(Self.connectSuccessJSON, to: clientId))
        try? await Task.sleep(nanoseconds: 200_000_000)
        #expect(collector.connectedCount == 1) // the repeat is rejected 
    }

    @Test func testEveryIncomingFrameRepersistsEventIDs() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        installProvider(wallet: wallet)
        _ = try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)])
        let store = NativeSessionStore(storage: storage)
        let session = await pollSession(store) { $0 != nil }
        let clientId = try #require(session?.sessionId)

        ConnectFakeBridge.pushFrame(id: "5", data: wallet.frame(Self.connectSuccessJSONId5, to: clientId))

        // a "restart" reader sees BOTH updated ids (W2 — they survive a cold restart)
        let updated = await pollSession(store) { $0?.lastEventId == "5" && $0?.lastWalletEventId == 5 }
        #expect(updated?.lastEventId == "5")
        #expect(updated?.lastWalletEventId == 5)
        _ = engine
    }

    // MARK: - wallet-initiated disconnect (BLOCKER 1)

    @Test func testWalletInitiatedDisconnectClearsSessionAndEmitsDisconnected() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        installProvider(wallet: wallet)
        let collector = EventCollector()
        // The handle + cancel are mandatory: an unnamed Task would hold the engine
        // strongly forever (the stream finishes only in deinit — which would never come).
        let collectorTask = Task { for await event in engine.events { collector.append(event) } }
        defer { collectorTask.cancel() }
        _ = try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)])
        let store = NativeSessionStore(storage: storage)
        let session = await pollSession(store) { $0 != nil }
        let clientId = try #require(session?.sessionId)

        ConnectFakeBridge.pushFrame(id: "3", data: wallet.frame(Self.walletDisconnectJSON, to: clientId))

        #expect(await waitUntil { collector.sawDisconnected }) // yield BEFORE state teardown
        let cleared = await pollSession(store) { $0 == nil }
        #expect(cleared == nil) // store.clear()
        await #expect(throws: TonConnectError.self) { // the session is dead
            try await engine.restoreConnection()
        }
    }

    // MARK: - restore + lifecycle (mirror)

    @Test func testRestoreWithoutSessionThrowsTypedError() async {
        let engine = makeEngine(storage: InMemoryStorage())
        await #expect(throws: TonConnectError.self) {
            try await engine.restoreConnection()
        }
    }

    @Test func testRestoreReopensSSEWithSavedLastEventID() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let first = makeEngine(storage: storage)
        installProvider(wallet: wallet)
        _ = try await first.connect(source: Self.source, items: [.tonAddress(network: nil)])
        let store = NativeSessionStore(storage: storage)
        _ = await pollSession(store) { $0?.walletPublicKeyHex != nil }
        first.pauseForTesting() // the first stream is closed, does not skew the count

        // an "app restart": a new engine on the same storage (WITHOUT resetting the fake!)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ConnectFakeBridge.self]
        let second = NativeEngine(manifestUrl: "https://example.com/tonconnect-manifest.json",
                                  storage: storage, opener: SpyOpener(),
                                  sessionConfiguration: config,
                                  clock: ManualReconnectClock())
        try await second.restoreConnection()

        #expect(await waitUntil {
            ConnectFakeBridge.recordedRequestURLs.last?.absoluteString
                .contains("last_event_id=1") == true
        })
        _ = second
    }
    
    @Test func testRestoreEmitsConnectedEventFromPersistedSession() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let first = makeEngine(storage: storage)
        installProvider(wallet: wallet)
        _ = try await first.connect(source: Self.source, items: [.tonAddress(network: nil)])
        let store = NativeSessionStore(storage: storage)
        _ = await pollSession(store) { $0?.connectEventJSON != nil }
        first.pauseForTesting()

        // an "app restart": a new engine on the same storage (WITHOUT resetting the fake!)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ConnectFakeBridge.self]
        let second = NativeEngine(manifestUrl: "https://example.com/tonconnect-manifest.json",
                                  storage: storage, opener: SpyOpener(),
                                  sessionConfiguration: config,
                                  clock: ManualReconnectClock())
        let collector = EventCollector()
        let collectorTask = Task { for await event in second.events { collector.append(event) } }
        defer { collectorTask.cancel() }

        try await second.restoreConnection()

        // The engine must deliver .connected with the persisted account —
        // otherwise the facade stays in .restoring forever (observed on a live wallet).
        #expect(await waitUntil { collector.connectedCount == 1 })
        _ = second
    }

    @Test func testWakeReconnectsWithLastEventID() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        // the 2nd subscription (after wake) delivers the event "missed while asleep"
        installProvider(wallet: wallet, followUp: [(id: "5", json: Self.walletDisconnectJSON)])
        let collector = EventCollector()
        // The handle + cancel are mandatory: an unnamed Task would hold the engine
        // strongly forever (the stream finishes only in deinit — which would never come).
        let collectorTask = Task { for await event in engine.events { collector.append(event) } }
        defer { collectorTask.cancel() }
        _ = try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)])
        let store = NativeSessionStore(storage: storage)
        _ = await pollSession(store) { $0?.walletPublicKeyHex != nil }

        engine.pauseForTesting() // asleep: the line is closed
        engine.wakeForTesting() // awake: re-subscription

        #expect(await waitUntil {
            ConnectFakeBridge.recordedRequestURLs
                .filter { $0.absoluteString.contains("/events") }.count >= 2
        })
        let lastGET = ConnectFakeBridge.recordedRequestURLs
            .last { $0.absoluteString.contains("/events") }
        #expect(lastGET?.absoluteString.contains("last_event_id=1") == true) // from the same spot
        #expect(await waitUntil { collector.sawDisconnected }) // the "while asleep" event arrived
    }

    // MARK: - code-review fixes 

    @Test func testPauseDuringPendingConnectRecoversAfterWake() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        // the 1st subscription is empty ("the wallet is thinking"); the reply arrives only on the 2nd — after wake
        let calls = PerClientCounter()
        ConnectFakeBridge.eventsFrameProvider = { url in
            guard let clientId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "client_id" })?.value else { return [] }
            if calls.next(clientId) == 1 { return [] }
            return [(id: "1", data: wallet.frame(Self.connectSuccessJSON, to: clientId))]
        }

        let connectTask = Task {
            try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)])
        }
        #expect(await waitUntil {
            ConnectFakeBridge.recordedRequestURLs.contains { $0.path.contains("/events") }
        })

        engine.pauseForTesting() // the wallet is open → the app went to the background
        engine.wakeForTesting() // back — the subscription must reopen 

        let result = try await connectTask.value
        guard case .success = result else {
            Issue.record("connect must survive pause/wake while pending, got \(result)")
            return
        }
    }

    @Test func testParallelRPCRequestsGetDistinctMonotonicIDs() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        installProvider(wallet: wallet)
        _ = try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)])
        let store = NativeSessionStore(storage: storage)
        let session = await pollSession(store) { $0?.walletPublicKeyHex != nil }
        let clientId = try #require(session?.sessionId)

        ConnectFakeBridge.messageHandler = { _, body in
            guard let decrypted = wallet.decryptRPCBody(body, from: clientId),
                  let data = decrypted.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let id = object["id"] as? String else { return }
            let responseJSON = "{\"result\":\"boc-\(id)\",\"id\":\"\(id)\"}"
            ConnectFakeBridge.pushFrame(id: nil, data: wallet.frame(responseJSON, to: clientId))
        }

        let payload = SendTransactionPayload(validUntil: nil, network: nil, from: nil, messages: [])
        async let first = engine.sendTransaction(payload)
        async let second = engine.sendTransaction(payload)
        let responses = try await [first, second]

        var ids: Set<String> = []
        for response in responses {
            guard case .success(_, let id) = response else {
                Issue.record("expected success, got \(response)")
                return
            }
            ids.insert(id)
        }
        #expect(ids.count == 2) // distinct ids, both tickets resolved
    }
    
    @Test func testSendTransactionAutoFillsFromWithAccountAddress() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        installProvider(wallet: wallet)
        _ = try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)])
        let store = NativeSessionStore(storage: storage)
        let session = await pollSession(store) { $0?.walletPublicKeyHex != nil }
        let clientId = try #require(session?.sessionId)

        let sentParams = CapturedText()
        ConnectFakeBridge.messageHandler = { _, body in
            guard let decrypted = wallet.decryptRPCBody(body, from: clientId),
                  let data = decrypted.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let id = object["id"] as? String else { return }
            if let params = (object["params"] as? [String])?.first { sentParams.set(params) }
            ConnectFakeBridge.pushFrame(id: nil, data: wallet.frame("{\"result\":\"boc\",\"id\":\"\(id)\"}", to: clientId))
        }

        // Demo style: from is not passed — the engine must substitute the account
        // address (JS SDK parity, bundle.js:6009; Tonkeeper requires from and silently drops without it).
        let payload = SendTransactionPayload(validUntil: 1_785_221_364, network: "-3",
                                             from: nil, messages: [])
        _ = try await engine.sendTransaction(payload)

        #expect(sentParams.value?.contains("\"from\":\"0:fake\"") == true,
                "params[0] must carry from=account address, got \(sentParams.value ?? "nil")")
    }
    
    @Test func testBridgeHeartbeatFrameDoesNotFailPendingConnect() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        // A real bridge sends data: heartbeat AS AN EVENT (not a comment line)
        // before the wallet's reply — connect must survive it and await the envelope.
        ConnectFakeBridge.eventsFrameProvider = { url in
            guard let clientId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "client_id" })?.value else { return [] }
            return [(id: nil, data: "heartbeat"),
                    (id: "1", data: wallet.frame(Self.connectSuccessJSON, to: clientId))]
        }

        let result = try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)])

        guard case .success = result else {
            Issue.record("expected ConnectEvent.success after heartbeat frame, got \(result)")
            return
        }
    }
    
    @Test func testTamperedIncomingFrameIsIgnoredAndConnectStillSucceeds() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        // a forged frame is ignored — the genuine frame right
        // behind it must still resolve the connect.
        ConnectFakeBridge.eventsFrameProvider = { url in
            guard let clientId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "client_id" })?.value else { return [] }
            return [(id: nil, data: wallet.tamperedFrame(Self.connectSuccessJSON, to: clientId)),
                    (id: "1", data: wallet.frame(Self.connectSuccessJSON, to: clientId))]
        }

        let result = try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)])

        guard case .success = result else {
            Issue.record("expected connect to survive the forged frame, got \(result)")
            return
        }
    }
    
    @Test func testTelegramWalletLinkUsesStartappEncoding() async throws {
        let storage = InMemoryStorage()
        let opener = SpyOpener()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage, opener: opener)
        installProvider(wallet: wallet)
        let telegramSource = WalletConnectionSource(
            universalLink: "https://t.me/wallet?attach=wallet",
            bridgeUrl: Self.bridgeUrl)

        _ = try await engine.connect(source: telegramSource, items: [.tonAddress(network: nil)])

        let opened = try #require(opener.openedURLs.first)
        let components = try #require(URLComponents(url: opened, resolvingAgainstBaseURL: false))
        #expect(components.host == "t.me")
        #expect(components.path == "/wallet/start") // attach dropped, /start appended
        #expect(!(opened.absoluteString.contains("attach=")))
        let startapp = try #require(components.queryItems?.first { $0.name == "startapp" }?.value)
        #expect(startapp.hasPrefix("tonconnect-"))
        #expect(startapp.hasSuffix("-ret__back")) // ret rides inside the payload
        // Telegram's startapp alphabet: nothing but [A-Za-z0-9_-] may survive.
        #expect(startapp.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" })
        #expect(components.queryItems?.count == 1) // no loose v/id/r/ret params
    }
    
    @Test func testSendTransactionEmitsRequestSentAfterBridgeAcceptsPost() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        installProvider(wallet: wallet)
        _ = try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)])
        let store = NativeSessionStore(storage: storage)
        let session = await pollSession(store) { $0?.walletPublicKeyHex != nil }
        let clientId = try #require(session?.sessionId)

        let collector = EventCollector()
        let collectorTask = Task { for await event in engine.events { collector.append(event) } }
        defer { collectorTask.cancel() }

        ConnectFakeBridge.messageHandler = { _, body in
            guard let decrypted = wallet.decryptRPCBody(body, from: clientId),
                  let data = decrypted.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let id = object["id"] as? String else { return }
            ConnectFakeBridge.pushFrame(id: nil, data: wallet.frame("{\"result\":\"boc\",\"id\":\"\(id)\"}", to: clientId))
        }

        _ = try await engine.sendTransaction(
            SendTransactionPayload(validUntil: nil, network: nil, from: nil, messages: []))

        // The UI gates waking the wallet on this event (SDK parity: onRequestSent).
        #expect(await waitUntil { collector.all.contains(.requestSent) })
    }
}
