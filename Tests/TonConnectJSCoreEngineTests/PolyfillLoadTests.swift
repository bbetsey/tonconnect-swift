import Foundation
import JavaScriptCore
import Testing
@testable import TonConnectJSCoreEngine

/// The phase's success criterion #1: the vendored @tonconnect/sdk bundle loads
/// into a real JSContext without a ReferenceError given the full polyfill set.
/// The A3 gate: runs both under swift test (macOS) and xcodebuild test (iOS Simulator).
struct PolyfillLoadTests {

    // MARK: - helpers

    /// A mini version of what JSCoreBridge does at initialization:
    /// a context + the polyfills in the fixed order (console → timers → atob/btoa → crypto).
    private func makeContextWithPolyfills(includeBase64: Bool = true) -> (JSContext, () -> JSValue?) {
        let queue = DispatchQueue(label: "test.jscore")
        let context = JSContext()!
        var captured: JSValue?
        context.exceptionHandler = { _, exception in captured = exception }
        ConsolePolyfill().apply(to: context)
        TimerPolyfill(jsQueue: queue).apply(to: context)
        if includeBase64 { Base64Polyfill().apply(to: context) }
        SecureRandomPolyfill().apply(to: context)
        return (context, { captured })
    }

    private func loadBundle(into context: JSContext) throws {
        let url = Bundle.module.url(forResource: "tonconnect-sdk.bundle", withExtension: "js")!
        context.evaluateScript(try String(contentsOf: url, encoding: .utf8))
    }

    // MARK: - happy path

    @Test func testBundleLoadsWithoutReferenceError() throws {
        let (context, captured) = makeContextWithPolyfills()
        try loadBundle(into: context)
        #expect(captured() == nil, "Bundle load threw: \(captured()?.toString() ?? "?")")
    }

    @Test func testAllPolyfillGlobalsAreDefinedAfterApply() {
        let (context, _) = makeContextWithPolyfills()
        for name in ["console", "setTimeout", "setInterval", "clearTimeout", "clearInterval", "atob", "btoa"] {
            let value = context.objectForKeyedSubscript(name)
            #expect(value?.isUndefined == false, "\(name) must be defined after the polyfills are applied")
        }
        let getRandomValues = context.evaluateScript("globalThis.crypto && globalThis.crypto.getRandomValues")
        #expect(getRandomValues?.isUndefined == false, "crypto.getRandomValues must be defined")
    }

    // MARK: - error paths

    /// Negative test: atob/btoa are load-bearing. If Base64Polyfill is
    /// removed on the assumption "crypto is there, so we're fine", the bundle load
    /// MUST fail with a ReferenceError about Buffer (tweetnacl-util at module top level).
    @Test func testBundleWithoutBase64PolyfillThrowsBufferReferenceError() throws {
        let (context, captured) = makeContextWithPolyfills(includeBase64: false)
        try loadBundle(into: context)
        #expect(captured() != nil, "Expected an exception when loading without atob/btoa")
        #expect(
            captured()?.toString().contains("Buffer") == true,
            "Expected a ReferenceError about Buffer without atob/btoa, got: \(captured()?.toString() ?? "nil")"
        )
    }
}
