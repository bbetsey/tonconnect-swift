import Foundation
import JavaScriptCore
import TonConnectCore

/// The IStorage (JS) ↔ TonConnectStorage (Swift) bridge. PromiseAdapter's reverse
/// direction: JS calls __nativeStorage*, receives a JS Promise whose body runs
/// async Swift and resolves. Keys pass VERBATIM — the
/// SDK owns the names (ton-connect-storage_*) and session assembly; SessionKey.make
/// is NOT applied. In production the engine injects KeychainStorage
/// (kSecAttrAccessibleAfterFirstUnlock) — the session lands in the Keychain.
public final class StorageBridge {
    private let storage: any TonConnectStorage
    private unowned let bridge: JSCoreBridge // the bridge outlives us — unowned, no cycle

    public init(storage: any TonConnectStorage, bridge: JSCoreBridge) {
        self.storage = storage
        self.bridge = bridge
    }

    /// Installs __nativeStorageGet/Set/Remove. Called by the engine
    /// BEFORE __tcCreateEngine (the glue expects them to exist). Call on the JS
    /// queue (perform). The blocks do NOT capture self — only storage and bridge
    /// locals; StorageBridge may die after install, the functions keep working.
    public func install(into context: JSContext) {
        let storage = self.storage
        let bridge = self.bridge

        let get: @convention(block) (String) -> JSValue = { key in
            guard let ctx = JSContext.current() else { fatalError("__nativeStorageGet outside JSContext") }
            return Self.makePromise(in: ctx, bridge: bridge) { resolve, reject in
                Task {
                    do { resolve(try await storage.get(key)) } // the key VERBATIM
                    catch { reject(String(describing: error)) }
                }
            }
        }
        let set: @convention(block) (String, String) -> JSValue = { key, value in
            guard let ctx = JSContext.current() else { fatalError("__nativeStorageSet outside JSContext") }
            return Self.makePromise(in: ctx, bridge: bridge) { resolve, reject in
                Task {
                    do { try await storage.set(value, forKey: key); resolve(nil) }
                    catch { reject(String(describing: error)) }
                }
            }
        }
        let remove: @convention(block) (String) -> JSValue = { key in
            guard let ctx = JSContext.current() else { fatalError("__nativeStorageRemove outside JSContext") }
            return Self.makePromise(in: ctx, bridge: bridge) { resolve, reject in
                Task {
                    do { try await storage.remove(key); resolve(nil) }
                    catch { reject(String(describing: error)) }
                }
            }
        }
        context.setObject(get, forKeyedSubscript: "__nativeStorageGet" as NSString)
        context.setObject(set, forKeyedSubscript: "__nativeStorageSet" as NSString)
        context.setObject(remove, forKeyedSubscript: "__nativeStorageRemove" as NSString)
    }

    /// Builds a JS Promise; the body receives Swift resolvers that HOP onto the JS
    /// queue (bridge.enqueue) and touch JSValue only there. The do/catch
    /// branches are mutually exclusive → resolve exactly once. nil → JS null (inside the queue).
    private static func makePromise(
        in context: JSContext,
        bridge: JSCoreBridge,
        _ body: @escaping (_ resolve: @escaping (String?) -> Void, _ reject: @escaping (String) -> Void) -> Void
    ) -> JSValue {
        var resolveFn: JSValue?
        var rejectFn: JSValue?
        let promise = JSValue(newPromiseIn: context) { res, rej in
            resolveFn = res
            rejectFn = rej
        }!
        // The resolvers are held as plain JSValues, on purpose. They used to be
        // JSManagedValue(value:andOwner: context), on the belief that GC would not
        // collect them while the Swift read was in flight. JavaScriptCore's own
        // header says otherwise: a managed value is "conditionally retained" — kept
        // only while reachable from the JS graph or from an owner registered via
        // addManagedReference — and nothing here registered one. Nothing in JS
        // references a promise's own resolve/reject functions, so under a timely
        // collection they were freed, `resolve?.value` became nil, and the promise
        // never settled: the SDK's restoreConnection hung forever on the iOS
        // simulator, where an allocation-heavy call (a NaCl keypair) right before
        // the read was enough to trigger the collector (SimTraceProbe, 2026-09-07).
        // TimerPolyfill learned the same lesson earlier. A strong JSValue is safe
        // here: these closures live in a Swift Task and are never handed to JS, so
        // there is no JS-side cycle for the header's warning to apply to.
        let resolve = resolveFn
        let reject = rejectFn
        body(
            { value in
                bridge.enqueue {
                    if let value {
                        resolve?.call(withArguments: [value])
                    } else {
                        resolve?.call(withArguments: [NSNull()]) // nil → JS null
                    }
                }
            },
            { message in
                bridge.enqueue {
                    guard let ctx = reject?.context,
                          let error = JSValue(newErrorFromMessage: message, in: ctx) else { return }
                    reject?.call(withArguments: [error])
                }
            }
        )
        return promise
    }
}
