import Foundation
import Testing
import TonConnectCore
import TonConnectTestSupport
@testable import TonConnectNativeEngine

/// Session boundaries, adversarially: frames from a key other than the pinned
/// wallet, replies that arrive after the app gave up, a bridge that refuses a
/// disconnect, a request issued while a new connect is pending. Every test here
/// began as a probe that PASSED against the vulnerable engine (security review,
/// 2026-09-11); the expectations are inverted.
private final class BoundaryFakeBridge: FakeBridgeURLProtocol {}
private struct NoopOpener: WalletOpener { func open(_ url: URL) {} }

/// A wallet (or an impostor) played by a second SessionCrypto: seals a frame to
/// the dApp's client_id under ITS OWN key, with `from` = its key.
private struct WalletSimulator {
    let crypto = SessionCrypto()
    var publicKeyHex: String { HexCoding.toHexString(crypto.keyPair.publicKey) }
    func frame(_ json: String, to clientIdHex: String) -> String {
        let clientKey = (try? HexCoding.hexToByteArray(clientIdHex)) ?? []
        let cipher = (try? crypto.encrypt(json, to: clientKey)) ?? []
        return "{\"from\":\"\(publicKeyHex)\",\"message\":\"\(Data(cipher).base64EncodedString())\"}"
    }
}

private final class EventCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [TonConnectEvent] = []
    func append(_ event: TonConnectEvent) { lock.lock(); items.append(event); lock.unlock() }
    var all: [TonConnectEvent] { lock.lock(); defer { lock.unlock() }; return items }
    var connectedAddresses: [String] {
        all.compactMap { event -> String? in
            guard case .connected(let ce) = event, case .success(_, let payload, _) = ce else { return nil }
            for item in payload.items { if case .tonAddress(let r) = item { return r.address } }
            return nil
        }
    }
    var sawDisconnected: Bool { all.contains(.disconnected) }
}

private final class Box<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var v: T
    init(_ v: T) { self.v = v }
    var value: T {
        get { lock.lock(); defer { lock.unlock() }; return v }
        set { lock.lock(); v = newValue; lock.unlock() }
    }
}

@Suite(.serialized) struct SessionBoundaryTests {

    static func connectJSON(address: String, id: Int) -> String {
        """
        {"event":"connect","id":\(id),"payload":{"items":[{"name":"ton_addr","address":"\(address)","network":"-3","publicKey":"deadbeef","walletStateInit":"x"}],"device":{"platform":"iphone","appName":"W","appVersion":"1","maxProtocolVersion":2,"features":[]}}}
        """
    }
    private static let source = WalletConnectionSource(universalLink: "https://wallet.native/tc",
                                                       bridgeUrl: "https://bridge.native/bridge")
    private static let source2 = WalletConnectionSource(universalLink: "https://wallet2.native/tc",
                                                        bridgeUrl: "https://bridge2.native/bridge")
    private static let payload = SendTransactionPayload(validUntil: nil, network: nil, from: nil, messages: [])

    private func waitUntil(_ condition: @escaping @Sendable () -> Bool,
                           timeoutNanoseconds: UInt64 = 15_000_000_000) async -> Bool {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return condition()
    }

    /// The negative wait: the condition must NOT come true within the window.
    private func stays(quietFor nanoseconds: UInt64 = 300_000_000,
                       _ condition: @escaping @Sendable () -> Bool) async -> Bool {
        let deadline = DispatchTime.now().uptimeNanoseconds + nanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if condition() { return false }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return !condition()
    }

