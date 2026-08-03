import Foundation
import JavaScriptCore
import Testing
import TonConnectCore
import TonConnectTestSupport
@testable import TonConnectJSCoreEngine

/// This suite's isolated scenario (fake v3 — per-class state).
private final class ReconnectFakeBridge: FakeBridgeURLProtocol {}

/// A thread-safe provider-call counter.
private final class CountBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    func increment() -> Int { lock.lock(); defer { lock.unlock() }; value += 1; return value }
}

/// The automated tier: suspension is simulated via the
/// simulateWake hook; the event "missed while asleep" catches up after wake via
/// last_event_id. The real background/foreground — the 03-10 device checklist.
@Suite(.serialized) struct ForegroundReconnectTests {

    private static let walletDisconnectJSON = """
    {"event":"disconnect","id":2,"payload":{}}
    """

    private func makeConnectedEngine() async throws -> JSCoreEngine {
        ReconnectFakeBridge.reset()
        var script = ReconnectFakeBridge.Script()
        script.keepEventsStreamOpen = true
        ReconnectFakeBridge.script = script
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ReconnectFakeBridge.self]
        let engine = try JSCoreEngine(
            manifestUrl: "https://example.com/tonconnect-manifest.json",
            storage: InMemoryStorage(),
            opener: SpyOpener(),
            bridge: JSCoreBridge(transportConfiguration: config)
        )

        let bridge = engine.bridge
        let walletPub = bridge.perform { ctx in
            ctx.evaluateScript("__tcTestWalletCreate()")?.toString() ?? ""
        }
        let callCount = CountBox()
        // The state machine: the 1st stream — the wallet's connect reply (SSE id
        // "1"); every following one (after wake) — the event "missed while asleep" (id "7").
        ReconnectFakeBridge.eventsFrameProvider = { [weak bridge] url in
            guard let bridge,
                  let clientId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                      .queryItems?.first(where: { $0.name == "client_id" })?.value else { return [] }
            let call = callCount.increment()
            let (frameId, eventJSON) = call == 1
                ? ("1", FakeBridgeE2ETests.connectSuccessJSON)
                : ("7", Self.walletDisconnectJSON)
            let frame = bridge.perform { ctx -> String in
                let encrypted = ctx.evaluateScript(
                    "__tcTestWalletEncrypt(\(FakeBridgeE2ETests.js(clientId)), \(FakeBridgeE2ETests.js(eventJSON)))"
                )?.toString() ?? ""
                return "{\"from\":\"\(walletPub)\",\"message\":\"\(encrypted)\"}"
            }
            return [(id: frameId, data: frame)]
        }

        _ = try await engine.connect(
            source: WalletConnectionSource(universalLink: "https://wallet.reconnect/tc",
                                           bridgeUrl: "https://bridge.reconnect/bridge"),
            items: [.tonAddress(network: nil)]
        )
        return engine
    }

    /// Awaits .disconnected from engine.events with a ceiling (the suite's awaitEvent idiom).
    private func awaitDisconnected(from engine: JSCoreEngine,
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

    @Test func testSimulateWakeReconnectsAndDeliversEventMissedDuringSuspension() async throws {
        let engine = try await makeConnectedEngine()
        engine.lifecycle.pause() // "asleep": the SDK closed SSE
        engine.lifecycle.simulateWake() // "awake" → the SDK recreates the EventSource
        let received = await awaitDisconnected(from: engine)
        #expect(received, "an event arriving during suspension must catch up after wake")
    }

    @Test func testSecondEventsRequestCarriesLastEventId() async throws {
        let engine = try await makeConnectedEngine()
        engine.lifecycle.pause()
        engine.lifecycle.simulateWake()
        for _ in 0..<200 {
            if ReconnectFakeBridge.recordedRequestURLs.filter({ $0.path.contains("/events") }).count >= 2 { break }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        let eventsURLs = ReconnectFakeBridge.recordedRequestURLs.filter { $0.path.contains("/events") }
        #expect(eventsURLs.count >= 2, "wake must reopen SSE")
        #expect(eventsURLs.last?.query?.contains("last_event_id=1") == true,
                "reconnect carries the saved frame's last_event_id, got \(String(describing: eventsURLs.last))")
        _ = engine // keep the engine alive until the checks finish
    }
}
