import Foundation
import Testing
import TonConnectCore
import TonConnectTestSupport
@testable import TonConnectNativeEngine

/// This suite's isolated scenario (fake v3 — per-class state).
private final class NativeReconnectFakeBridge: FakeBridgeURLProtocol {}

private final class SpyOpener: WalletOpener, @unchecked Sendable {
    func open(_ url: URL) {}
}

/// A PER-client_id subscription counter (see NativeEngineConnectTests: guards
/// against late GETs of closed gateways under load).
private final class PerClientCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var counts: [String: Int] = [:]
    func next(_ clientId: String) -> Int {
        lock.lock(); defer { lock.unlock() }
        counts[clientId, default: 0] += 1
        return counts[clientId]!
    }
}

private struct WalletSimulator {
    let crypto = SessionCrypto()
    var publicKeyHex: String { HexCoding.toHexString(crypto.keyPair.publicKey) }
    func frame(_ json: String, to clientIdHex: String) -> String {
        let clientKey = (try? HexCoding.hexToByteArray(clientIdHex)) ?? []
        let cipher = (try? crypto.encrypt(json, to: clientKey)) ?? []
        return "{\"from\":\"\(publicKeyHex)\",\"message\":\"\(Data(cipher).base64EncodedString())\"}"
    }
}

/// The resume mirror: suspension is simulated via pauseForTesting/wakeForTesting
/// (the counterpart of lifecycle.simulateWake in the JSCore tests); the event
/// "missed while asleep" catches up after wake via last_event_id.
@Suite(.serialized) struct NativeForegroundReconnectTests {

    static let connectSuccessJSON = """
    {"event":"connect","id":1,"payload":{"items":[{"name":"ton_addr","address":"0:fake","network":"-3","publicKey":"deadbeef","walletStateInit":"te6ccFakeInit"}],"device":{"platform":"iphone","appName":"FakeWallet","appVersion":"1.0.0","maxProtocolVersion":2,"features":[{"name":"SendTransaction","maxMessages":4},{"name":"SignData","types":["text","binary","cell"]}]}}}
    """

    static let walletDisconnectJSON = """
    {"event":"disconnect","id":2,"payload":{}}
    """

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

    /// The state machine: the 1st subscription — connect (SSE id "1"); every
    /// following one (after wake) — the event "missed while asleep" (SSE id "7").
    private func makeConnectedEngine(storage: InMemoryStorage) async throws -> NativeEngine {
        NativeReconnectFakeBridge.reset()
        var script = NativeReconnectFakeBridge.Script()
        script.keepEventsStreamOpen = true
        NativeReconnectFakeBridge.script = script
        let wallet = WalletSimulator()
        let calls = PerClientCounter()
        NativeReconnectFakeBridge.eventsFrameProvider = { url in
            guard let clientId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "client_id" })?.value else { return [] }
            if calls.next(clientId) == 1 {
                return [(id: "1", data: wallet.frame(Self.connectSuccessJSON, to: clientId))]
            }
            return [(id: "7", data: wallet.frame(Self.walletDisconnectJSON, to: clientId))]
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [NativeReconnectFakeBridge.self]
        // ManualReconnectClock: the re-subscription here is done by wakeForTesting
        // directly; the watchdog is unneeded and must not tick on a slow run.
        let engine = NativeEngine(manifestUrl: "https://example.com/tonconnect-manifest.json",
                                  storage: storage, opener: SpyOpener(),
                                  sessionConfiguration: config,
                                  clock: ManualReconnectClock())
        _ = try await engine.connect(
            source: WalletConnectionSource(universalLink: "https://wallet.fg/tc",
                                           bridgeUrl: "https://bridge.fg/bridge"),
            items: [.tonAddress(network: nil)])
        // the session persist is asynchronous — wait, or wake won't find last_event_id
        _ = await pollSession(NativeSessionStore(storage: storage)) { $0 != nil }
        return engine
    }

    /// The awaitEvent idiom with a ceiling (a silent engine fails the assert instead of hanging).
    private func awaitDisconnected(from engine: NativeEngine,
                                   timeoutNanoseconds: UInt64 = 5_000_000_000) async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                for await event in engine.events where event == .disconnected { return true }
                return false
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                return false
            }
            let first = await group.next() ?? false
            group.cancelAll()
            return first
        }
    }

    // MARK: - resume after suspension

    @Test func testSimulateWakeReconnectsAndDeliversEventMissedDuringSuspension() async throws {
        let engine = try await makeConnectedEngine(storage: InMemoryStorage())

        engine.pauseForTesting() // asleep: SSE closed
        engine.wakeForTesting() // awake: re-subscription with last_event_id

        #expect(await awaitDisconnected(from: engine)) // the "while asleep" event arrived
    }

    @Test func testSecondEventsRequestCarriesLastEventID() async throws {
        let engine = try await makeConnectedEngine(storage: InMemoryStorage())

        engine.pauseForTesting()
        engine.wakeForTesting()

        #expect(await waitUntil {
            NativeReconnectFakeBridge.recordedRequestURLs
                .filter { $0.path.contains("/events") }.count >= 2
        })
        let lastGET = NativeReconnectFakeBridge.recordedRequestURLs
            .last { $0.path.contains("/events") }
        #expect(lastGET?.absoluteString.contains("last_event_id=1") == true)
        _ = engine
    }
}
