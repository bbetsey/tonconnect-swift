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
}
