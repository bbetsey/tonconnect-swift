import JavaScriptCore

/// EVERY SDK method calls createAbortController() first thing —
/// without a global AbortController, connect/send/sign/disconnect/restore
/// immediately throw ReferenceError: AbortController is not defined. Implemented
/// in pure JS (an event emitter, no OS capabilities) — unlike fetch/EventSource,
/// no native backend is needed.
public final class AbortControllerPolyfill: JSPolyfill {
    public init() {}
    public func apply(to context: JSContext) {
        context.evaluateScript("""
        (function(){
          if (typeof globalThis.AbortController !== 'undefined') return;
          class _AbortSignal {
            constructor(){ this.aborted = false; this._cbs = []; }
            addEventListener(type, cb){ if (type === 'abort') this._cbs.push(cb); }
            removeEventListener(type, cb){ if (type === 'abort') this._cbs = this._cbs.filter(function(f){return f!==cb;}); }
            _fire(){ this.aborted = true; var cbs = this._cbs.slice(); for (var i=0;i<cbs.length;i++){ try{ cbs[i](); }catch(e){} } }
          }
          class _AbortController {
            constructor(){ this.signal = new _AbortSignal(); }
            abort(){ if(!this.signal.aborted) this.signal._fire(); }
          }
          globalThis.AbortController = _AbortController;
          globalThis.AbortSignal = _AbortSignal;
        })();
        """)
    }
}
