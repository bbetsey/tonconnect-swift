import Foundation
import JavaScriptCore
import Testing
@testable import TonConnectJSCoreEngine

/// The phase's success criterion #3: one JSContext/JSVirtualMachine on one
/// serial queue. A stress test: parallel bridge calls from
/// different threads cause no crash/corruption, because perform marshals every
/// call onto the serial queue (cross-thread JSValue excluded by construction).
struct ThreadSafetyTests {

    @Test func testConcurrentBridgeCallsFromManyThreadsDoNotCrash() {
        let bridge = JSCoreBridge()
        let lock = NSLock()
        var results: [Int32] = []
        DispatchQueue.concurrentPerform(iterations: 200) { _ in
            let value = bridge.perform { ctx in ctx.evaluateScript("1 + 1").toInt32() }
            lock.lock()
            results.append(value)
            lock.unlock()
        }
        #expect(results.count == 200)
        #expect(results.allSatisfy { $0 == 2 })
    }

    /// If every call created a new context, the counter would never reach 100.
    /// The shared global proves a single shared JSContext (and one JSVirtualMachine).
    @Test func testAllCallsShareOneContextObservedViaGlobalCounter() {
        let bridge = JSCoreBridge()
        bridge.perform { ctx in _ = ctx.evaluateScript("globalThis.__marker = 0") }
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            bridge.perform { ctx in _ = ctx.evaluateScript("globalThis.__marker = (globalThis.__marker || 0) + 1") }
        }
        let final = bridge.perform { ctx in ctx.evaluateScript("globalThis.__marker").toInt32() }
        #expect(final == 100)
    }

    /// The dispatchPrecondition guard cannot be unit-tested without killing the
    /// process — its presence in JSCoreBridge is checked at the code level; this is a
    /// smoke that the seam works.
    @Test func testBridgeExposesQueueDisciplineSeam() {
        let bridge = JSCoreBridge()
        let result = bridge.perform { ctx in ctx.evaluateScript("2 * 3").toInt32() }
        #expect(result == 6)
    }
}
