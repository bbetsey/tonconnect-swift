import Foundation
import JavaScriptCore
import Testing
import TonConnectCore
@testable import TonConnectJSCoreEngine

private struct NoopOpener: WalletOpener { func open(_ url: URL) {} }

/// Absence of leaks is verified by a deinit test on every run, no manual
/// Instruments. If this test goes red — look for a cycle in the exceptionHandler
/// ([weak self]), a JSManagedValue retention in TimerPolyfill ,
/// or a self capture in a continuation .
struct DeinitLeakTests {

    @Test func testBridgeIsDeallocatedAfterLastStrongReferenceReleased() async throws {
        weak var weakBridge: JSCoreBridge?
        do {
            let bridge = JSCoreBridge()
            try bridge.loadBundle()
            _ = try await bridge.awaitPromise { ctx in ctx.evaluateScript("Promise.resolve(1)")! }
            weakBridge = bridge
        } // the last strong reference leaves the scope
        // let the concurrency runtime catch up with the release
        try await Task.sleep(nanoseconds: 50_000_000)
        #expect(weakBridge == nil, "JSCoreBridge did not deallocate — a retain cycle (exceptionHandler/JSManagedValue/continuation?)")
    }

    /// The whole engine, storage bridge installed: the blocks in the context
    /// used to hold the bridge strongly, and the bridge holds the context — so
    /// every engine ever created lived on with its SSE streams and timers.
    @Test func testEngineWithStorageBridgeIsDeallocatedAfterLastStrongReferenceReleased() async throws {
        weak var weakBridge: JSCoreBridge?
        do {
            let bridge = JSCoreBridge()
            let engine = try JSCoreEngine(manifestUrl: "https://example.com/m.json",
                                          storage: InMemoryStorage(),
                                          opener: NoopOpener(),
                                          bridge: bridge)
            weakBridge = engine.bridge
        }
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(weakBridge == nil, "JSCoreBridge did not deallocate with its engine — the storage bridge cycle is back")
    }
}
