import Foundation
import Testing
import TonConnectTransport

/// SSEEventParser framing tests : a pure function, no network.
/// The scenarios — spec/bridge.md + WHATWG text/event-stream.
struct SSEEventParserTests {

    @Test func testConsumeSingleEventParsesIdAndData() {
        var parser = SSEEventParser()
        let events = parser.consume(Data("id: 42\ndata: hello\n\n".utf8))
        #expect(events == [SSEEvent(id: "42", event: nil, data: "hello")])
    }

    @Test func testConsumeMultiLineDataJoinsWithNewline() {
        var parser = SSEEventParser()
        let events = parser.consume(Data("data: a\ndata: b\n\n".utf8))
        #expect(events == [SSEEvent(id: nil, event: nil, data: "a\nb")])
    }

    @Test func testConsumeCommentLineIsIgnored() {
        var parser = SSEEventParser()
        let events = parser.consume(Data(":keep-alive\n\n".utf8))
        #expect(events.isEmpty)
    }

    @Test func testConsumePartialLineAcrossChunksBuffersUntilComplete() {
        var parser = SSEEventParser()
        let first = parser.consume(Data("data: par".utf8))
        #expect(first.isEmpty)
        let second = parser.consume(Data("tial\n\n".utf8))
        #expect(second == [SSEEvent(id: nil, event: nil, data: "partial")])
    }

    @Test func testConsumeNamedEventPopulatesEventField() {
        var parser = SSEEventParser()
        let events = parser.consume(Data("event: message\ndata: x\n\n".utf8))
        #expect(events == [SSEEvent(id: nil, event: "message", data: "x")])
    }

    @Test func testConsumeBlankLineWithoutDataEmitsNoEvent() {
        var parser = SSEEventParser()
        let events = parser.consume(Data("\n\n\n".utf8))
        #expect(events.isEmpty)
    }

    // MARK: - ceilings (the bridge is not trusted)

    @Test func testConsumeLineLongerThanTheCeilingRecordsAViolationAndStopsParsing() {
        var parser = SSEEventParser(limits: .init(maxLineBytes: 64))
        _ = parser.consume(Data(repeating: 0x61, count: 40))
        #expect(parser.violation == nil, "under the ceiling, still buffering")
        _ = parser.consume(Data(repeating: 0x61, count: 40))
        #expect(parser.violation == .lineTooLong)
        let after = parser.consume(Data("\ndata: x\n\n".utf8))
        #expect(after.isEmpty, "a dead parser accepts nothing more")
    }

    @Test func testConsumeEventWithMoreDataThanTheCeilingRecordsAViolation() {
        var parser = SSEEventParser(limits: .init(maxEventDataBytes: 16))
        let events = parser.consume(Data("data: 0123456789\ndata: 0123456789\n\n".utf8))
        #expect(events.isEmpty)
        #expect(parser.violation == .eventDataTooLarge)
    }

    @Test func testConsumeIDLongerThanTheCeilingRecordsAViolation() {
        var parser = SSEEventParser(limits: .init(maxIDBytes: 8))
        _ = parser.consume(Data("id: 123456789\n".utf8))
        #expect(parser.violation == .idTooLong)
    }

    /// The default ceilings are far above a real frame: a 20 KiB base64 event
    /// passes untouched.
    @Test func testDefaultCeilingsLeaveARealisticFrameAlone() {
        var parser = SSEEventParser()
        let payload = String(repeating: "A", count: 20 * 1024)
        let events = parser.consume(Data("id: 1\ndata: \(payload)\n\n".utf8))
        #expect(events.count == 1)
        #expect(events.first?.data.count == 20 * 1024)
        #expect(parser.violation == nil)
    }

    /// Bytes are cut at newlines and decoded per line, so a multi-byte character
    /// split across two chunks survives intact.
    @Test func testMultiByteCharacterSplitAcrossChunksIsDecodedWhole() {
        var parser = SSEEventParser()
        let bytes = Array("data: héllo\n\n".utf8) // é = 0xC3 0xA9
        let cut = bytes.firstIndex(of: 0xC3)! + 1
        let first = parser.consume(Data(bytes[..<cut]))
        #expect(first.isEmpty)
        let second = parser.consume(Data(bytes[cut...]))
        #expect(second == [SSEEvent(id: nil, event: nil, data: "héllo")])
    }
}
