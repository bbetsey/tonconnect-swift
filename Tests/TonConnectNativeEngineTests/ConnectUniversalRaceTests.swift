import Foundation
import Testing
import TonConnectCore
import TonConnectTestSupport
@testable import TonConnectNativeEngine

/// The race fakes: every bridge gets ITS OWN subclass (per-class state, lesson
/// from 03-09) + a host filter in canInit — otherwise the first in protocolClasses
/// would grab every request.
private final class BridgeAFake: FakeBridgeURLProtocol {
    nonisolated(unsafe) static var failEventsConnection = false
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "bridge-a.race" && super.canInit(with: request)
    }
    override func startLoading() {
        if Self.failEventsConnection, request.url?.path.contains("/events") == true {
            if let url = request.url { Self.recordedRequestURLs.append(url) }
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
            return
        }
        super.startLoading()
    }
}

private final class BridgeBFake: FakeBridgeURLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "bridge-b.race" && super.canInit(with: request)
    }
}

private final class SpyOpener: WalletOpener, @unchecked Sendable {
    private let lock = NSLock()
    private var urls: [URL] = []
    func open(_ url: URL) { lock.lock(); urls.append(url); lock.unlock() }
    var openedURLs: [URL] { lock.lock(); defer { lock.unlock() }; return urls }
}

private final class EventCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var items: [TonConnectEvent] = []
    func append(_ event: TonConnectEvent) { lock.lock(); items.append(event); lock.unlock() }
    var all: [TonConnectEvent] { lock.lock(); defer { lock.unlock() }; return items }
    var sawLinkGenerated: Bool {
        all.contains { if case .connectLinkGenerated = $0 { return true } else { return false } }
    }
}

/// A Swift wallet simulator (a second SessionCrypto, no JSContext).
private struct WalletSimulator {
    let crypto = SessionCrypto()
    var publicKeyHex: String { HexCoding.toHexString(crypto.keyPair.publicKey) }

    func frame(_ json: String, to clientIdHex: String) -> String {
        let clientKey = (try? HexCoding.hexToByteArray(clientIdHex)) ?? []
        let cipher = (try? crypto.encrypt(json, to: clientKey)) ?? []
        return "{\"from\":\"\(publicKeyHex)\",\"message\":\"\(Data(cipher).base64EncodedString())\"}"
    }

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

@Suite(.serialized) struct ConnectUniversalRaceTests {

    static let connectSuccessJSON = """
    {"event":"connect","id":1,"payload":{"items":[{"name":"ton_addr","address":"0:fake","network":"-3","publicKey":"deadbeef","walletStateInit":"te6ccFakeInit"}],"device":{"platform":"iphone","appName":"FakeWallet","appVersion":"1.0.0","maxProtocolVersion":2,"features":[{"name":"SendTransaction","maxMessages":4},{"name":"SignData","types":["text","binary","cell"]}]}}}
    """

    private static let bridgeAUrl = "https://bridge-a.race/bridge"
    private static let bridgeBUrl = "https://bridge-b.race/bridge"

    // MARK: - helpers

    private func waitUntil(_ condition: @escaping @Sendable () -> Bool,
                           timeoutNanoseconds: UInt64 = 2_000_000_000) async -> Bool {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return condition()
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

    /// Both fakes: reset + keepEventsStreamOpen; the engine sees both hosts.
    private func makeEngine(storage: InMemoryStorage, opener: SpyOpener = SpyOpener()) -> NativeEngine {
        for fake in [BridgeAFake.self, BridgeBFake.self] as [FakeBridgeURLProtocol.Type] {
            fake.reset()
            var script = fake.Script()
            script.keepEventsStreamOpen = true
            fake.script = script
        }
        BridgeAFake.failEventsConnection = false
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [BridgeAFake.self, BridgeBFake.self]
        // ManualReconnectClock: the watchdog/cadence never tick in tests (determinism).
        return NativeEngine(manifestUrl: "https://example.com/tonconnect-manifest.json",
                            storage: storage, opener: opener, sessionConfiguration: config,
                            clock: ManualReconnectClock())
    }

    /// A valid (or forged) connect-success on this fake's first subscription.
    private func installConnectProvider(on fake: FakeBridgeURLProtocol.Type,
                                        wallet: WalletSimulator, tampered: Bool = false) {
        fake.eventsFrameProvider = { url in
            guard let clientId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "client_id" })?.value else { return [] }
            let frame = tampered
                ? wallet.tamperedFrame(Self.connectSuccessJSON, to: clientId)
                : wallet.frame(Self.connectSuccessJSON, to: clientId)
            return [(id: "1", data: frame)]
        }
    }

