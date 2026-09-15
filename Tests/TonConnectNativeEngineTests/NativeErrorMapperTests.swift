import Foundation
import Testing
import TonConnectCore
@testable import TonConnectNativeEngine

@Suite struct NativeErrorMapperTests {

    @Test func testMapPassesThroughExistingTonConnectError() {
        let original = TonConnectError.network(message: "x")
        #expect(NativeErrorMapper.map(original) == original)
    }

    @Test func testMapSessionCryptoErrorBecomesInternalError() {
        let mapped = NativeErrorMapper.map(SessionCryptoError.decryptionFailed)
        guard case .internalError(let message) = mapped else {
            Issue.record("expected .internalError, got \(mapped)")
            return
        }
        #expect(message.contains("session crypto"))
    }

    @Test func testMapURLErrorBecomesNetwork() {
        let mapped = NativeErrorMapper.map(URLError(.notConnectedToInternet))
        guard case .network = mapped else {
            Issue.record("expected .network, got \(mapped)")
            return
        }
    }

    @Test func testMapDecodingErrorBecomesInternalError() {
        let decodingError = DecodingError.dataCorrupted(
            .init(codingPath: [], debugDescription: "broken json")
        )
        let mapped = NativeErrorMapper.map(decodingError)
        guard case .internalError = mapped else {
            Issue.record("expected .internalError, got \(mapped)")
            return
        }
    }

    @Test func testWalletDeclinedCode300MapsToWalletDeclined() {
        let mapped = NativeErrorMapper.walletDeclined(code: 300, message: "user declined")
        #expect(mapped == .walletDeclined(code: 300, message: "user declined"))
    }

    // MARK: - what the message carries

    /// A URLError's userInfo holds the failing URL — for a bridge POST that is the
    /// session's client_id and the wallet's key. The message must not.
    @Test func testMapURLErrorMessageDoesNotCarryTheFailingURL() {
        let url = URL(string: "https://bridge.test/message?client_id=aa11&to=bb22&ttl=300&topic=sendTransaction")!
        let error = URLError(.notConnectedToInternet, userInfo: [NSURLErrorFailingURLStringErrorKey: url.absoluteString,
                                                                 NSURLErrorFailingURLErrorKey: url])
        let mapped = NativeErrorMapper.map(error)
        guard case .network(let message) = mapped else {
            Issue.record("expected .network, got \(mapped)")
            return
        }
        #expect(!message.contains("client_id"))
        #expect(!message.contains("bb22"))
        #expect(message.contains("\(URLError.notConnectedToInternet.rawValue)"))
    }

    @Test func testMapPlainSwiftErrorStillPrintsItsCase() {
        struct Boom: Error {}
        let mapped = NativeErrorMapper.map(Boom())
        guard case .internalError(let message) = mapped else {
            Issue.record("expected .internalError, got \(mapped)")
            return
        }
        #expect(message.contains("Boom"))
    }
}
