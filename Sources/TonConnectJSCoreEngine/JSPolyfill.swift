import JavaScriptCore

/// The shared polyfill contract: applies a JS shim to the context BEFORE evaluateScript(bundle).
/// The application order (console → timers → atob/btoa → crypto) is fixed.
public protocol JSPolyfill {
    func apply(to context: JSContext)
}
