import Foundation
import Testing
import TonConnectCore
import TonConnectTestSupport
@testable import TonConnectNativeEngine

/// This suite's isolated scenario (fake v3 — per-class state, lesson from).
/// failEventsConnection=true simulates a dead host: GET /events fails with a
/// network error BEFORE any HTTP response — onError WITHOUT onOpen, the cadence
/// escalates 2s→5s .
private final class ReconnectGatewayFakeBridge: FakeBridgeURLProtocol {
    nonisolated(unsafe) static var failEventsConnection = false

    override func startLoading() {
        if Self.failEventsConnection, request.url?.path.contains("/events") == true {
            if let url = request.url { Self.recordedRequestURLs.append(url) }
            client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
            return
        }
        super.startLoading()
    }
}

/// A thread-safe delivery counter (after ForegroundReconnectTests' CountBox).
private final class CountBox: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    func increment() { lock.lock(); value += 1; lock.unlock() }
    var count: Int { lock.lock(); defer { lock.unlock() }; return value }
}

@Suite(.serialized) struct ReconnectGatewayTests {

    /// Bounded condition wait: a silent gateway fails the assert instead of
    /// hanging the run (the conformance awaitEvent idiom).
    ///
    /// The ceiling is paid only on failure — a green run returns the moment the
    /// condition holds — so it is set for the slowest machine the suite runs on,
    /// not the fastest. It was 2s; testFirstReconnectWaitsTwoSecondsThenFiveSeconds
    /// failed once on the CI runner (PR #39, green on re-run, never reproduced
    /// locally in 34 runs), where this suite shares the bundle with suites that
    /// run in parallel and hammer URLSession through the same fake protocol.
    private func waitUntil(_ condition: @escaping @Sendable () -> Bool,
                           timeoutNanoseconds: UInt64 = 15_000_000_000) async -> Bool {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return condition()
    }

