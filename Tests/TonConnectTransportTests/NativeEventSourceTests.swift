import Foundation
import Testing
import TonConnectTestSupport
@testable import TonConnectTransport

/// This suite's isolated scenario (fake v3 — per-class state).
private final class TransportFakeBridge: FakeBridgeURLProtocol {}

/// NativeEventSource ↔ FakeBridgeURLProtocol integration (no port).
/// The fake's statics are shared → @Suite(.serialized) (lesson from).
/// The fake is injected via the internal sessionConfiguration seam:
/// URLProtocol.registerClass has no effect on custom sessions (a fact).
@Suite(.serialized) struct NativeEventSourceTests {

    /// A clean fake scenario + a source with the fake injected.
    private func makeSource(
        frames: [(id: String?, data: String)],
        url: String = "https://bridge.test/events",
        lastEventId: String? = nil
    ) -> NativeEventSource {
        var script = FakeBridgeURLProtocol.Script()
        script.sseFrames = frames
        FakeBridgeURLProtocol.script = script
        FakeBridgeURLProtocol.recordedRequestURLs = []

        let source = NativeEventSource(url: url, lastEventId: lastEventId)
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [FakeBridgeURLProtocol.self]
        source.sessionConfiguration = config
        return source
    }

    @Test func testOnMessageDeliversScriptedSSEFrames() async {
        let source = makeSource(frames: [(id: "7", data: "{\"from\":\"wallet\"}")])
        let messages = await withCheckedContinuation { (cont: CheckedContinuation<[(String?, String)], Never>) in
            var received: [(String?, String)] = []
            source.onMessage = { id, data in received.append((id, data)) }
            source.onError = { _ in cont.resume(returning: received) } // the stream ended after the frames
            source.connect()
        }
        source.close()
        #expect(messages.count == 1)
        #expect(messages.first?.0 == "7")
        #expect(messages.first?.1 == "{\"from\":\"wallet\"}")
    }

    @Test func testLastEventIdAppendedToEventsQuery() async {
        let source = makeSource(frames: [], lastEventId: "42")
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            source.onError = { _ in cont.resume() } // an empty scenario → the stream ends immediately
            source.connect()
        }
        source.close()
        let url = FakeBridgeURLProtocol.recordedRequestURLs.first
        #expect(url?.query?.contains("last_event_id=42") == true,
                "last_event_id must leave as a query parameter, got \(String(describing: url))")
    }

    @Test func testStreamCompletionFiresOnErrorNotReconnect() async throws {
        let source = makeSource(frames: [(id: nil, data: "x")])
        let errorCount = await withCheckedContinuation { (cont: CheckedContinuation<Int, Never>) in
            var errors = 0
            source.onError = { _ in
                errors += 1
                cont.resume(returning: errors)
            }
            source.connect()
        }
        // Give a hypothetical self-reconnect time to show itself…
        try? await Task.sleep(nanoseconds: 200_000_000)
        #expect(errorCount == 1, "onError exactly once")
        #expect(source.readyState == .closed, "after a drop — closed, not connecting (no self-reconnect)")
        #expect(FakeBridgeURLProtocol.recordedRequestURLs.count == 1,
                "exactly one GET /events — the wrapper never reconnects on its own")
        source.close()
    }
}
