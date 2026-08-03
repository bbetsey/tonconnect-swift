import Foundation
import JavaScriptCore
import Testing
@testable import TonConnectJSCoreEngine

/// A smoke through the full stack — the bundle
/// exposed the SDK, new TonConnect({manifestUrl}) creates an instance. A failure
/// here = the bundle integration; the bridge itself is checked in isolation by
/// PromiseBridgeTests.
struct SDKSmokeTests {

    @Test func testTonConnectSDKIsExposedOnGlobalAfterBundleLoad() throws {
        let bridge = JSCoreBridge()
        try bridge.loadBundle()
        let hasSDK = bridge.perform { ctx in
            ctx.evaluateScript(
                "typeof globalThis.TonConnectSDK !== 'undefined' && typeof globalThis.TonConnectSDK.TonConnect === 'function'"
            )!.toBool()
        }
        #expect(hasSDK == true)
    }

    @Test func testNewTonConnectInstanceCreatesWithoutThrowing() throws {
        let bridge = JSCoreBridge()
        try bridge.loadBundle()
        let created = bridge.perform { ctx -> Bool in
            ctx.evaluateScript("""
                (function() {
                    try {
                        var tc = new globalThis.TonConnectSDK.TonConnect({ manifestUrl: 'https://example.com/tonconnect-manifest.json' });
                        return typeof tc === 'object' && tc !== null;
                    } catch (e) {
                        globalThis.__smokeError = String(e);
                        return false;
                    }
                })()
                """)!.toBool()
        }
        let smokeError = bridge.perform { ctx in
            ctx.evaluateScript("globalThis.__smokeError || ''")!.toString()
        }
        #expect(created == true, "new TonConnect threw: \(smokeError ?? "?")")
        #expect(bridge.lastException == nil, "instantiating the SDK must leave no unexpected exceptions")
    }
}
