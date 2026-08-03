import CTweetNacl
import Foundation

/// Decryption error. Internal; mapping onto the TonConnectError families happens at the engine boundary.
enum SessionCryptoError: Error, Equatable, Sendable {
    case decryptionFailed
    case invalidKeyLength(expected: Int, actual: Int)
}

/// A byte-for-byte port of the JS SessionCrypto class from @tonconnect/protocol@3.0.0.
/// Wire format: nonce(24) || ciphertext, raw bytes (text encoding is the bridge layer).
/// Everything internal.
struct SessionCrypto {

    let keyPair: (publicKey: [UInt8], secretKey: [UInt8])
    let sessionId: String
    let nonceLength = 24

    // crypto_box_ZEROBYTES / crypto_box_BOXZEROBYTES from tweetnacl.h
    private static let zeroBytes = 32
    private static let boxZeroBytes = 16

    /// A fresh keypair; entropy comes from the randombytes seam (01).
    init() {
        _ = RandomBytesBridge.bootstrap
        var publicKey = [UInt8](repeating: 0, count: 32)
        var secretKey = [UInt8](repeating: 0, count: 32)
        _ = crypto_box_curve25519xsalsa20poly1305_tweet_keypair(&publicKey, &secretKey)
        self.keyPair = (publicKey, secretKey)
        self.sessionId = HexCoding.toHexString(publicKey) // like the oracle — in the constructor
    }

    /// Restore from stringifyKeypair (oracle: createKeypairFromString stores BOTH halves as hex strings).
    init(keyPair: (publicKey: String, secretKey: String)) throws {
        let publicKey = try HexCoding.hexToByteArray(keyPair.publicKey)
        let secretKey = try HexCoding.hexToByteArray(keyPair.secretKey)
        self.keyPair = (try Self.validated32(publicKey), try Self.validated32(secretKey))
        self.sessionId = HexCoding.toHexString(publicKey)
    }
    
    private static func validated32(_ key: [UInt8]) throws -> [UInt8] {
        guard key.count == 32 else {
            throw SessionCryptoError.invalidKeyLength(expected: 32, actual: key.count)
        }
        return key
    }

    /// UTF-8 → nonce(24 random bytes from the seam) || ciphertext. Raw bytes.
    func encrypt(_ message: String, to receiverPublicKey: [UInt8]) throws -> [UInt8] {
        let receiverPublicKey = try Self.validated32(receiverPublicKey)
        _ = RandomBytesBridge.bootstrap
        let encodedMessage = Array(message.utf8)
        var nonce = [UInt8](repeating: 0, count: nonceLength)
        randombytes(&nonce, UInt64(nonceLength)) // the same seam as the keypair
        let ciphertext = Self.cryptoBoxSeal(
            encodedMessage,
            nonce: nonce,
            receiverPublicKey: receiverPublicKey,
            senderSecretKey: keyPair.secretKey
        )
        return nonce + ciphertext
    }

    /// First 24 bytes are the nonce; any open failure → throw (never silent).
    func decrypt(_ message: [UInt8], from senderPublicKey: [UInt8]) throws -> String {
        let senderPublicKey = try Self.validated32(senderPublicKey)
        guard message.count >= nonceLength else {
            throw SessionCryptoError.decryptionFailed // truncated message
        }
        let nonce = Array(message[..<nonceLength])
        let ciphertext = Array(message[nonceLength...])
        let plaintext = try Self.cryptoBoxOpen(
            ciphertext,
            nonce: nonce,
            senderPublicKey: senderPublicKey,
            receiverSecretKey: keyPair.secretKey
        )
        return String(decoding: plaintext, as: UTF8.self)
    }

    func stringifyKeypair() -> (publicKey: String, secretKey: String) {
        (HexCoding.toHexString(keyPair.publicKey), HexCoding.toHexString(keyPair.secretKey))
    }

    // MARK: - crypto_box helpers: ALL zero-padding lives here and only here

    /// message → 32 leading zeros → crypto_box → strip 16 output zeros = ciphertext.
    private static func cryptoBoxSeal(
        _ message: [UInt8],
        nonce: [UInt8],
        receiverPublicKey: [UInt8],
        senderSecretKey: [UInt8]
    ) -> [UInt8] {
        let padded = [UInt8](repeating: 0, count: zeroBytes) + message
        var out = [UInt8](repeating: 0, count: padded.count)
        _ = crypto_box_curve25519xsalsa20poly1305_tweet(
            &out, padded, UInt64(padded.count), nonce, receiverPublicKey, senderSecretKey
        )
        return Array(out[boxZeroBytes...])
    }

    /// ciphertext → 16 leading zeros → crypto_box_open → non-zero code = throw → strip 32 zeros = plaintext.
    private static func cryptoBoxOpen(
        _ ciphertext: [UInt8],
        nonce: [UInt8],
        senderPublicKey: [UInt8],
        receiverSecretKey: [UInt8]
    ) throws -> [UInt8] {
        let padded = [UInt8](repeating: 0, count: boxZeroBytes) + ciphertext
        var out = [UInt8](repeating: 0, count: padded.count)
        let result = crypto_box_curve25519xsalsa20poly1305_tweet_open(
            &out, padded, UInt64(padded.count), nonce, senderPublicKey, receiverSecretKey
        )
        guard result == 0 else {
            throw SessionCryptoError.decryptionFailed
        }
        return Array(out[zeroBytes...])
    }
}
