import Foundation
import JavaScriptCore
import Testing
@testable import TonConnectJSCoreEngine

/// The JS glue smoke : after loadBundle every __tc* global is exposed.
/// __tcCreateEngine is NOT called here — the native __nativeStorage*/__tcEmitEvent
/// are installed by 03-06/03-08; the full E2E flow is checked by 03-09.
struct GlueSmokeTests {

    @Test func testGlueGlobalsExistAfterBundleLoad() throws {
        let bridge = JSCoreBridge()
        try bridge.loadBundle()
        let allFunctions = bridge.perform { ctx in
            ctx.evaluateScript("""
                typeof globalThis.__tcCreateEngine === 'function'
                && typeof globalThis.__tcConnect === 'function'
                && typeof globalThis.__tcPause === 'function'
                && typeof globalThis.__tcUnpause === 'function'
                """)!.toBool()
        }
        #expect(allFunctions == true)
        #expect(bridge.lastException == nil)
    }

    @Test func testRpcAndStorageGlueGlobalsExist() throws {
        let bridge = JSCoreBridge()
        try bridge.loadBundle()
        let allFunctions = bridge.perform { ctx in
            ctx.evaluateScript("""
                typeof globalThis.__tcSendTransaction === 'function'
                && typeof globalThis.__tcSignData === 'function'
                && typeof globalThis.__tcDisconnect === 'function'
                && typeof globalThis.__tcRestore === 'function'
                && typeof globalThis.__tcDestroy === 'function'
                """)!.toBool()
        }
        #expect(allFunctions == true)
        #expect(bridge.lastException == nil)
    }
}