    private func pollSession(_ store: NativeSessionStore,
                             until predicate: (NativeSession?) -> Bool) async -> NativeSession? {
        for _ in 0..<200 {
            let session = try? await store.load()
            if predicate(session) { return session }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return try? await store.load()
    }

    private func makeEngine(storage: InMemoryStorage, postStatus: Int = 200) -> NativeEngine {
        BoundaryFakeBridge.reset()
        var script = BoundaryFakeBridge.Script()
        script.keepEventsStreamOpen = true
        script.postStatus = postStatus
        BoundaryFakeBridge.script = script
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [BoundaryFakeBridge.self]
        return NativeEngine(manifestUrl: "https://example.com/m.json", storage: storage,
                            opener: NoopOpener(), sessionConfiguration: config,
                            clock: ManualReconnectClock())
    }

    private static func clientId(of url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?
            .first { $0.name == "client_id" }?.value
    }

    /// Connects with the genuine wallet; returns the dApp's client_id and the store.
    private func connectGenuine(_ engine: NativeEngine, storage: InMemoryStorage,
                                wallet: WalletSimulator) async throws -> (String, NativeSessionStore) {
        BoundaryFakeBridge.eventsFrameProvider = { url in
            guard let clientId = Self.clientId(of: url) else { return [] }
            return [(id: "1", data: wallet.frame(Self.connectJSON(address: "0:genuine", id: 1), to: clientId))]
        }
        _ = try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)])
        let store = NativeSessionStore(storage: storage)
        let session = await pollSession(store) { $0?.walletPublicKeyHex != nil }
        return (try #require(session?.sessionId), store)
    }

    /// Runs an operation with a real-time ceiling; nil = it did not finish.
    private func within<T: Sendable>(_ nanoseconds: UInt64,
                                     _ operation: @escaping @Sendable () async throws -> T) async throws -> T? {
        try await withThrowingTaskGroup(of: T?.self) { group in
            group.addTask { try await operation() }
            group.addTask { try await Task.sleep(nanoseconds: nanoseconds); return nil }
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }

    // MARK: - the pinned wallet key (HIGH-1)

    @Test func testReplyFromAKeyOtherThanThePinnedWalletDoesNotResolveTheRequest() async throws {
        let storage = InMemoryStorage()
        let genuine = WalletSimulator(), impostor = WalletSimulator()
        let engine = makeEngine(storage: storage)
        let (clientId, _) = try await connectGenuine(engine, storage: storage, wallet: genuine)

        // The impostor answers first, then the wallet: only the wallet's answer counts.
        BoundaryFakeBridge.messageHandler = { _, _ in
            BoundaryFakeBridge.pushFrame(id: "2", data: impostor.frame("{\"id\":\"1\",\"result\":\"FORGED\"}", to: clientId))
            Task {
                try? await Task.sleep(nanoseconds: 150_000_000)
                BoundaryFakeBridge.pushFrame(id: "3", data: genuine.frame("{\"id\":\"1\",\"result\":\"GENUINE\"}", to: clientId))
            }
        }
        let response = try await engine.sendTransaction(Self.payload)
        #expect(response == .success(result: "GENUINE", id: "1"))
    }

    @Test func testConnectEventFromAKeyOtherThanThePinnedWalletDoesNotRepinTheSession() async throws {
        let storage = InMemoryStorage()
        let genuine = WalletSimulator(), impostor = WalletSimulator()
        let engine = makeEngine(storage: storage)
        let collector = EventCollector()
        let task = Task { for await e in engine.events { collector.append(e) } }
        defer { task.cancel() }
        let (clientId, store) = try await connectGenuine(engine, storage: storage, wallet: genuine)
        #expect(await waitUntil { collector.connectedAddresses == ["0:genuine"] })

        BoundaryFakeBridge.pushFrame(id: "2", data: impostor.frame(Self.connectJSON(address: "0:impostor", id: 99), to: clientId))

        #expect(await stays { collector.connectedAddresses.count > 1 }, "no second .connected")
        let session = try await store.load()
        #expect(session?.walletPublicKeyHex == genuine.publicKeyHex, "the persisted wallet key is still the wallet's")

        // The next request is still addressed to the wallet.
        let posted = Box<URL?>(nil)
        BoundaryFakeBridge.messageHandler = { url, _ in
            posted.value = url
            BoundaryFakeBridge.pushFrame(id: "3", data: genuine.frame("{\"id\":\"1\",\"result\":\"ok\"}", to: clientId))
        }
        _ = try await engine.sendTransaction(Self.payload)
        let to = posted.value.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "to" }?.value }
        #expect(to == genuine.publicKeyHex)
    }

    @Test func testDisconnectEventFromAKeyOtherThanThePinnedWalletIsIgnored() async throws {
        let storage = InMemoryStorage()
        let genuine = WalletSimulator(), impostor = WalletSimulator()
        let engine = makeEngine(storage: storage)
        let collector = EventCollector()
        let task = Task { for await e in engine.events { collector.append(e) } }
        defer { task.cancel() }
        let (clientId, store) = try await connectGenuine(engine, storage: storage, wallet: genuine)

        BoundaryFakeBridge.pushFrame(id: "2", data: impostor.frame("{\"event\":\"disconnect\",\"id\":5,\"payload\":{}}", to: clientId))

        #expect(await stays { collector.sawDisconnected })
        let session = try await store.load()
        #expect(session?.walletPublicKeyHex == genuine.publicKeyHex, "the session is untouched")
    }

    /// A foreign frame must not move the replay counter either — otherwise a
    /// stranger could park it at Int.max and the wallet's own disconnect would
    /// be rejected as a replay.
    @Test func testForeignEventDoesNotPoisonTheReplayCounterForTheWalletsOwnDisconnect() async throws {
        let storage = InMemoryStorage()
        let genuine = WalletSimulator(), impostor = WalletSimulator()
        let engine = makeEngine(storage: storage)
        let collector = EventCollector()
        let task = Task { for await e in engine.events { collector.append(e) } }
        defer { task.cancel() }
        let (clientId, store) = try await connectGenuine(engine, storage: storage, wallet: genuine)

        BoundaryFakeBridge.pushFrame(id: "2", data: impostor.frame("{\"event\":\"disconnect\",\"id\":\(Int.max),\"payload\":{}}", to: clientId))
        #expect(await stays { collector.sawDisconnected })
        BoundaryFakeBridge.pushFrame(id: "3", data: genuine.frame("{\"event\":\"disconnect\",\"id\":2,\"payload\":{}}", to: clientId))

        #expect(await waitUntil { collector.sawDisconnected }, "the wallet's own disconnect still works")
        let session = await pollSession(store) { $0 == nil }
        #expect(session == nil)
    }

    /// Even the pinned wallet cannot "connect again" into a live session: a connect
    /// event is an answer, and without a connect in flight there is no question.
    @Test func testConnectEventWithoutAConnectInFlightIsIgnored() async throws {
        let storage = InMemoryStorage()
        let genuine = WalletSimulator()
        let engine = makeEngine(storage: storage)
        let collector = EventCollector()
        let task = Task { for await e in engine.events { collector.append(e) } }
        defer { task.cancel() }
        let (clientId, store) = try await connectGenuine(engine, storage: storage, wallet: genuine)
        #expect(await waitUntil { collector.connectedAddresses == ["0:genuine"] })

        BoundaryFakeBridge.pushFrame(id: "2", data: genuine.frame(Self.connectJSON(address: "0:other", id: 7), to: clientId))

        #expect(await stays { collector.connectedAddresses.count > 1 })
        let session = try await store.load()
        #expect(session?.connectEventJSON?.contains("0:genuine") == true)
    }

    // MARK: - disconnect() always ends the session locally (MEDIUM-1)

    @Test func testDisconnectWithAFailingBridgeStillClearsTheSessionAndReportsTheDeliveryError() async throws {
        let storage = InMemoryStorage()
        let genuine = WalletSimulator()
        let engine = makeEngine(storage: storage, postStatus: 503)
        let collector = EventCollector()
        let task = Task { for await e in engine.events { collector.append(e) } }
        defer { task.cancel() }
        let (_, store) = try await connectGenuine(engine, storage: storage, wallet: genuine)

        await #expect(throws: TonConnectError.self) { try await engine.disconnect() }

        let session = try await store.load()
        #expect(session == nil, "the record — secret included — is gone")
        #expect(await waitUntil { collector.sawDisconnected })
        await #expect(throws: TonConnectError.self, "no session left to send from") {
            _ = try await engine.sendTransaction(Self.payload)
        }
        #expect(!BoundaryFakeBridge.recordedRequestURLs.contains { $0.path.contains("/message") && $0.query?.contains("sendTransaction") == true })
    }

    // MARK: - a connect attempt that ends, ends (MEDIUM-2, LOW-1)

    @Test func testWalletReplyAfterACancelledConnectIsIgnoredAndThePendingRecordIsGone() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        let collector = EventCollector()
        let task = Task { for await e in engine.events { collector.append(e) } }
        defer { task.cancel() }
        let subscribedClient = Box<String?>(nil)
        BoundaryFakeBridge.eventsFrameProvider = { url in subscribedClient.value = Self.clientId(of: url); return [] }

        let connectTask = Task { try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)]) }
        #expect(await waitUntil { subscribedClient.value != nil })
        connectTask.cancel()
        await #expect(throws: CancellationError.self) { _ = try await connectTask.value }

        let clientId = try #require(subscribedClient.value)
        let store = NativeSessionStore(storage: storage)
        let pending = await pollSession(store) { $0 == nil }
        #expect(pending == nil, "the pending record is discarded with the attempt")

        BoundaryFakeBridge.pushFrame(id: "1", data: wallet.frame(Self.connectJSON(address: "0:late", id: 1), to: clientId))
        #expect(await stays { !collector.connectedAddresses.isEmpty }, "a late Approve connects nothing")
        #expect(try await store.load() == nil)
    }

    @Test func testWalletDeclineEndsTheAttemptSoALaterApproveConnectsNothing() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        let collector = EventCollector()
        let task = Task { for await e in engine.events { collector.append(e) } }
        defer { task.cancel() }
        BoundaryFakeBridge.eventsFrameProvider = { url in
            guard let clientId = Self.clientId(of: url) else { return [] }
            return [(id: "1", data: wallet.frame("{\"event\":\"connect_error\",\"id\":1,\"payload\":{\"code\":300,\"message\":\"no\"}}", to: clientId))]
        }
        let subscribed = Box<String?>(nil)
        BoundaryFakeBridge.eventsFrameProvider = { url in
            let clientId = Self.clientId(of: url)
            subscribed.value = clientId
            guard let clientId else { return [] }
            return [(id: "1", data: wallet.frame("{\"event\":\"connect_error\",\"id\":1,\"payload\":{\"code\":300,\"message\":\"no\"}}", to: clientId))]
        }
        await #expect(throws: TonConnectError.self) {
            _ = try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)])
        }
        let clientId = try #require(subscribed.value)
        BoundaryFakeBridge.pushFrame(id: "2", data: wallet.frame(Self.connectJSON(address: "0:late", id: 2), to: clientId))
        #expect(await stays { !collector.connectedAddresses.isEmpty })
        let store = NativeSessionStore(storage: storage)
        let record = await pollSession(store) { $0 == nil }
        #expect(record == nil)
    }

    @Test func testRequestDuringAPendingReconnectIsRefusedInsteadOfGoingOutUnderTheOldWalletKey() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        let subs = Box<[String]>([])
        BoundaryFakeBridge.eventsFrameProvider = { url in
            guard let clientId = Self.clientId(of: url) else { return [] }
            subs.value = subs.value + [clientId]
            if subs.value.count == 1 {
                return [(id: "1", data: wallet.frame(Self.connectJSON(address: "0:first", id: 1), to: clientId))]
            }
            return [] // the second connect stays pending
        }
        _ = try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)])
        let second = Task { try await engine.connect(source: Self.source2, items: [.tonAddress(network: nil)]) }
        defer { second.cancel() }
        #expect(await waitUntil { subs.value.count == 2 })

        let posted = Box<Bool>(false)
        BoundaryFakeBridge.messageHandler = { _, _ in posted.value = true }
        await #expect(throws: TonConnectError.self) { _ = try await engine.sendTransaction(Self.payload) }
        #expect(!posted.value, "nothing was posted")
    }

    // MARK: - a cancelled request is not forgotten (MEDIUM-6)

    @Test func testIDLessReplyAfterACancelledRequestIsNotAdoptedByTheNextOne() async throws {
        let storage = InMemoryStorage()
        let genuine = WalletSimulator()
        let engine = makeEngine(storage: storage)
        let (clientId, _) = try await connectGenuine(engine, storage: storage, wallet: genuine)

        // A: posted, then cancelled after the bridge accepted it.
        let postedA = Box<Bool>(false)
        BoundaryFakeBridge.messageHandler = { _, _ in postedA.value = true }
        let a = Task { try await engine.sendTransaction(Self.payload) }
        #expect(await waitUntil { postedA.value })
        a.cancel()
        await #expect(throws: CancellationError.self) { _ = try await a.value }

        // B in flight; the wallet's late, id-less answer to A must not land on B.
        BoundaryFakeBridge.messageHandler = { _, _ in
            BoundaryFakeBridge.pushFrame(id: "2", data: genuine.frame("{\"result\":\"boc-of-A\"}", to: clientId))
        }
        let b = try await within(400_000_000) { try await engine.signData(.text(text: "x", network: nil, from: nil)) }
        #expect(b == nil, "B is still waiting: the id-less frame was not adopted")

        // An answer WITH B's id still resolves B.
        BoundaryFakeBridge.messageHandler = nil
        let bTask = Task { try await engine.signData(.text(text: "y", network: nil, from: nil)) }
        let recorded = Box<Int>(0)
        BoundaryFakeBridge.messageHandler = { _, _ in
            recorded.value += 1
            BoundaryFakeBridge.pushFrame(id: "3", data: genuine.frame("{\"id\":\"3\",\"result\":\"sig-of-B\"}", to: clientId))
        }
        _ = try await within(2_000_000_000) { try await bTask.value }
        // (ids: A=1, first B=2 — cancelled by `within` —, this B=3)
    }

    // MARK: - universal race batch (LOW-13)

    @Test func testASecondWakeDuringAPendingUniversalConnectClosesTheFirstBatch() async throws {
        let storage = InMemoryStorage()
        let engine = makeEngine(storage: storage)
        BoundaryFakeBridge.eventsFrameProvider = { _ in [] }
        let race = Task {
            try await engine.connectUniversal(bridgeURLs: ["https://one.native/bridge", "https://two.native/bridge"],
                                              items: [.tonAddress(network: nil)])
        }
        defer { race.cancel() }
        #expect(await waitUntil { BoundaryFakeBridge.liveEventStreamCount == 2 })
        var subscriptions: Int { BoundaryFakeBridge.recordedRequestURLs.filter { $0.path.contains("/events") }.count }

        // Two wakes, each allowed to subscribe before the next: the second batch
        // must close the first, not pile on top of it. (Wakes racing each other
        // would only test the fake's bookkeeping — a stream cancelled between
        // its start and its registration is counted as live though it is not.)
        engine.wakeForTesting()
        #expect(await waitUntil { subscriptions >= 4 })
        engine.wakeForTesting()
        #expect(await waitUntil { subscriptions >= 6 })

        #expect(await waitUntil { BoundaryFakeBridge.liveEventStreamCount == 2 },
                "one live stream per bridge, the earlier batches closed; got \(BoundaryFakeBridge.liveEventStreamCount)")
        #expect(await stays { BoundaryFakeBridge.liveEventStreamCount != 2 }, "and it stays that way")
    }
}
