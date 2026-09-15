import Foundation

/// A single SSE event (spec/bridge.md). The SDK reads only data and lastEventId (id).
public struct SSEEvent: Equatable, Sendable {
    public let id: String?
    public let event: String?
    public let data: String

    public init(id: String? = nil, event: String? = nil, data: String) {
        self.id = id
        self.event = event
        self.data = data
    }
}

/// An incremental `text/event-stream` framing parser. Pure Swift (SSE is
/// parsed in Swift, JS receives ready-made events). Does NOT reconnect on its own —
/// this is low-level framing; the reconnect policy is held above.
///
/// Bounded. The stream comes from a bridge, and a bridge is not trusted: one
/// that sends bytes without ever sending a newline, or an event that never ends,
/// used to be held in memory in full and rescanned from the start on every
/// chunk — quadratic time and unbounded memory, on the app's side, at the
/// bridge's discretion. Every buffer here has a ceiling (``Limits``); the first
/// one crossed is recorded in ``violation``, after which the parser accepts
/// nothing more. The owner of the stream is expected to close it.
public struct SSEEventParser {

    /// Ceilings for what a single stream may make the parser hold. Real bridge
    /// frames are a few kilobytes of base64; the defaults leave two orders of
    /// magnitude of room.
    public struct Limits: Equatable, Sendable {
        /// The longest line, in bytes, that may accumulate without a newline.
        public var maxLineBytes: Int
        /// The most `data:` bytes one event may carry, all its lines together.
        public var maxEventDataBytes: Int
        /// The longest `id:` value, in bytes — it travels back to the bridge as
        /// `last_event_id` and into the session record.
        public var maxIDBytes: Int

        public init(maxLineBytes: Int = 1 << 20, maxEventDataBytes: Int = 1 << 20, maxIDBytes: Int = 256) {
            self.maxLineBytes = maxLineBytes
            self.maxEventDataBytes = maxEventDataBytes
            self.maxIDBytes = maxIDBytes
        }

        public static let `default` = Limits()
    }

    /// Which ceiling a stream crossed.
    public enum LimitViolation: Equatable, Sendable {
        case lineTooLong
        case eventDataTooLarge
        case idTooLong
    }

    public let limits: Limits
    /// Set once a limit was crossed; the parser is dead from then on.
    public private(set) var violation: LimitViolation?

    private var lineBuffer: [UInt8] = [] // an incomplete line carried over between chunks
    private var dataLines: [String] = []
    private var dataBytes = 0
    private var eventType: String?
    private var lastId: String?

    public init(limits: Limits = .default) {
        self.limits = limits
    }

    /// Feeds in the next chunk of bytes, returns the completed events.
    ///
    /// Lines are cut at newlines in the byte stream and decoded one at a time —
    /// so a multi-byte UTF-8 character split across two chunks is decoded whole,
    /// and a chunk costs the parser its own length, not the buffer's.
    public mutating func consume(_ chunk: Data) -> [SSEEvent] {
        guard violation == nil else { return [] }
        var events: [SSEEvent] = []
        var lineStart = 0
        var bytes = chunk // a local copy: Data's indices need not start at 0
        bytes.withUnsafeBytes { raw in
            let buffer = raw.bindMemory(to: UInt8.self)
            for index in buffer.indices where buffer[index] == 0x0A { // "\n"
                let line = lineBuffer + Array(buffer[lineStart..<index])
                lineBuffer.removeAll(keepingCapacity: true)
                lineStart = index + 1
                if let event = handle(line: line) { events.append(event) }
                if violation != nil { return }
            }
            guard violation == nil else { return }
            let tail = buffer[lineStart...]
            if lineBuffer.count + tail.count > limits.maxLineBytes {
                violation = .lineTooLong
                lineBuffer = []
                return
            }
            lineBuffer.append(contentsOf: tail)
        }
        bytes.removeAll()
        return events
    }

    /// One complete line, without its newline; the carriage return of a CRLF
    /// pair is dropped here.
    private mutating func handle(line rawLine: [UInt8]) -> SSEEvent? {
        var lineBytes = rawLine[...]
        if lineBytes.last == 0x0D { lineBytes = lineBytes.dropLast() } // "\r"
        if lineBytes.count > limits.maxLineBytes { violation = .lineTooLong; return nil }
        if lineBytes.isEmpty { return flush() }
        if lineBytes.first == 0x3A { return nil } // ":" — comment / keep-alive
        let line = String(decoding: lineBytes, as: UTF8.self)
        let (field, value) = Self.split(line)
        switch field {
        case "data":
            dataBytes += value.utf8.count
            if dataBytes > limits.maxEventDataBytes { violation = .eventDataTooLarge; return nil }
            dataLines.append(value)
        case "event":
            eventType = value
        case "id":
            if value.utf8.count > limits.maxIDBytes { violation = .idTooLong; return nil }
            lastId = value
        default:
            break // other fields (retry) ignored
        }
        return nil
    }

    private mutating func flush() -> SSEEvent? {
        defer { dataLines = []; dataBytes = 0; eventType = nil }
        guard !dataLines.isEmpty else { return nil } // a blank line without data → not an event
        return SSEEvent(id: lastId, event: eventType, data: dataLines.joined(separator: "\n"))
    }

    /// "field: value" (the space after the colon is optional per spec and consumed).
    private static func split(_ line: String) -> (String, String) {
        guard let idx = line.firstIndex(of: ":") else { return (line, "") }
        let field = String(line[line.startIndex..<idx])
        var value = String(line[line.index(after: idx)...])
        if value.hasPrefix(" ") { value.removeFirst() }
        return (field, value)
    }
}
