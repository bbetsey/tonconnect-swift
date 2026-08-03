import Foundation
import TonConnectTransport
import JavaScriptCore
import os

/// Owner of exactly one JSContext (and therefore one JSVirtualMachine) on a
/// private serial queue — the only protection against cross-thread JSValue
/// (memory corruption). Every touch of JS goes through enqueue/perform.
///
/// The bridge never hangs silently — every reject is carried through as an error —
/// but it does not impose a waiting policy either: that belongs to the engine above
/// it. Leak checking lives in DeinitLeakTests.
public final class JSCoreBridge {

    internal let context: JSContext
    private let queue = DispatchQueue(label: "tonconnect-swift.jscore", qos: .userInitiated)
    private let logger = Logger(subsystem: "tonconnect-swift", category: "JSBridge")
    private let exceptionLogger = Logger(subsystem: "tonconnect-swift", category: "JSException")

    /// The bridge's "X-ray" — when enabled, every pass through
    /// enqueue/perform is logged to an os.Logger at .debug. Off by default.
    public var traceEnabled: Bool = false

    /// The last uncaught JS exception — as a String, not a JSValue
    /// (a JSValue never crosses the queue boundary).
    private var _lastException: String?
    public var lastException: String? {
        queue.sync { _lastException }
    }

    public init(transportConfiguration: URLSessionConfiguration = .ephemeral) {
        // JSContext() creates its own JSVirtualMachine —
        // exactly one VM per bridge.
        guard let ctx = JSContext() else { fatalError("JSContext unavailable") }
        self.context = ctx

        queue.sync {
            // [weak self] — otherwise the context would hold the bridge, the
            // bridge holds the context, and the deinit tests would
            // never observe deallocation.
            ctx.exceptionHandler = { [weak self] _, exception in
                self?.recordException(exception)
            }
            // Fixed order: environment (self/performance) → console →
            // timers → atob/btoa → crypto → AbortController → fetch → EventSource.
            EnvironmentPolyfill().apply(to: ctx)
            ConsolePolyfill().apply(to: ctx)
            TimerPolyfill(jsQueue: queue).apply(to: ctx) // the same queue
            Base64Polyfill().apply(to: ctx)
            SecureRandomPolyfill().apply(to: ctx)
            AbortControllerPolyfill().apply(to: ctx)
            FetchPolyfill(bridge: self,
                          nativeFetch: NativeFetch(session: URLSession(configuration: transportConfiguration))).apply(to: ctx)
            EventSourcePolyfill(bridge: self,
                                sessionConfiguration: transportConfiguration).apply(to: ctx)
        }
    }

    /// Loads the vendored @tonconnect/sdk bundle into the context.
    public func loadBundle() throws {
        dispatchPrecondition(condition: .notOnQueue(queue)) // the public API is called from outside
        guard let url = Bundle.module.url(forResource: "tonconnect-sdk.bundle", withExtension: "js") else {
            throw JSBridgeError.bundleLoadFailed("resource not found")
        }
        let source: String
        do {
            source = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw JSBridgeError.bundleLoadFailed("cannot read bundle: \(error)")
        }
        let exceptionAfterLoad: String? = queue.sync {
            _lastException = nil
            trace("loadBundle: evaluating \(source.count) chars")
            context.evaluateScript(source)
            return _lastException
        }
        if let message = exceptionAfterLoad {
            throw JSBridgeError.bundleLoadFailed(message)
        }
    }

    // MARK: - Seam for PromiseAdapter

    /// Executes work asynchronously on the JS queue. The only legal way to "file
    /// a request" to touch a JSValue from a foreign thread.
    internal func enqueue(_ work: @escaping () -> Void) {
        queue.async {
            dispatchPrecondition(condition: .onQueue(self.queue))
            self.trace("enqueue: executing queued work")
            work()
        }
    }

    /// Executes body synchronously on the JS queue and returns the result.
    /// IMPORTANT: the body's result must not be a JSValue leaving the queue —
    /// convert to native types inside the body.
    internal func perform<T>(_ body: (JSContext) -> T) -> T {
        dispatchPrecondition(condition: .notOnQueue(queue)) // reentrant-deadlock guard
        return queue.sync {
            dispatchPrecondition(condition: .onQueue(queue))
            trace("perform: executing on JS queue")
            return body(context)
        }
    }

    // MARK: - Private

    /// Called from the exceptionHandler — always on the queue (every evaluateScript goes through it).
    /// Log + record only, NO fatal — the SDK also throws recoverable exceptions.
    private func recordException(_ exception: JSValue?) {
        let message = exception?.toString() ?? "unknown"
        _lastException = message
        exceptionLogger.error("JS uncaught exception: \(message, privacy: .public)")
    }

    private func trace(_ message: @autoclosure () -> String) {
        guard traceEnabled else { return }
        let text = message()
        logger.debug("\(text, privacy: .public)")
    }
}
