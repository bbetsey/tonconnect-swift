import Foundation
import JavaScriptCore
import Testing
@testable import TonConnectJSCoreEngine

/// Load tests of the network polyfills : after loadBundle the SDK's
/// methods no longer hit a ReferenceError and can see fetch/EventSource.
struct NetworkPolyfillLoadTests {

    @Test func testAbortControllerFetchEventSourceGlobalsPresent() throws {
        let bridge = JSCoreBridge()
        try bridge.loadBundle()
        let present = bridge.perform { ctx in
            ctx.evaluateScript(
                "typeof AbortController === 'function' && typeof fetch === 'function' && typeof EventSource === 'function'"
            )!.toBool()
        }
        #expect(present == true)
        #expect(bridge.lastException == nil)
    }

    @Test func testEventSourceStaticsMatchSpec() throws {
        let bridge = JSCoreBridge()
        try bridge.loadBundle()
        let staticsMatch = bridge.perform { ctx in
            ctx.evaluateScript(
                "EventSource.CONNECTING === 0 && EventSource.OPEN === 1 && EventSource.CLOSED === 2"
            )!.toBool()
        }
        #expect(staticsMatch == true, "the SDK compares readyState with the statics — the spec's values")
    }

    @Test func testConnectDoesNotThrowAbortControllerReferenceError() throws {
        let bridge = JSCoreBridge()
        try bridge.loadBundle()
        // The SDK's createAbortController() path — the first line of every method.
        let error = bridge.perform { ctx in
            ctx.evaluateScript("""
                (function(){ try { new AbortController().abort(); return ''; } catch(e){ return String(e); } })()
                """)!.toString() ?? "?"
        }
        #expect(!error.contains("AbortController is not defined"), "AbortController must be installed before the SDK loads, got: \(error)")
        #expect(error.isEmpty, "the abort() happy path throws nothing, got: \(error)")
        #expect(bridge.lastException == nil)
    }
}
