import Foundation
import JavaScriptCore

/// setTimeout/setInterval/clearTimeout/clearInterval → DispatchSourceTimer.
/// NOT stateless: init(jsQueue:) — the timer fires on the same serial queue that
/// owns the JSContext (a divergence from kit-ios, which uses a
/// separate callbackQueue).
///
/// Callbacks live in a JS registry on globalThis (the EventSourcePolyfill
/// pattern) — a GC root, uncollectable, dying with the context. A
/// JSManagedValue(owner: context) here was effectively a weak reference: GC ate
/// the callback under pressure, SDK promises hung and dropped the continuation
/// in awaitPromise (ManagedValueLifetimeTests).
public final class TimerPolyfill: JSPolyfill {
    private let jsQueue: DispatchQueue
    private let lock = NSLock()
    private var timers: [Int32: DispatchSourceTimer] = [:]
    private var nextIdentifier: Int32 = 1
    // weak: do not resurrect the cycle context→block→polyfill→context.
    private weak var context: JSContext?

    public init(jsQueue: DispatchQueue) {
        self.jsQueue = jsQueue
    }

    deinit {
        // Safety net: cancel unclosed sources (no JS touched — the context is already dying).
        for timer in timers.values { timer.cancel() }
    }

    public func apply(to context: JSContext) {
        self.context = context
        context.evaluateScript("""
            globalThis.__tcTimers = {};
            globalThis.__tcTimerFire = function (id, once) {
                var fn = __tcTimers[id];
                if (!fn) return;
                if (once) delete __tcTimers[id];
                fn();
            };
            """)
        // The blocks capture self strongly: the polyfill lives exactly as long as the JSContext.
        let setTimeout: @convention(block) (JSValue, Double) -> Int32 = { callback, ms in
            self.schedule(callback: callback, ms: ms, repeats: false)
        }
        let setInterval: @convention(block) (JSValue, Double) -> Int32 = { callback, ms in
            self.schedule(callback: callback, ms: ms, repeats: true)
        }
        let clearTimer: @convention(block) (Int32) -> Void = { identifier in
            self.cancel(identifier)
        }
        context.setObject(setTimeout, forKeyedSubscript: "setTimeout" as NSString)
        context.setObject(setInterval, forKeyedSubscript: "setInterval" as NSString)
        context.setObject(clearTimer, forKeyedSubscript: "clearTimeout" as NSString)
        context.setObject(clearTimer, forKeyedSubscript: "clearInterval" as NSString)
    }

    private func schedule(callback: JSValue, ms: Double, repeats: Bool) -> Int32 {
        guard callback.isObject, isFunction(callback), let ctx = callback.context else { return -1 }

        lock.lock()
        let identifier = nextIdentifier
        nextIdentifier += 1
        lock.unlock()

        // We are on the JS queue (schedule is called only from the
        // setTimeout/setInterval blocks) — putting a JSValue into the registry is safe.
        ctx.objectForKeyedSubscript("__tcTimers")?
            .setObject(callback, forKeyedSubscript: "\(identifier)" as NSString)

        let timer = DispatchSource.makeTimerSource(queue: jsQueue) // fires on jsQueue
        let delaySeconds = max(0.0, ms) / 1000.0
        if repeats {
            timer.schedule(deadline: .now() + delaySeconds, repeating: delaySeconds)
        } else {
            timer.schedule(deadline: .now() + delaySeconds)
        }
        timer.setEventHandler { [weak self] in
            guard let self, let ctx = self.context else { return }
            ctx.objectForKeyedSubscript("__tcTimerFire")?
                .call(withArguments: [identifier, !repeats])
            if !repeats { self.cancel(identifier) }
        }

        lock.lock()
        timers[identifier] = timer
        lock.unlock()
        timer.resume()
        return identifier
    }

    /// Called only on jsQueue (the clearTimeout block or the event handler) — touching JS is fine.
    private func cancel(_ identifier: Int32) {
        lock.lock()
        let timer = timers.removeValue(forKey: identifier)
        lock.unlock()
        timer?.cancel()
        context?.objectForKeyedSubscript("__tcTimers")?
            .deleteProperty("\(identifier)")
    }

    /// JSValue has no public isFunction — check via the JavaScriptCore C API.
    private func isFunction(_ value: JSValue) -> Bool {
        guard let context = value.context else { return false }
        return JSObjectIsFunction(context.jsGlobalContextRef, value.jsValueRef)
    }
}
