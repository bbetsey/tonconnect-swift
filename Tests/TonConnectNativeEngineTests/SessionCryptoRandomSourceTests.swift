import CTweetNacl
import Testing
@testable import TonConnectNativeEngine

// The short names in tweetnacl.h are #define aliases; Swift sees only the long symbols.
private let cryptoBoxKeypair = crypto_box_curve25519xsalsa20poly1305_tweet_keypair

// .serialized — belt-and-suspenders; the real protection from parallel Suites is
// the process-wide lock inside RandomBytesBridge.withSource (lesson from).
@Suite(.serialized)
struct SessionCryptoRandomSourceTests {

    // criterion #1's fatal path (SecRandomCopyBytes != errSecSuccess → fatalError)
    // is verified by code review, not a death test: a fatalError kills the test process.

    @Test
    func testFixedSourceMakesKeypairDeterministicAcrossCalls() {
        let knownBytes = [UInt8](1...32)

        var pk1 = [UInt8](repeating: 0, count: 32)
        var sk1 = [UInt8](repeating: 0, count: 32)
        var pk2 = [UInt8](repeating: 0, count: 32)
        var sk2 = [UInt8](repeating: 0, count: 32)

        RandomBytesBridge.withSource(FixedBytesSource(bytes: knownBytes)) {
            _ = cryptoBoxKeypair(&pk1, &sk1)
            _ = cryptoBoxKeypair(&pk2, &sk2)
        }

        #expect(pk1 == pk2)
        #expect(sk1 == sk2)
    }

    @Test
    func testFixedSourceCopiesInjectedBytesIntoSecretKey() {
        let knownBytes = [UInt8](1...32)

        var pk = [UInt8](repeating: 0, count: 32)
        var sk = [UInt8](repeating: 0, count: 32)

        RandomBytesBridge.withSource(FixedBytesSource(bytes: knownBytes)) {
            _ = cryptoBoxKeypair(&pk, &sk)
        }

        // tweetnacl copies the raw random bytes into the secret key as-is
        #expect(sk == knownBytes)
    }

    @Test
    func testSecureRandomSourceProducesDistinctKeypairs() {
        var pk1 = [UInt8](repeating: 0, count: 32)
        var sk1 = [UInt8](repeating: 0, count: 32)
        var pk2 = [UInt8](repeating: 0, count: 32)
        var sk2 = [UInt8](repeating: 0, count: 32)

        // withSource for the production source too: the call holds the same lock
        // and cannot observe a foreign FixedBytesSource from a parallel Suite.
        RandomBytesBridge.withSource(SecureRandomBytesSource()) {
            _ = cryptoBoxKeypair(&pk1, &sk1)
            _ = cryptoBoxKeypair(&pk2, &sk2)
        }

        #expect(pk1 != pk2)
        #expect(sk1 != sk2)
    }
}
