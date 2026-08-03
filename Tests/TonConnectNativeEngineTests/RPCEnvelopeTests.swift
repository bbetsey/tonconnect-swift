import Foundation
import Testing
import TonConnectCore
@testable import TonConnectNativeEngine

@Suite struct RPCEnvelopeTests {

    // MARK: - URL assembly

    @Test func testEventsURLOmitsLastEventIDWhenNil() {
        let url = RPCEnvelope.eventsURL(bridgeUrl: "https://b/bridge", clientId: "aa", lastEventId: nil)
        #expect(url == "https://b/bridge/events?client_id=aa")
    }

    @Test func testEventsURLAppendsLastEventIDWhenProvided() {
        let url = RPCEnvelope.eventsURL(bridgeUrl: "https://b/bridge", clientId: "aa", lastEventId: "17")
        #expect(url == "https://b/bridge/events?client_id=aa&last_event_id=17")
    }

    @Test func testMessageURLContainsClientIDToTTLTopic() {
        let url = RPCEnvelope.messageURL(bridgeUrl: "https://b/bridge", myClientId: "aa",
                                         to: "bb", topic: "sendTransaction")
        #expect(url.hasPrefix("https://b/bridge/message?"))
        #expect(url.contains("client_id=aa"))
        #expect(url.contains("to=bb"))
        #expect(url.contains("ttl=300"))
        #expect(url.contains("topic=sendTransaction"))
    }

    // MARK: - outgoing body

    @Test func testRPCBodyRoundTripsThroughRealNaClBox() throws {
        let alice = SessionCrypto() // dApp
        let bob = SessionCrypto() // the "wallet"
        let request = AppRequest(method: "sendTransaction", params: ["{}"], id: "1")

        let body = try RPCEnvelope.rpcBody(request, sessionCrypto: alice,
                                           walletPublicKey: bob.keyPair.publicKey)

        // Bob's side: base64-decode → decrypt → JSON → AppRequest
        let cipherData = try #require(Data(base64Encoded: body))
        let json = try bob.decrypt(Array(cipherData), from: alice.keyPair.publicKey)
        let decoded = try JSONDecoder().decode(AppRequest.self, from: Data(json.utf8))
        #expect(decoded == request)
    }

    @Test func testRPCBodyIsBase64OfRawNoncePlusCiphertext() throws {
        let alice = SessionCrypto()
        let bob = SessionCrypto()
        let request = AppRequest(method: "sendTransaction", params: ["{}"], id: "1")
        let plaintextLength = try JSONEncoder().encode(request).count

        let body = try RPCEnvelope.rpcBody(request, sessionCrypto: alice,
                                           walletPublicKey: bob.keyPair.publicKey)

        // raw nonce(24)||ciphertext(len+16), NOT a {"message":...} JSON wrapper
        let raw = try #require(Data(base64Encoded: body))
        #expect(raw.count == 24 + plaintextLength + 16)
        #expect(raw.first != UInt8(ascii: "{"))
    }

    // MARK: - incoming envelope

    private func makeEnvelopeJSON(from senderHex: String, messageBase64: String) -> String {
        #"{"from":"\#(senderHex)","message":"\#(messageBase64)","trace_id":"t-1"}"#
    }

    @Test func testDecodeRoundTripsIncomingBridgeMessage() throws {
        let alice = SessionCrypto()
        let bob = SessionCrypto()
        let walletJSON = #"{"result":"ok","id":"1"}"#
        let cipher = try bob.encrypt(walletJSON, to: alice.keyPair.publicKey)
        let sseData = makeEnvelopeJSON(
            from: HexCoding.toHexString(bob.keyPair.publicKey),
            messageBase64: Data(cipher).base64EncodedString()
        )

        let decoded = try RPCEnvelope.decode(sseData: sseData, sessionCrypto: alice)
        #expect(decoded == walletJSON)
    }

    @Test func testDecodeWithBrokenBase64ThrowsDecodeFailure() throws {
        let alice = SessionCrypto()
        let sseData = makeEnvelopeJSON(
            from: HexCoding.toHexString(alice.keyPair.publicKey),
            messageBase64: "%%%not-base64%%%"
        )
        #expect(throws: TonConnectError.decodeFailure("bad base64 in BridgeMessage.message")) {
            _ = try RPCEnvelope.decode(sseData: sseData, sessionCrypto: alice)
        }
    }

    @Test func testDecodeRejectsTamperedCiphertextByThrowing() throws {
        let alice = SessionCrypto()
        let bob = SessionCrypto()
        var cipher = try bob.encrypt(#"{"result":"ok","id":"1"}"#, to: alice.keyPair.publicKey)
        cipher[cipher.count - 1] ^= 0xFF // break the seal: flip a byte
        let sseData = makeEnvelopeJSON(
            from: HexCoding.toHexString(bob.keyPair.publicKey),
            messageBase64: Data(cipher).base64EncodedString()
        )
        #expect(throws: SessionCryptoError.decryptionFailed) {
            _ = try RPCEnvelope.decode(sseData: sseData, sessionCrypto: alice)
        }
    }
    
    @Test func testURLBuildersNormalizeTrailingSlashInBridgeURL() {
        let events = RPCEnvelope.eventsURL(bridgeUrl: "https://bridge.example/bridge/",
                                           clientId: "abc", lastEventId: nil)
        #expect(events.hasPrefix("https://bridge.example/bridge/events?"))
        #expect(!events.contains("//events"))
        let message = RPCEnvelope.messageURL(bridgeUrl: "https://bridge.example/bridge/",
                                             myClientId: "abc", to: "def", topic: nil)
        #expect(message.hasPrefix("https://bridge.example/bridge/message?"))
        #expect(!message.contains("//message"))
    }
    
    @Test func testDecodeIncomingAcceptsBase64URLWithoutPadding() throws {
        let alice = SessionCrypto()
        let bob = SessionCrypto()
        let cipher = try bob.encrypt("{\"probe\":1}", to: alice.keyPair.publicKey)
        // Re-encode the same bytes as base64url without padding — a wallet dialect.
        let urlSafe = Data(cipher).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "="))
        let frame = "{\"from\":\"\(HexCoding.toHexString(bob.keyPair.publicKey))\",\"message\":\"\(urlSafe)\"}"
        let decoded = try RPCEnvelope.decodeIncoming(sseData: frame, sessionCrypto: alice)
        #expect(decoded.json == "{\"probe\":1}")
    }
}
