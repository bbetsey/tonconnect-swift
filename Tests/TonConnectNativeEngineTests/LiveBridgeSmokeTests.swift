import Foundation
import Testing
import TonConnectCore
import TonConnectTransport
@testable import TonConnectNativeEngine

private final class OneShotFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false
    func set() { lock.lock(); value = true; lock.unlock() }
    var isSet: Bool { lock.lock(); defer { lock.unlock() }; return value }
}

/// Raw-byte timestamps — the heartbeat-interval empirics (A1).
private final class StampBox: @unchecked Sendable {
    private let lock = NSLock()
    private var stamps: [TimeInterval] = []
    func mark() { lock.lock(); stamps.append(ProcessInfo.processInfo.systemUptime); lock.unlock() }
    func intervals() -> [Double] {
        lock.lock(); defer { lock.unlock() }
        guard stamps.count > 1 else { return [] }
        return zip(stamps.dropFirst(), stamps).map { (($0 - $1) * 10).rounded() / 10 }
    }
}

/// An env-gated smoke against the REAL bridge, WITHOUT a wallet.
/// A manual run before merging:
///   TC_LIVE_BRIDGE_SMOKE=1 swift test --filter LiveBridgeSmokeTests
/// The goal — the real server's surprises: SSE frame format, POST codes, the
/// actual heartbeat interval — the number behind the watchdog threshold, which
/// neither the spec nor the JS SDK documents.
@Suite struct LiveBridgeSmokeTests {

    private static let bridgeUrl = "https://bridge.tonapi.io/bridge"

    private func waitUntil(_ condition: @escaping @Sendable () -> Bool,
                           timeoutNanoseconds: UInt64) async -> Bool {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        return condition()
    }

    /// A POST with a 10s ceiling: return the HTTP code or nil (the network did not answer).
    private func postStatus(url: String, body: Data,
                            timeoutNanoseconds: UInt64 = 10_000_000_000) async -> Int? {
        await withTaskGroup(of: Int?.self) { group in
            group.addTask {
                await withCheckedContinuation { (continuation: CheckedContinuation<Int?, Never>) in
                    NativeFetch().post(url: url, body: body) { result in
                        switch result {
                        case .success(let response): continuation.resume(returning: response.status)
                        case .failure: continuation.resume(returning: nil)
                        }
                    }
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }

    @Test func testLiveBridgeAcceptsSSEConnectAndMessagePost() async throws {
        guard ProcessInfo.processInfo.environment["TC_LIVE_BRIDGE_SMOKE"] == "1" else { return }

        let crypto = SessionCrypto()
        let clientId = crypto.sessionId

        // --- SSE: a real connect, a fresh client_id, await open/bytes (10s ceiling) ---
        let streamAlive = OneShotFlag()
        let stamps = StampBox()
        let source = NativeEventSource(
            url: RPCEnvelope.eventsURL(bridgeUrl: Self.bridgeUrl, clientId: clientId, lastEventId: nil),
            lastEventId: nil)
        source.onOpen = { streamAlive.set() }
        source.onRawData = { _ in streamAlive.set(); stamps.mark() }
        source.connect()
        let sawStream = await waitUntil({ streamAlive.isSet }, timeoutNanoseconds: 10_000_000_000)
        #expect(sawStream, "live bridge did not open SSE stream within 10s")

        // The heartbeat empirics (A1): listen to raw bytes for ~20s, print the intervals.
        try? await Task.sleep(nanoseconds: 20_000_000_000)
        print("[smoke] raw-data intervals over 20s: \(stamps.intervals()) s")
        source.close()

        // --- POST /message: the transport answers with a CODE (no wallet — no flow expected) ---
        let url = RPCEnvelope.messageURL(bridgeUrl: Self.bridgeUrl,
                                         myClientId: clientId,
                                         to: String(repeating: "00", count: 32),
                                         ttl: 300, topic: nil)
        let status = await postStatus(url: url, body: Data("aGVsbG8=".utf8))
        #expect(status != nil, "live bridge POST /message did not answer within 10s")
        print("[smoke] POST /message → HTTP \(status ?? -1)")
    }
}
