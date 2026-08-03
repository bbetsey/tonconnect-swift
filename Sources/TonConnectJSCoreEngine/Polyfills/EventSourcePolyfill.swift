import Foundation
import JavaScriptCore
import TonConnectTransport

/// globalThis.EventSource on top of NativeEventSource.
/// The SDK's surface: new EventSource(url), .onopen/.onmessage/.onerror,
/// .readyState, the CONNECTING/OPEN/CLOSED statics, .close(). The SDK puts
/// last_event_id into the url itself.
/// Native callbacks arrive on a URLSession thread → hop via bridge.enqueue;
/// JS callbacks live on the JS object (the __esDispatch registry) — not stored in Swift.
public final class EventSourcePolyfill: JSPolyfill {
    // weak: do not resurrect the retain cycle bridge→context→block→polyfill→bridge.
    private weak var bridge: JSCoreBridge?
    private let lock = NSLock()
    private var sources: [Int32: NativeEventSource] = [:]
    private var nextIdentifier: Int32 = 1
    private let sessionConfiguration: URLSessionConfiguration

    public init(bridge: JSCoreBridge, sessionConfiguration: URLSessionConfiguration = .ephemeral) {
        self.bridge = bridge
        self.sessionConfiguration = sessionConfiguration
    }

    deinit {
        // Safety net: URLSession holds its delegate until invalidate — close any unclosed streams.
        for source in sources.values { source.close() }
    }

    public func apply(to context: JSContext) {
        // The blocks capture self strongly (the TimerPolyfill idiom) — the polyfill lives with the JSContext.
        let create: @convention(block) (String) -> Int32 = { url in
            guard JSContext.current() != nil else {
                fatalError("__nativeESCreate called outside a JSContext")
            }
            self.lock.lock()
            let identifier = self.nextIdentifier
            self.nextIdentifier += 1
            self.lock.unlock()

            let source = NativeEventSource(url: url, lastEventId: nil,
                                           sessionConfiguration: self.sessionConfiguration)
            // [weak self]: the polyfill holds the source via the registry — otherwise a polyfill↔source cycle.
            source.onOpen = { [weak self] in
                self?.dispatch(identifier, type: "open", data: "", lastEventId: "")
            }
            source.onMessage = { [weak self] eventId, data in
                self?.dispatch(identifier, type: "message", data: data, lastEventId: eventId ?? "")
            }
            source.onError = { [weak self] error in
                self?.dispatch(identifier, type: "error",
                               data: error.map { "\($0)" } ?? "stream closed", lastEventId: "")
            }
            self.lock.lock()
            self.sources[identifier] = source
            self.lock.unlock()
            source.connect()
            return identifier
        }
        let close: @convention(block) (Int32) -> Void = { identifier in
            self.lock.lock()
            let source = self.sources.removeValue(forKey: identifier)
            self.lock.unlock()
            source?.close()
        }
        let readyState: @convention(block) (Int32) -> Int32 = { identifier in
            self.lock.lock()
            let source = self.sources[identifier]
            self.lock.unlock()
            return Int32(source?.readyState.rawValue ?? NativeEventSource.ReadyState.closed.rawValue)
        }
        context.setObject(create, forKeyedSubscript: "__nativeESCreate" as NSString)
        context.setObject(close, forKeyedSubscript: "__nativeESClose" as NSString)
        context.setObject(readyState, forKeyedSubscript: "__nativeESReadyState" as NSString)
        context.evaluateScript("""
            (function(){
              var instances = {};
              globalThis.__esDispatch = function(id, type, data, lastEventId) {
                var inst = instances[id];
                if (!inst) return;
                if (type === 'open') { if (typeof inst.onopen === 'function') inst.onopen(); }
                else if (type === 'message') {
                  if (typeof inst.onmessage === 'function')
                    inst.onmessage({ data: data, lastEventId: lastEventId });
                }
                else if (type === 'error') { if (typeof inst.onerror === 'function') inst.onerror(data); }
              };
              class EventSource {
                constructor(url) {
                  this._id = __nativeESCreate(String(url));
                  instances[this._id] = this;
                }
                close() { delete instances[this._id]; __nativeESClose(this._id); }
                get readyState() { return __nativeESReadyState(this._id); }
              }
              EventSource.CONNECTING = 0;
              EventSource.OPEN = 1;
              EventSource.CLOSED = 2;
              globalThis.EventSource = EventSource;
            })();
            """)
    }

    /// A native callback from a URLSession thread → the JS queue, then __esDispatch.
    private func dispatch(_ identifier: Int32, type: String, data: String, lastEventId: String) {
        guard let bridge = self.bridge else { return }
        bridge.enqueue { [weak bridge] in
            guard let context = bridge?.context,
                  let dispatcher = context.objectForKeyedSubscript("__esDispatch") else { return }
            dispatcher.call(withArguments: [identifier, type, data, lastEventId])
        }
    }
}
