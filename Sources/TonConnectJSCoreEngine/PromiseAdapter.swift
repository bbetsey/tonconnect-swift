import Foundation
import JavaScriptCore
import os

private let promiseLogger = Logger(subsystem: "tonconnect-swift", category: "JSBridge")

/// The continuation lives in a box, the .then blocks
/// hold the box. If GC collects a dangling promise together with its reactions
/// (observed on device: a universal QR connect with dead bridges —
/// weak JSManagedValues in the polyfills dropped the chain), the box dies without
/// a resume — and deinit resolves the continuation with a typed error instead of
/// "SWIFT TASK CONTINUATION MISUSE".
final class ContinuationBox {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<String, Error>?

    init(_ continuation: CheckedContinuation<String, Error>) {
        self.continuation = continuation
    }

    /// Exactly one winner (resolved / rejected / deinit) takes the continuation.
    func take() -> CheckedContinuation<String, Error>? {
        lock.lock()
        defer { lock.unlock() }
        let taken = continuation
        continuation = nil
        return taken
    }

    deinit {
        // JavaScriptCore's GC frees the blocks from its own thread — hence the
        // lock above rather than an assumption about the JS queue.
        take()?.resume(throwing: JSBridgeError.promiseCollected)
    }
}

/// JS Promise → Swift async. This file owns the no-silent-hang guarantee:
/// every reject/throw is carried through to a JSBridgeError (an error, not an
/// eternal hang), and the continuation resumes exactly once — including the case
/// where GC destroys a dangling promise (ContinuationBox). A waiting policy is
/// not its job: connect() legitimately waits for the user's wallet
/// actions for as long as it takes.
extension JSCoreBridge {

    /// Builds the promise via makePromise (on the JS queue), attaches
    /// .then(resolve, reject), and returns the result as a String. Bridged via an
    /// explicit .then, NOT the exceptionHandler (a rejection is object
    /// state — the exceptionHandler never sees it).
    func awaitPromise(_ makePromise: @escaping (JSContext) -> JSValue) async throws -> String {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            self.enqueue { // on the JS queue (dispatchPrecondition inside enqueue)
                let ctx = self.context
                let promise = makePromise(ctx)

                // Not a Promise → an immediate typed error, not a silent hang.
                guard let promiseCtor = ctx.objectForKeyedSubscript("Promise"),
                      promise.isInstance(of: promiseCtor) else {
                    continuation.resume(throwing: JSBridgeError.notAPromise)
                    return
                }

                // The four paths (resolved / rejected / notAPromise / GC-collected)
                // are mutually exclusive — take() hands the continuation to exactly one.
                // JSValue → String INSIDE the callback on the JS queue, before resume.
                //
                // The callbacks must NOT capture self — the promise's JS heap
                // holds them until JSC garbage collection, and capturing self forms a
                // cycle bridge → context → promise reactions → block → bridge.
                // The flag is copied into a local Bool.
                let box = ContinuationBox(continuation)
                let traceEnabled = self.traceEnabled
                let onResolved: @convention(block) (JSValue) -> Void = { value in
                    if traceEnabled { promiseLogger.debug("awaitPromise: resolved") }
                    box.take()?.resume(returning: value.isUndefined ? "undefined" : (value.toString() ?? ""))
                }
                let onRejected: @convention(block) (JSValue) -> Void = { error in
                    if traceEnabled { promiseLogger.debug("awaitPromise: rejected") }
                    box.take()?.resume(throwing: JSBridgeError.jsException(message: error.toString() ?? "unknown"))
                }
                promise.invokeMethod("then", withArguments: [
                    unsafeBitCast(onResolved, to: JSValue.self),
                    unsafeBitCast(onRejected, to: JSValue.self)
                ])
            }
        }
    }
}
