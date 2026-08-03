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
}
