import Foundation
import JavaScriptCore
import Testing
@testable import TonConnectJSCoreEngine

/// The phase's success criterion #4 (the isolated part): a matrix of hand-written
/// snippets . Every path resumes the continuation exactly once .
/// A failure HERE = the bridge itself; a failure in SDKSmokeTests = the bundle
/// integration (attribution per).
struct PromiseBridgeTests {

    @Test func testResolvedPromiseReturnsValue() async throws {
        let bridge = JSCoreBridge()
        let result = try await bridge.awaitPromise { ctx in ctx.evaluateScript("Promise.resolve('ok')")! }
        #expect(result == "ok")
    }

    @Test func testRejectedPromiseThrowsJSException() async throws {
        let bridge = JSCoreBridge()
        do {
            _ = try await bridge.awaitPromise { ctx in ctx.evaluateScript("Promise.reject(new Error('bad'))")! }
            Issue.record("Expected JSBridgeError.jsException, but awaitPromise returned without an error")
        } catch let error as JSBridgeError {
            guard case .jsException(let message) = error else {
                Issue.record("Expected .jsException, got \(error)")
                return
            }
            #expect(message.contains("bad"))
        }
    }

    /// A throw inside the promise executor == a rejected promise (JS semantics) —
    /// the bridge must carry it to the same typed error.
    @Test func testSynchronousThrowInsidePromiseExecutorRejects() async throws {
        let bridge = JSCoreBridge()
        do {
            _ = try await bridge.awaitPromise { ctx in
                ctx.evaluateScript("new Promise(function(){ throw new Error('boom'); })")!
            }
            Issue.record("Expected a reject: a throw inside the executor becomes a rejected promise")
        } catch let error as JSBridgeError {
            guard case .jsException(let message) = error else {
                Issue.record("Expected .jsException, got \(error)")
                return
            }
            #expect(message.contains("boom"))
        }
    }

    /// Integration: TimerPolyfill (firing on the JS queue) + the continuation.
    /// Proves a deferred resolve neither hangs nor touches JSValue from a foreign thread.
    @Test func testTimerDelayedPromiseStillResolves() async throws {
        let bridge = JSCoreBridge()
        let result = try await bridge.awaitPromise { ctx in
            ctx.evaluateScript("new Promise(function(res){ setTimeout(function(){ res('late'); }, 20); })")!
        }
        #expect(result == "late")
    }

    /// A non-promise — an instant typed error, not a silent hang.
    @Test func testNonPromiseValueThrowsNotAPromise() async throws {
        let bridge = JSCoreBridge()
        do {
            _ = try await bridge.awaitPromise { ctx in ctx.evaluateScript("42")! }
            Issue.record("Expected JSBridgeError.notAPromise")
        } catch let error as JSBridgeError {
            #expect(error == .notAPromise)
        }
    }
}