    /// heartbeatTimeout=1000 by default: in requestedIntervals the reconnect
    /// pauses (2/5) are separated from watchdog arms by the `< 1_000` filter.
    private func makeGateway(clock: ManualReconnectClock,
                             heartbeatTimeout: TimeInterval = 1_000) -> ReconnectGateway {
        ReconnectGatewayFakeBridge.reset()
        ReconnectGatewayFakeBridge.failEventsConnection = false
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ReconnectGatewayFakeBridge.self]
        return ReconnectGateway(bridgeUrl: "https://bridge.gw/bridge",
                                clientId: "aa",
                                sessionConfiguration: config,
                                clock: clock,
                                heartbeatTimeout: heartbeatTimeout)
    }

    private func reconnectDelays(_ clock: ManualReconnectClock) -> [Double] {
        clock.requestedIntervals.filter { $0 < 1_000 }
    }

    // MARK: - cadence 

    @Test func testFirstReconnectWaitsTwoSecondsThenFiveSeconds() async {
        let clock = ManualReconnectClock()
        let gateway = makeGateway(clock: clock)
        ReconnectGatewayFakeBridge.failEventsConnection = true

        gateway.start()
        #expect(await waitUntil { clock.requestedIntervals.count == 1 })
        clock.advance(by: 2)
        #expect(await waitUntil { clock.requestedIntervals.count == 2 })
        clock.advance(by: 5)
        #expect(await waitUntil { clock.requestedIntervals.count == 3 })
        #expect(clock.requestedIntervals == [2.0, 5.0, 5.0]) // step 0→2s, then 5s indefinitely
        gateway.close()
    }

    @Test func testSuccessfulOpenResetsCadenceToTwoSeconds() async {
        let clock = ManualReconnectClock()
        let gateway = makeGateway(clock: clock)
        var script = ReconnectGatewayFakeBridge.Script()
        script.keepEventsStreamOpen = false // 200 → onOpen → the stream finishes → onError
        ReconnectGatewayFakeBridge.script = script
        ReconnectGatewayFakeBridge.failEventsConnection = true

        gateway.start()
        #expect(await waitUntil { self.reconnectDelays(clock).count == 1 }) // [2]
        clock.advance(by: 2)
        #expect(await waitUntil { self.reconnectDelays(clock).count == 2 }) // [2, 5]
        // the host "came back": the next attempt yields onOpen (step reset), the stream closes → a drop
        ReconnectGatewayFakeBridge.failEventsConnection = false
        clock.advance(by: 5)
        #expect(await waitUntil { self.reconnectDelays(clock).count == 3 })
        #expect(reconnectDelays(clock) == [2.0, 5.0, 2.0]) // after onOpen — 2s again
        gateway.close()
    }

    // MARK: - last_event_id / single live source

    @Test func testReconnectCarriesLastEventID() async {
        let clock = ManualReconnectClock()
        let gateway = makeGateway(clock: clock)
        var script = ReconnectGatewayFakeBridge.Script()
        script.sseFrames = [(id: "42", data: "hello")]
        script.keepEventsStreamOpen = false
        ReconnectGatewayFakeBridge.script = script

        gateway.start()
        #expect(await waitUntil { self.reconnectDelays(clock).count == 1 })
        clock.advance(by: 2)
        #expect(await waitUntil { ReconnectGatewayFakeBridge.recordedRequestURLs.count >= 2 })
        let lastURL = ReconnectGatewayFakeBridge.recordedRequestURLs.last?.absoluteString ?? ""
        #expect(lastURL.contains("last_event_id=42"))
        gateway.close()
    }

    @Test func testOnlyOneLiveEventSourceDuringReconnect() async {
        let clock = ManualReconnectClock()
        let gateway = makeGateway(clock: clock, heartbeatTimeout: 30)
        var script = ReconnectGatewayFakeBridge.Script()
        script.keepEventsStreamOpen = true
        ReconnectGatewayFakeBridge.script = script

        let received = CountBox()
        gateway.onMessage = { _, _ in received.increment() }
        gateway.start()
        #expect(await waitUntil { clock.requestedIntervals.contains(30.0) }) // the watchdog is armed

        clock.advance(by: 30) // total silence → a "quiet death" → reconnect
        #expect(await waitUntil { clock.requestedIntervals.contains(2.0) })
        clock.advance(by: 2)
        #expect(await waitUntil { ReconnectGatewayFakeBridge.recordedRequestURLs.count >= 2 })
        #expect(await waitUntil { clock.requestedIntervals.filter { $0 == 30.0 }.count >= 2 })

        // a frame into ALL of the subclass's live streams: had the old source
        // stayed alive, the gateway would receive a duplicate 
        ReconnectGatewayFakeBridge.pushFrame(id: "9", data: "x")
        #expect(await waitUntil { received.count >= 1 })
        try? await Task.sleep(nanoseconds: 100_000_000) // a window for the hypothetical duplicate
        #expect(received.count == 1)
        gateway.close()
    }

    // MARK: - watchdog 

    @Test func testWatchdogIgnoresRawHeartbeatButFiresOnSilence() async {
        let clock = ManualReconnectClock()
        let gateway = makeGateway(clock: clock, heartbeatTimeout: 30)
        var script = ReconnectGatewayFakeBridge.Script()
        script.keepEventsStreamOpen = true
        ReconnectGatewayFakeBridge.script = script

        gateway.start()
        #expect(await waitUntil { clock.requestedIntervals.contains(30.0) })
        let getsBeforeHeartbeat = ReconnectGatewayFakeBridge.recordedRequestURLs.count

        // 20s of silence → a "cough behind the door": a comment line without data →
        // no event is born, but onRawData re-arms the watchdog (new deadline = 20+30 = 50)
        clock.advance(by: 20)
        ReconnectGatewayFakeBridge.pushRawText(": heartbeat\n\n")
        #expect(await waitUntil { clock.requestedIntervals.filter { $0 == 30.0 }.count >= 2 })

        // another 20s (40 total): the FIRST watchdog's deadline (30) has long
        // passed, but its ticket number is stale — no reconnect happened
        clock.advance(by: 20)
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(ReconnectGatewayFakeBridge.recordedRequestURLs.count == getsBeforeHeartbeat)
        #expect(!clock.requestedIntervals.contains(2.0))

        // total silence up to the 50 mark — the current watchdog fires → reconnect
        clock.advance(by: 10)
        #expect(await waitUntil { clock.requestedIntervals.contains(2.0) })
        gateway.close()
    }

    // MARK: - shutdown

    @Test func testCloseStopsFurtherReconnects() async {
        let clock = ManualReconnectClock()
        let gateway = makeGateway(clock: clock)
        ReconnectGatewayFakeBridge.failEventsConnection = true

        gateway.start()
        #expect(await waitUntil { clock.requestedIntervals.count == 1 })
        let attempts = ReconnectGatewayFakeBridge.recordedRequestURLs.count

        gateway.close()
        clock.advance(by: 2) // the pause expired, but the session is dead
        try? await Task.sleep(nanoseconds: 100_000_000)
        #expect(ReconnectGatewayFakeBridge.recordedRequestURLs.count == attempts)
    }
}
