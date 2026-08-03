import Foundation
import JavaScriptCore
import Testing
@testable import TonConnectJSCoreEngine

/// The phase's success criterion #2: the exceptionHandler is installed and
/// catches synchronous throws into lastException. Documented here:
/// a bare Promise.reject NEVER reaches the exceptionHandler — reject delivery is
/// built via the explicit .then(resolve:, reject:) in PromiseAdapter .
struct ExceptionHandlerTests {

    // MARK: - what the exceptionHandler DOES catch

    @Test func testSynchronousThrowDuringEvaluateScriptIsCapturedInLastException() {
        let bridge = JSCoreBridge()
        bridge.perform { ctx in _ = ctx.evaluateScript("throw new Error('boom')") }
        #expect(bridge.lastException?.contains("boom") == true)
    }

    @Test func testSyntaxErrorInEvaluatedScriptIsCapturedInLastException() {
        let bridge = JSCoreBridge()
        bridge.perform { ctx in _ = ctx.evaluateScript("this is not valid js @@@") }
        #expect(bridge.lastException != nil)
    }

    // MARK: - what the exceptionHandler does NOT catch (a documenting test)

    /// NOT a bug, but JavaScriptCore's documented behavior: a rejection is the
    /// Promise object's state, not a throw into host code. If this test ever
    /// fails — JavaScriptCore's behaviour changed and the adapter needs revisiting.
    @Test func testUnhandledPromiseRejectionDoesNotReachExceptionHandler() {
        let bridge = JSCoreBridge()
        bridge.perform { ctx in _ = ctx.evaluateScript("Promise.reject(new Error('rejected'))") }
        #expect(bridge.lastException == nil,
                "A bare Promise.reject must not reach the exceptionHandler — a reject is caught only by an explicit .then")
    }

    // MARK: - criterion #2, literally

    @Test func testExceptionHandlerIsInstalledOnBridgeContext() {
        let bridge = JSCoreBridge()
        bridge.perform { ctx in
            #expect(ctx.exceptionHandler != nil)
        }
    }
}
