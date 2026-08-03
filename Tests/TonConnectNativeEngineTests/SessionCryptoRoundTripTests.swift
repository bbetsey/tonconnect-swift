import Foundation
import JavaScriptCore
import Testing
@testable import TonConnectNativeEngine

// The oracle's Tier 2 : a live Swift↔JS round-trip with random inputs.
//
// The JS loading choice (documented): a bare JSContext + a vendored copy of
// tweetnacl-js 1.0.3 (Fixtures/nacl.js), NOT JSCoreBridge — the bridge needs the
// fetch/SSE/timer polyfills, while the crypto oracle needs only a plain JS engine.
//
// .serialized — belt-and-suspenders; the real protection is the lock in withSource (lesson from).
@Suite(.serialized)
struct SessionCryptoRoundTripTests {

    // MARK: - the JS oracle

    private func makeOracle() throws -> JSContext {
        let context = try #require(JSContext())

        let naclURL = try #require(Bundle.module.url(forResource: "nacl", withExtension: "js"))
        let naclSource = try String(contentsOf: naclURL, encoding: .utf8)

        context.evaluateScript("var self = this;") // nacl.js's UMD wrapper needs self
        context.evaluateScript(naclSource)
        context.evaluateScript("""
        function fromHex(h) {
            var a = new Uint8Array(h.length / 2);
            for (var i = 0; i < a.length; i++) { a[i] = parseInt(h.substr(2 * i, 2), 16); }
            return a;
        }
        function toHex(a) {
            var s = "";
            for (var i = 0; i < a.length; i++) {
                var b = a[i].toString(16);
                if (b.length < 2) b = "0" + b;
                s += b;
            }
            return s;
        }
        function jsPublicKeyFromSecret(skHex) {
            return toHex(nacl.box.keyPair.fromSecretKey(fromHex(skHex)).publicKey);
        }
        function jsOpen(wireHex, senderPkHex, receiverSkHex) {
            var wire = fromHex(wireHex);
            var opened = nacl.box.open(
                wire.subarray(24), wire.subarray(0, 24),
                fromHex(senderPkHex), fromHex(receiverSkHex)
            );
            return opened ? toHex(opened) : null;
        }
        function jsSeal(msgHex, nonceHex, receiverPkHex, senderSkHex) {
            var cipher = nacl.box(
                fromHex(msgHex), fromHex(nonceHex),
                fromHex(receiverPkHex), fromHex(senderSkHex)
            );
            var wire = new Uint8Array(24 + cipher.length);
            wire.set(fromHex(nonceHex), 0);
            wire.set(cipher, 24);
            return toHex(wire);
        }
        """)

        let loaded = context.evaluateScript("typeof nacl.box === 'function'")
        try #require(loaded?.toBool() == true, "tweetnacl failed to load into the JSContext")
        return context
    }

    /// Random bytes straight from the system CSPRNG (bypassing the seam — this is input data, not crypto).
    private func randomBytes(_ count: Int) -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        SecureRandomBytesSource().fill(&bytes, count: count)
        return bytes
    }

    private let messages = [
        "",
        "a",
        "hello TON Connect",
        "привет 🌍 юникод и {\"json\":42}",
        String(repeating: "случайности не случайны ", count: 40),
    ]

    // MARK: - Tier 2 in both directions

    @Test
    func testSwiftEncryptDecryptsInJavaScript() throws {
        let oracle = try makeOracle()

        for message in messages {
            // The JS side: keys from a random secret (fromSecretKey needs no PRNG in JS)
            let jsSecretKey = randomBytes(32)
            let jsPublicKeyHex = try #require(
                oracle.objectForKeyedSubscript("jsPublicKeyFromSecret")
                    .call(withArguments: [HexCoding.toHexString(jsSecretKey)])?.toString()
            )

            // Swift encrypts; the default-entropy path — under the same lock (withSource)
            let (wire, swiftPublicKeyHex) = try RandomBytesBridge.withSource(SecureRandomBytesSource()) {
                let swift = SessionCrypto()
                let wire = try swift.encrypt(message, to: try! HexCoding.hexToByteArray(jsPublicKeyHex))
                return (wire, swift.sessionId)
            }

            // JS opens it
            let openedHex = oracle.objectForKeyedSubscript("jsOpen").call(withArguments: [
                HexCoding.toHexString(wire),
                swiftPublicKeyHex,
                HexCoding.toHexString(jsSecretKey),
            ])

            #expect(openedHex?.isNull != true, "nacl.box.open failed for: \(message.prefix(24))")
            #expect(
                openedHex?.toString() == HexCoding.toHexString(Array(message.utf8)),
                "plaintext mismatch for: \(message.prefix(24))"
            )
        }
    }

    @Test
    func testJavaScriptEncryptDecryptsInSwift() throws {
        let oracle = try makeOracle()

        for message in messages {
            let jsSecretKey = randomBytes(32)
            let jsPublicKeyHex = try #require(
                oracle.objectForKeyedSubscript("jsPublicKeyFromSecret")
                    .call(withArguments: [HexCoding.toHexString(jsSecretKey)])?.toString()
            )
            let nonce = randomBytes(24)

            // The Swift side: the keypair under the lock
            let swift = RandomBytesBridge.withSource(SecureRandomBytesSource()) { SessionCrypto() }

            // JS encrypts for Swift
            let wireHex = try #require(
                oracle.objectForKeyedSubscript("jsSeal").call(withArguments: [
                    HexCoding.toHexString(Array(message.utf8)),
                    HexCoding.toHexString(nonce),
                    swift.sessionId, // hex(pk) — that IS the sessionId
                    HexCoding.toHexString(jsSecretKey),
                ])?.toString()
            )

            // Swift opens it
            let decrypted = try swift.decrypt(
                try HexCoding.hexToByteArray(wireHex),
                from: try HexCoding.hexToByteArray(jsPublicKeyHex)
            )

            #expect(decrypted == message, "decrypt mismatch for: \(message.prefix(24))")
        }
    }
}
