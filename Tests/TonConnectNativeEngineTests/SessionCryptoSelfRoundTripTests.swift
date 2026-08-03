import Testing
@testable import TonConnectNativeEngine

// .serialized — belt-and-suspenders; the real protection from parallel Suites is
// the process-wide lock inside RandomBytesBridge.withSource (lesson from).
@Suite(.serialized)
struct SessionCryptoSelfRoundTripTests {

    @Test
    func testEncryptDecryptRoundTripReturnsOriginalMessage() throws {
        try RandomBytesBridge.withSource(SecureRandomBytesSource()) {
            let alice = SessionCrypto()
            let bob = SessionCrypto()
            let message = "Привет, TON Connect! 🚀 {\"method\":\"sendTransaction\"}"

            let wire = try alice.encrypt(message, to: bob.keyPair.publicKey)
            let decrypted = try bob.decrypt(wire, from: alice.keyPair.publicKey)

            #expect(decrypted == message)
        }
    }

    @Test
    func testEncryptOutputLengthIsNoncePlusCiphertextPlusTag() throws {
        try RandomBytesBridge.withSource(SecureRandomBytesSource()) {
            let alice = SessionCrypto()
            let bob = SessionCrypto()
            let message = "hello"

            let wire = try alice.encrypt(message, to: bob.keyPair.publicKey)

            // nonce(24) + ciphertext(= message length + the Poly1305 seal(16))
            #expect(wire.count == 24 + message.utf8.count + 16)
        }
    }

    @Test
    func testDecryptCorruptedCiphertextThrows() throws {
        try RandomBytesBridge.withSource(SecureRandomBytesSource()) {
            let alice = SessionCrypto()
            let bob = SessionCrypto()

            var wire = try alice.encrypt("secret", to: bob.keyPair.publicKey)
            wire[wire.count - 1] ^= 0xFF // flip the last byte's bits

            #expect(throws: SessionCryptoError.decryptionFailed) {
                _ = try bob.decrypt(wire, from: alice.keyPair.publicKey)
            }
        }
    }

    @Test
    func testDecryptWithWrongSenderKeyThrows() throws {
        try RandomBytesBridge.withSource(SecureRandomBytesSource()) {
            let alice = SessionCrypto()
            let bob = SessionCrypto()
            let mallory = SessionCrypto()

            let wire = try alice.encrypt("secret", to: bob.keyPair.publicKey)

            // Bob believes the letter is from Mallory — the seal won't match
            #expect(throws: SessionCryptoError.decryptionFailed) {
                _ = try bob.decrypt(wire, from: mallory.keyPair.publicKey)
            }
        }
    }

    @Test
    func testDecryptTruncatedMessageThrows() {
        RandomBytesBridge.withSource(SecureRandomBytesSource()) {
            let bob = SessionCrypto()
            let alice = SessionCrypto()
            let tooShort = [UInt8](repeating: 0xAB, count: 23) // shorter than the nonce(24)

            #expect(throws: SessionCryptoError.decryptionFailed) {
                _ = try bob.decrypt(tooShort, from: alice.keyPair.publicKey)
            }
        }
    }

    @Test
    func testSessionIdEqualsHexOfPublicKey() {
        RandomBytesBridge.withSource(SecureRandomBytesSource()) {
            let crypto = SessionCrypto()

            #expect(crypto.sessionId == HexCoding.toHexString(crypto.keyPair.publicKey))
            #expect(crypto.sessionId.count == 64) // 32 bytes × 2 characters

            let stringified = crypto.stringifyKeypair()
            #expect(stringified.publicKey == crypto.sessionId)
            #expect(stringified.secretKey == HexCoding.toHexString(crypto.keyPair.secretKey))
        }
    }
}
