import CTweetNacl
import Foundation
import Testing
@testable import TonConnectNativeEngine

// .serialized — belt-and-suspenders; the real protection from parallel Suites is
// the process-wide lock inside RandomBytesBridge.withSource (lesson from).
@Suite(.serialized)
struct SessionCryptoVectorTests {

    // MARK: - the vector file format (mirrors generate-vectors.mjs)

    struct Vectors: Codable {
        let protocolVersion: String
        let keypairs: [KeypairVector]
        let encryptCases: [EncryptCase]
        let decryptFailureCases: [DecryptFailureCase]
    }

    struct KeypairVector: Codable {
        let seed: String
        let publicKey: String
        let secretKey: String
    }

    struct EncryptCase: Codable {
        let senderSecretKey: String
        let receiverPublicKey: String
        let nonce: String
        let plaintext: String
        let expectedWire: String
    }

    struct DecryptFailureCase: Codable {
        let description: String
        let wireHex: String
        let senderPublicKey: String
        let receiverSecretKey: String
        let expectThrow: Bool
    }

    // MARK: - Helpers

    private func loadVectors() throws -> Vectors {
        let url = try #require(
            Bundle.module.url(forResource: "session-crypto-vectors", withExtension: "json")
        )
        return try JSONDecoder().decode(Vectors.self, from: Data(contentsOf: url))
    }

    /// pk is derived from sk by the same operation as nacl.box.keyPair.fromSecretKey.
    private func sessionCrypto(secretKeyHex: String) throws -> SessionCrypto {
        let secretKey = try HexCoding.hexToByteArray(secretKeyHex)
        var publicKey = [UInt8](repeating: 0, count: 32)
        _ = crypto_scalarmult_curve25519_tweet_base(&publicKey, secretKey)
        return try SessionCrypto(keyPair: (
            publicKey: HexCoding.toHexString(publicKey),
            secretKey: secretKeyHex
        ))
    }

    // MARK: - Tier 1: byte-for-byte against the oracle

    @Test
    func testEncryptCasesMatchOracleWireByteForByte() throws {
        let vectors = try loadVectors()

        for encryptCase in vectors.encryptCases {
            let crypto = try sessionCrypto(secretKeyHex: encryptCase.senderSecretKey)
            let receiverPublicKey = try HexCoding.hexToByteArray(encryptCase.receiverPublicKey)
            let nonce = try HexCoding.hexToByteArray(encryptCase.nonce)

            // A deterministic nonce — ONLY via withSource (cross-cutting constraint)
            let wire = try RandomBytesBridge.withSource(FixedBytesSource(bytes: nonce)) {
                try crypto.encrypt(encryptCase.plaintext, to: receiverPublicKey)
            }

            #expect(
                HexCoding.toHexString(wire) == encryptCase.expectedWire,
                "wire mismatch for plaintext: \(encryptCase.plaintext.prefix(32))"
            )
        }
    }

    @Test
    func testKeypairDerivationMatchesOracle() throws {
        let vectors = try loadVectors()

        for keypairVector in vectors.keypairs {
            let seed = try HexCoding.hexToByteArray(keypairVector.seed)
            var publicKey = [UInt8](repeating: 0, count: 32)
            _ = crypto_scalarmult_curve25519_tweet_base(&publicKey, seed)

            #expect(HexCoding.toHexString(publicKey) == keypairVector.publicKey)
            #expect(keypairVector.secretKey == keypairVector.seed) // fromSecretKey: sk == seed
        }
    }

    @Test
    func testDecryptFailureCasesThrow() throws {
        let vectors = try loadVectors()

        for failureCase in vectors.decryptFailureCases {
            let crypto = try sessionCrypto(secretKeyHex: failureCase.receiverSecretKey)
            let senderPublicKey = try HexCoding.hexToByteArray(failureCase.senderPublicKey)
            let wire = try HexCoding.hexToByteArray(failureCase.wireHex)

            #expect(throws: (any Error).self, "\(failureCase.description)") {
                _ = try crypto.decrypt(wire, from: senderPublicKey)
            }
        }
    }

    @Test
    func testSessionIdMatchesHexOfPublicKey() throws {
        let vectors = try loadVectors()
        let keypairVector = try #require(vectors.keypairs.first)

        let crypto = try sessionCrypto(secretKeyHex: keypairVector.secretKey)

        #expect(crypto.sessionId == keypairVector.publicKey) // sessionId = the oracle's hex(pk)
    }
}
