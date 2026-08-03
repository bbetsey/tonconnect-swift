import Foundation
import Testing
import TonConnectTransport

/// A URLProtocol stub: intercepts any request of the session and serves the
/// canned response. The statics are shared state, hence @Suite(.serialized):
/// parallel tests would otherwise race for one canned response.
final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var stubStatus: Int?
    nonisolated(unsafe) static var stubError: Error?
    nonisolated(unsafe) static var lastContentType: String?

    override static func canInit(with request: URLRequest) -> Bool { true }
    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastContentType = request.value(forHTTPHeaderField: "Content-Type")
        if let error = Self.stubError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let status = Self.stubStatus ?? 200
        let response = HTTPURLResponse(
            url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Suite(.serialized) struct NativeFetchTests {

    private func makeFetch() -> NativeFetch {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return NativeFetch(session: URLSession(configuration: config))
    }

    private func post(_ fetch: NativeFetch) async -> Result<FetchResponse, Error> {
        await withCheckedContinuation { continuation in
            fetch.post(url: "https://bridge.example/message", body: Data("probe".utf8)) {
                continuation.resume(returning: $0)
            }
        }
    }
    
    @Test func testPostSendsTextPlainContentType() async throws {
        StubURLProtocol.stubStatus = 200
        StubURLProtocol.stubError = nil
        StubURLProtocol.lastContentType = nil
        _ = await post(makeFetch())
        // Browser-fetch parity: Tonhub's bridge rejects URLSession's default
        // (application/x-www-form-urlencoded) with HTTP 415.
        #expect(StubURLProtocol.lastContentType == "text/plain;charset=UTF-8")
    }

    @Test func testPostWith200ReturnsOkTrue() async throws {
        StubURLProtocol.stubStatus = 200
        StubURLProtocol.stubError = nil
        let result = await post(makeFetch())
        let response = try result.get()
        #expect(response.ok == true)
        #expect(response.status == 200)
    }

    @Test func testPostWith500ReturnsOkFalse() async throws {
        StubURLProtocol.stubStatus = 500
        StubURLProtocol.stubError = nil
        let result = await post(makeFetch())
        let response = try result.get()
        #expect(response.ok == false)
        #expect(response.status == 500)
    }

    @Test func testPostTransportErrorPropagatesFailure() async {
        StubURLProtocol.stubStatus = nil
        StubURLProtocol.stubError = URLError(.notConnectedToInternet)
        let result = await post(makeFetch())
        guard case .failure = result else {
            Issue.record("expected .failure for transport error, got \(result)")
            return
        }
    }
}
