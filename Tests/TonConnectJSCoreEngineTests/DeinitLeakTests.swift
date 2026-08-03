import Foundation
import JavaScriptCore
import Testing
@testable import TonConnectJSCoreEngine

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
}
