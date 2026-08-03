import Foundation

/// A reusable TON Connect bridge fake via URLProtocol (automated tier).
/// v3: state is stored PER-CLASS (ObjectIdentifier) — each test suite
/// declares its own subclass (`private final class MyFake: FakeBridgeURLProtocol {}`)
/// and gets an isolated scenario: parallel Swift Testing suites no longer race
/// over shared statics (lesson learned: one suite's keepEventsStreamOpen used to
/// hang a neighbor's continuation).
open class FakeBridgeURLProtocol: URLProtocol {
    /// What the fake bridge should do: how POST /message answers and which SSE
    /// frames GET /events plays back.
    public struct Script: Sendable {
        public var postStatus: Int = 200
        /// SSE frames for GET /events: (id, data). Played back in order.
        public var sseFrames: [(id: String?, data: String)] = []
        /// true → GET /events does NOT finish: frames arrive later via pushFrame.
        public var keepEventsStreamOpen: Bool = false
        public init() {}
    }

    private struct State {
        var script = Script()
        var recordedRequestURLs: [URL] = []
        var eventsFrameProvider: ((URL) -> [(id: String?, data: String)])?
        var messageHandler: ((URL, String) -> Void)?
        var liveEventStreams: [FakeBridgeURLProtocol] = []
    }
    nonisolated(unsafe) private static var states: [ObjectIdentifier: State] = [:]
    private static let stateLock = NSLock()

    private static func withState<T>(of cls: AnyClass, _ body: (inout State) -> T) -> T {
        stateLock.lock()
        defer { stateLock.unlock() }
        return body(&states[ObjectIdentifier(cls), default: State()])
    }

    // `self` in the static accessors is the metatype the call came through (the
    // subclass), so every subclass gets its own state cell.
    public static var script: Script {
        get { withState(of: self) { $0.script } }
        set { withState(of: self) { $0.script = newValue } }
    }
    public static var recordedRequestURLs: [URL] {
        get { withState(of: self) { $0.recordedRequestURLs } }
        set { withState(of: self) { $0.recordedRequestURLs = newValue } }
    }
    public static var eventsFrameProvider: ((URL) -> [(id: String?, data: String)])? {
        get { withState(of: self) { $0.eventsFrameProvider } }
        set { withState(of: self) { $0.eventsFrameProvider = newValue } }
    }
    public static var messageHandler: ((URL, String) -> Void)? {
        get { withState(of: self) { $0.messageHandler } }
        set { withState(of: self) { $0.messageHandler = newValue } }
    }

    /// Full reset of this subclass's scenario.
    public static func reset() {
        withState(of: self) { $0 = State() }
    }

    /// A frame into every live /events stream of THIS subclass (keepEventsStreamOpen).
    public static func pushFrame(id: String?, data: String) {
        let streams = withState(of: self) { $0.liveEventStreams }
        for stream in streams {
            stream.client?.urlProtocol(stream, didLoad: Data(frameText(id: id, data: data).utf8))
        }
    }
    
    /// Raw bytes (NOT a well-formed SSE frame) into every live /events stream of
    /// this subclass — simulates a legacy heartbeat (": heartbeat" without data:).
    public static func pushRawText(_ text: String) {
        let streams = withState(of: self) { $0.liveEventStreams }
        for stream in streams {
            stream.client?.urlProtocol(stream, didLoad: Data(text.utf8))
        }
    }
    
    /// The number of live /events streams of this subclass — observability of the
    /// losing gateways being closed in the race tests.
    public static var liveEventStreamCount: Int {
        withState(of: self) { $0.liveEventStreams.count }
    }

    private static func frameText(id: String?, data: String) -> String {
        var text = ""
        if let id { text += "id: \(id)\n" }
        text += "data: \(data)\n\n"
        return text
    }

    open override class func canInit(with request: URLRequest) -> Bool {
        request.url?.path.contains("/message") == true || request.url?.path.contains("/events") == true
    }
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    open override func startLoading() {
        let cls = type(of: self)
        guard let url = request.url else { client?.urlProtocolDidFinishLoading(self); return }
        Self.withState(of: cls) { $0.recordedRequestURLs.append(url) }
        if url.path.contains("/events") {
            let headers = ["Content-Type": "text/event-stream"]
            let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            let provider = Self.withState(of: cls) { $0.eventsFrameProvider }
            let frames = provider?(url) ?? Self.withState(of: cls) { $0.script.sseFrames }
            for frame in frames {
                client?.urlProtocol(self, didLoad: Data(Self.frameText(id: frame.id, data: frame.data).utf8))
            }
            if Self.withState(of: cls, { $0.script.keepEventsStreamOpen }) {
                Self.withState(of: cls) { $0.liveEventStreams.append(self) }
                // The stream stays alive — do NOT call didFinishLoading; frames arrive via pushFrame.
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
        } else { // /message
            let body = Self.readBody(from: request)
            let handler = Self.withState(of: cls) { $0.messageHandler }
            handler?(url, body)
            let status = Self.withState(of: cls) { $0.script.postStatus }
            let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    public override func stopLoading() {
        let cls = type(of: self)
        Self.withState(of: cls) { $0.liveEventStreams.removeAll { $0 === self } }
    }

    /// URLSession converts httpBody into httpBodyStream inside URLProtocol —
    /// httpBody is always nil here, so read the stream.
    private static func readBody(from request: URLRequest) -> String {
        if let body = request.httpBody { return String(decoding: body, as: UTF8.self) }
        guard let stream = request.httpBodyStream else { return "" }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let count = stream.read(buffer, maxLength: bufferSize)
            if count <= 0 { break }
            data.append(buffer, count: count)
        }
        return String(decoding: data, as: UTF8.self)
    }
}
