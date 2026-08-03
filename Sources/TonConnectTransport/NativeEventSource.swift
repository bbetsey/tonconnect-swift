import Foundation

/// An honest low-level wrapper of the browser EventSource over a URLSession stream.
/// Does NOT reconnect on its own: on a drop it calls onError, and the reconnect
/// cadence is held one layer up (otherwise two layers race to reconnect the same
/// client_id). NativeEngine ADDS its own reconnect layer on top of this very
/// wrapper, additively.
public final class NativeEventSource: NSObject, @unchecked Sendable {
    /// Mirrors the browser EventSource readyState values, same numbering.
    public enum ReadyState: Int, Sendable { case connecting = 0, open = 1, closed = 2 }

    private let url: String
    private let lastEventId: String?
    private var parser = SSEEventParser()
    private var session: URLSession!
    private var task: URLSessionDataTask?
    private let stateLock = NSLock()
    private var _readyState: ReadyState = .connecting
    /// Test seam (internal): tests inject a configuration with the fake's
    /// protocolClasses. URLProtocol.registerClass has no effect on sessions with
    /// a custom configuration (verified empirically).
    var sessionConfiguration: URLSessionConfiguration = .ephemeral

    /// The stream is open — set these before calling ``connect()``.
    public var onOpen: (() -> Void)?
    /// One parsed SSE event: the frame id (used as `last_event_id` on reconnect)
    /// and its data payload.
    public var onMessage: ((_ id: String?, _ data: String) -> Void)?
    /// The stream ended or failed. Reconnecting is the caller's decision — this
    /// wrapper deliberately never does it on its own.
    public var onError: ((Error?) -> Void)?
    /// onRawData — the fact that bytes arrived (including a heartbeat without
    /// data:, which the parser ignores per spec), for the reconnect layer's
    /// heartbeat watchdog. The transport still never
    /// reconnects on its own.
    public var onRawData: ((Data) -> Void)?

    /// Thread-safe snapshot of the stream's state.
    public var readyState: ReadyState {
        stateLock.lock(); defer { stateLock.unlock() }; return _readyState
    }

    /// last_event_id is a QUERY parameter of GET /events (spec/bridge.md), not a header.
    /// sessionConfiguration — a seam for tests/debugging (the fake's protocolClasses).
    public init(url: String, lastEventId: String?,
                sessionConfiguration: URLSessionConfiguration = .ephemeral) {
        self.url = url
        self.lastEventId = lastEventId
        self.sessionConfiguration = sessionConfiguration
        super.init()
    }

    /// Opens the stream. Callbacks start firing on URLSession's delegate queue.
    public func connect() {
        var components = URLComponents(string: url)
        if let lastEventId = lastEventId, !lastEventId.isEmpty {
            var items = components?.queryItems ?? []
            items.append(URLQueryItem(name: "last_event_id", value: lastEventId))
            components?.queryItems = items
        }
        guard let resolved = components?.url else { fail(URLError(.badURL)); return }
        var request = URLRequest(url: resolved)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.timeoutInterval = TimeInterval.infinity // the SSE stream is long-lived — no waiting timeout
        session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request)
        self.task = task
        setState(.connecting)
        task.resume()
    }

    /// Ends the stream and tears the session down. Idempotent.
    public func close() {
        setState(.closed)
        task?.cancel()
        session?.invalidateAndCancel()
    }

    private func setState(_ s: ReadyState) { stateLock.lock(); _readyState = s; stateLock.unlock() }
    private func fail(_ error: Error?) { setState(.closed); onError?(error) }
}

extension NativeEventSource: URLSessionDataDelegate {
    public func urlSession(_ s: URLSession, dataTask: URLSessionDataTask,
                           didReceive response: URLResponse,
                           completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        if (200..<300).contains(code) { setState(.open); onOpen?() }
        completionHandler(.allow)
    }
    public func urlSession(_ s: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        onRawData?(data) // "the stream sent something" — record BEFORE parsing
        for event in parser.consume(data) { onMessage?(event.id, event.data) }
    }
    public func urlSession(_ s: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // The stream finished/dropped. NO reconnect — signal only.
        if readyState != .closed { fail(error) }
    }
}
