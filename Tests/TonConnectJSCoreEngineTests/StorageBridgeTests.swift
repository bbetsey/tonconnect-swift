import Foundation
import JavaScriptCore
import Testing
import TonConnectCore
@testable import TonConnectJSCoreEngine

/// StorageBridge round-trip : JS sees the native storage via
/// __nativeStorage*; keys pass verbatim (Don't Hand-Roll — the SDK owns the key names).
struct StorageBridgeTests {

    private func makeBridgedStorage() -> (bridge: JSCoreBridge, storage: InMemoryStorage) {
        let bridge = JSCoreBridge()
        let storage = InMemoryStorage()
        let storageBridge = StorageBridge(storage: storage, bridge: bridge)
        bridge.perform { ctx in storageBridge.install(into: ctx) }
        return (bridge, storage)
    }

    @Test func testJsSetThenGetReturnsStoredValue() async throws {
        let (bridge, storage) = makeBridgedStorage()
        let result = try await bridge.awaitPromise { ctx in
            ctx.evaluateScript(
                "(async function(){ await __nativeStorageSet('k','v'); return await __nativeStorageGet('k'); })()"
            )!
        }
        #expect(result == "v")
        #expect(try await storage.get("k") == "v", "the value actually landed in the Swift storage")
    }

    @Test func testJsGetMissingKeyReturnsNull() async throws {
        let (bridge, _) = makeBridgedStorage()
        let result = try await bridge.awaitPromise { ctx in
            ctx.evaluateScript(
                "(async function(){ var v = await __nativeStorageGet('absent'); return v === null ? 'was-null' : String(v); })()"
            )!
        }
        #expect(result == "was-null", "a Swift nil must become a JS null (not undefined and not 'nil')")
    }

    @Test func testJsRemoveDeletesKey() async throws {
        let (bridge, storage) = makeBridgedStorage()
        let result = try await bridge.awaitPromise { ctx in
            ctx.evaluateScript(
                "(async function(){ await __nativeStorageSet('k','v'); await __nativeStorageRemove('k'); var v = await __nativeStorageGet('k'); return v === null ? 'removed' : String(v); })()"
            )!
        }
        #expect(result == "removed")
        #expect(try await storage.get("k") == nil)
    }

    @Test func testKeyPassesThroughVerbatim() async throws {
        let (bridge, storage) = makeBridgedStorage()
        _ = try await bridge.awaitPromise { ctx in
            ctx.evaluateScript(
                "(async function(){ await __nativeStorageSet('ton-connect-storage_bridge-connection','session-blob'); return 'ok'; })()"
            )!
        }
        let stored = try await storage.get("ton-connect-storage_bridge-connection")
        #expect(stored != nil, "the SDK's key passed unwrapped — SessionKey is not applied")
    }
}
