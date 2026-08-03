import Foundation

/// The reconnect layer's injectable clock: cadence (2s/5s) and watchdog-threshold
/// tests run instantly on virtual time, no real waiting (determinism).
/// Injection is a ReconnectGateway init parameter (NOT a global swap: the gateway
/// is created explicitly by the engine/test, so a constructor suffices; the
/// global withSource seam, as in RandomBytesBridge, was only needed because of a C symbol).
protocol ReconnectClock: Sendable {
    func sleep(seconds: Double) async throws
}

/// Production: a real Task.sleep.
struct SystemReconnectClock: ReconnectClock {
    func sleep(seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}

/// Test double (next to Sources, internal — after the FixedBytesSource model).
/// VIRTUAL time: sleep does not actually wait — it registers a deadline and hangs
/// until advance(by:), which "moves the hands" and wakes every sleep whose
/// deadline has passed. Instant resolution would not do: the watchdog sleeps
/// through this same clock and would fire immediately — an endless reconnect
/// loop right inside the test.
/// requestedIntervals accumulates the requested pauses to verify the [2, 5, 5] cadence.
final class ManualReconnectClock: ReconnectClock, @unchecked Sendable {
    private let lock = NSLock()
    private var now: Double = 0
    private var pending: [(deadline: Double, continuation: CheckedContinuation<Void, Error>)] = []
    private var intervals: [Double] = []

    var requestedIntervals: [Double] {
        lock.lock(); defer { lock.unlock() }; return intervals
    }

    func sleep(seconds: Double) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            lock.lock()
            intervals.append(seconds)
            pending.append((now + seconds, continuation))
            lock.unlock()
        }
    }

    /// Move the hands by hand: everything whose deadline has arrived wakes up.
    func advance(by seconds: Double) {
        lock.lock()
        now += seconds
        let due = pending.filter { $0.deadline <= now }
        pending.removeAll { $0.deadline <= now }
        lock.unlock()
        for entry in due { entry.continuation.resume() }
    }
}