    // MARK: - race

    @Test func testUniversalDoesNotOpenWalletOnThisDevice() async throws {
        let storage = InMemoryStorage()
        let opener = SpyOpener()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage, opener: opener)
        installConnectProvider(on: BridgeAFake.self, wallet: wallet)
        installConnectProvider(on: BridgeBFake.self, wallet: wallet)
        let collector = EventCollector()
        // The handle + cancel are mandatory: an unnamed Task would hold the engine
        // strongly forever (the stream finishes only in deinit — which would never come).
        let collectorTask = Task { for await event in engine.events { collector.append(event) } }
        defer { collectorTask.cancel() }

        let result = try await engine.connectUniversal(bridgeURLs: [Self.bridgeAUrl, Self.bridgeBUrl],
                                                       items: [.tonAddress(network: nil)])

        guard case .success = result else {
            Issue.record("expected success, got \(result)")
            return
        }
        #expect(opener.openedURLs.isEmpty) // the wallet is NOT opened 
        #expect(await waitUntil { collector.sawLinkGenerated }) // the link left for the QR
    }

    @Test func testFirstRespondingBridgeWinsAndClosesOthers() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        installConnectProvider(on: BridgeAFake.self, wallet: wallet)
        // B is alive but silent (stream open, no frames) — only A will answer

        _ = try await engine.connectUniversal(bridgeURLs: [Self.bridgeAUrl, Self.bridgeBUrl],
                                              items: [.tonAddress(network: nil)])

        let store = NativeSessionStore(storage: storage)
        let session = await pollSession(store) { $0 != nil }
        #expect(session?.bridgeUrl == Self.bridgeAUrl) // the winner is pinned 
        // the losing gateway is closed: its live stream is taken down
        #expect(await waitUntil { BridgeBFake.liveEventStreamCount == 0 })
        _ = engine
    }

    @Test func testDeadBridgeDoesNotBlockUniversalConnect() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        BridgeAFake.failEventsConnection = true // A is dead (a network error)
        installConnectProvider(on: BridgeBFake.self, wallet: wallet)

        let result = try await engine.connectUniversal(bridgeURLs: [Self.bridgeAUrl, Self.bridgeBUrl],
                                                       items: [.tonAddress(network: nil)])

        guard case .success = result else {
            Issue.record("expected success despite dead bridge, got \(result)")
            return
        }
        let store = NativeSessionStore(storage: storage)
        let session = await pollSession(store) { $0 != nil }
        #expect(session?.bridgeUrl == Self.bridgeBUrl) // quiet degradation 
    }

    @Test func testCorruptedFirstResponderDoesNotWinRace() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        installConnectProvider(on: BridgeAFake.self, wallet: wallet, tampered: true) // a forgery
        installConnectProvider(on: BridgeBFake.self, wallet: wallet) // valid

        let result = try await engine.connectUniversal(bridgeURLs: [Self.bridgeAUrl, Self.bridgeBUrl],
                                                       items: [.tonAddress(network: nil)])

        guard case .success = result else {
            Issue.record("expected success from valid bridge, got \(result)")
            return
        }
        let store = NativeSessionStore(storage: storage)
        let session = await pollSession(store) { $0 != nil }
        #expect(session?.bridgeUrl == Self.bridgeBUrl) // the corrupted one did NOT win 
    }

    @Test func testAllGatewaysShareOneClientID() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        installConnectProvider(on: BridgeAFake.self, wallet: wallet)
        installConnectProvider(on: BridgeBFake.self, wallet: wallet)

        _ = try await engine.connectUniversal(bridgeURLs: [Self.bridgeAUrl, Self.bridgeBUrl],
                                              items: [.tonAddress(network: nil)])

        func clientID(_ url: URL?) -> String? {
            url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "client_id" }?.value }
        }
        // The race is won by bridge A's frame — bridge B's GET may not have made
        // it into recordedRequestURLs yet; wait with a ceiling, don't assert immediately.
        #expect(await waitUntil {
            !BridgeAFake.recordedRequestURLs.isEmpty && !BridgeBFake.recordedRequestURLs.isEmpty
        })
        let idA = clientID(BridgeAFake.recordedRequestURLs.first)
        let idB = clientID(BridgeBFake.recordedRequestURLs.first)
        #expect(idA != nil)
        #expect(idA == idB) // one badge for every door
        _ = engine
    }

    // MARK: - RPC over the winner (Task 1 smoke)

    @Test func testWinnerGatewayServesRPCAfterRace() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)
        BridgeAFake.failEventsConnection = true
        installConnectProvider(on: BridgeBFake.self, wallet: wallet)
        _ = try await engine.connectUniversal(bridgeURLs: [Self.bridgeAUrl, Self.bridgeBUrl],
                                              items: [.tonAddress(network: nil)])
        let store = NativeSessionStore(storage: storage)
        let session = await pollSession(store) { $0 != nil }
        let clientId = try #require(session?.sessionId)

        // The wallet: decrypt the POST, reply success with the same id as an SSE frame
        BridgeBFake.messageHandler = { _, body in
            guard let decrypted = wallet.decryptRPCBody(body, from: clientId),
                  let data = decrypted.data(using: .utf8),
                  let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let id = object["id"] as? String else { return }
            let responseJSON = "{\"result\":\"boc-fake\",\"id\":\"\(id)\"}"
            BridgeBFake.pushFrame(id: "10", data: wallet.frame(responseJSON, to: clientId))
        }

        let response = try await engine.sendTransaction(
            SendTransactionPayload(validUntil: nil, network: nil, from: nil, messages: []))

        guard case .success(let result, let id) = response else {
            Issue.record("expected WalletResponse.success, got \(response)")
            return
        }
        #expect(result == "boc-fake")
        #expect(id == "1") // the new session's first RPC — the monotonic counter from the store
    }

    // MARK: - code-review fix 

    @Test func testSecondUniversalConnectClosesPreviousGatewayPack() async throws {
        let storage = InMemoryStorage()
        let wallet = WalletSimulator()
        let engine = makeEngine(storage: storage)

        // The first race hangs: both bridges are silent (streams open)
        let firstAttempt = Task {
            try? await engine.connectUniversal(bridgeURLs: [Self.bridgeAUrl, Self.bridgeBUrl],
                                               items: [.tonAddress(network: nil)])
        }
        #expect(await waitUntil {
            BridgeAFake.liveEventStreamCount == 1 && BridgeBFake.liveEventStreamCount == 1
        })

        // The second race: the old batch must close ; now B answers
        installConnectProvider(on: BridgeBFake.self, wallet: wallet)
        let result = try await engine.connectUniversal(bridgeURLs: [Self.bridgeAUrl, Self.bridgeBUrl],
                                                       items: [.tonAddress(network: nil)])
        guard case .success = result else {
            Issue.record("expected success from second race, got \(result)")
            return
        }
        // the old A/B are closed by the 2nd race's start, the new A is closed as the loser
        #expect(await waitUntil {
            BridgeAFake.liveEventStreamCount == 0 && BridgeBFake.liveEventStreamCount == 1
        })
        firstAttempt.cancel()
    }
}
