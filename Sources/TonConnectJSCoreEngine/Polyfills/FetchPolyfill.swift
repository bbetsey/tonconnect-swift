import Foundation
import JavaScriptCore
import TonConnectTransport

/// globalThis.fetch on top of NativeFetch, to the SDK's surface:
/// fetch(url, {method, body, signal}) → Promise<{ok, status}>.
/// The URLSession completion arrives on an arbitrary thread → hop onto the JS
/// queue via bridge.enqueue BEFORE touching any JSValue.
/// The signal wiring lives in the JS shim: abort → handle.cancel() →
/// NativeFetchTask.cancel() — the foundation of Task cancellation across the
/// JavaScript boundary.
public final class FetchPolyfill: JSPolyfill {
    // weak: otherwise a cycle bridge→context→block→polyfill→bridge (would break DeinitLeakTests).
    private weak var bridge: JSCoreBridge?
    private let nativeFetch: NativeFetch

    public init(bridge: JSCoreBridge, nativeFetch: NativeFetch = NativeFetch()) {
        self.bridge = bridge
        self.nativeFetch = nativeFetch
    }

    public func apply(to context: JSContext) {
        // The block captures self strongly — the polyfill lives exactly as long as
        // the JSContext (the TimerPolyfill idiom); the weak bridge breaks the cycle outward.
        let start: @convention(block) (JSValue, JSValue) -> JSValue = { urlValue, bodyValue in
            guard let context = JSContext.current() else {
                fatalError("__nativeFetchStart called outside a JSContext")
            }
            guard let bridge = self.bridge else {
                // Unreachable while the context is alive: the bridge owns the JSContext.
                return JSValue(undefinedIn: context)
            }
            let url = urlValue.toString() ?? ""
            let body = (bodyValue.isNull || bodyValue.isUndefined) ? "" : (bodyValue.toString() ?? "")

            var resolveFn: JSValue?
            var rejectFn: JSValue?
            let promise = JSValue(newPromiseIn: context) { resolve, reject in
                resolveFn = resolve
                rejectFn = reject
            }!
            // The executor above ran synchronously — both functions are already in place.
            let resolve = resolveFn!
            let reject = rejectFn!

            // resolve/reject are captured STRONGLY: a JS promise does not hold its
            // own resolve functions — while the network call is in flight, this
            // closure is their only root. JSManagedValue(owner: context) was
            // effectively a weak reference: GC ate the functions under pressure, the
            // promise hung forever and dropped the continuation in awaitPromise
            // (proven by ManagedValueLifetimeTests).
            // The context is retained only until completion — URLSession always calls it.
            let task = self.nativeFetch.post(url: url, body: Data(body.utf8)) { result in
                // A URLSession thread! Hop onto the JS queue before touching JSValue.
                bridge.enqueue {
                    switch result {
                    case .success(let response):
                        guard let ctx = resolve.context,
                              let object = JSValue(newObjectIn: ctx) else { return }
                        object.setObject(response.ok, forKeyedSubscript: "ok" as NSString)
                        object.setObject(response.status, forKeyedSubscript: "status" as NSString)
                        resolve.call(withArguments: [object])
                    case .failure(let error):
                        guard let ctx = reject.context,
                              let jsError = JSValue(newErrorFromMessage: "fetch failed: \(error.localizedDescription)", in: ctx)
                        else { return }
                        reject.call(withArguments: [jsError])
                    }
                }
            }
            let cancel: @convention(block) () -> Void = { task.cancel() }
            let handle = JSValue(newObjectIn: context)!
            handle.setObject(promise, forKeyedSubscript: "promise" as NSString)
            handle.setObject(cancel, forKeyedSubscript: "cancel" as NSString)
            return handle
        }
        context.setObject(start, forKeyedSubscript: "__nativeFetchStart" as NSString)
        context.evaluateScript("""
            globalThis.fetch = function(url, options) {
                options = options || {};
                var handle = __nativeFetchStart(String(url), options.body === undefined ? null : options.body);
                if (options.signal) {
                    if (options.signal.aborted) { handle.cancel(); }
                    else { options.signal.addEventListener('abort', function(){ handle.cancel(); }); }
                }
                return handle.promise;
            };
            """)
    }
}
