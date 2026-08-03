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
public struct SSEEventParser {
    private var lineBuffer = "" // an incomplete line carried over between chunks
    private var dataLines: [String] = []
    private var eventType: String?
    private var lastId: String?

    public init() {}

    /// Feeds in the next chunk of bytes, returns the completed events.
    public mutating func consume(_ chunk: Data) -> [SSEEvent] {
        var events: [SSEEvent] = []
        lineBuffer += String(decoding: chunk, as: UTF8.self)
        // Split on \n; the last element may be an incomplete line → keep it in the buffer.
        var lines = lineBuffer.components(separatedBy: "\n")
        lineBuffer = lines.removeLast()
        for rawLine in lines {
            let line = rawLine.hasSuffix("\r") ? String(rawLine.dropLast()) : rawLine
            if line.isEmpty {
                if let event = flush() { events.append(event) }
                continue
            }
            if line.hasPrefix(":") { continue } // comment / keep-alive
            let (field, value) = Self.split(line)
            switch field {
            case "data": dataLines.append(value)
            case "event": eventType = value
            case "id": lastId = value
            default: break // other fields (retry) ignored
            }
        }
        return events
    }

    private mutating func flush() -> SSEEvent? {
        defer { dataLines = []; eventType = nil }
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
