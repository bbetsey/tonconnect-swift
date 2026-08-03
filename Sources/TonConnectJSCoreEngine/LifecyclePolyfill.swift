import Foundation
import JavaScriptCore

/// The lifecycle bridge: Swift invokes the SDK's
/// pauseConnection()/unPauseConnection() through the glue. unPause → the SDK
/// recreates the EventSource with the saved last_event_id — that IS the whole
/// resume mechanism, and Swift merely triggers it at the right moment. The
/// UIApplication subscription lives in the engine.
public final class LifecyclePolyfill {
    private unowned let bridge: JSCoreBridge
    public init(bridge: JSCoreBridge) { self.bridge = bridge }

    /// Called by the engine from UIApplication.willResignActiveNotification.
    public func pause() {
        bridge.perform { ctx in _ = ctx.evaluateScript("globalThis.__tcPause && globalThis.__tcPause()") }
    }

    /// Called by the engine from UIApplication.didBecomeActiveNotification.
    public func unpause() {
        bridge.perform { ctx in _ = ctx.evaluateScript("globalThis.__tcUnpause && globalThis.__tcUnpause()") }
    }

    /// The "simulate wake" test hook — ForegroundReconnectTests
    /// triggers a reconnect without a real background/foreground. Exactly the same path as unpause().
    public func simulateWake() { unpause() }
}
