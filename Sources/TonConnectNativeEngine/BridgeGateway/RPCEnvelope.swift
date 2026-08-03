import Foundation
import TonConnectCore

/// The bridge protocol's RPC envelope: JSON + base64 + URL assembly ON TOP of the
/// existing SessionCrypto and TonConnectCore DTOs (no type duplication).
/// No crypto and no SSE parsing of its own here (Don't Hand-Roll).
/// The bridge is untrusted: it sees only routing parameters in the query, the body
/// is E2E-encrypted. Plaintext is never logged.
enum RPCEnvelope {

    /// GET {bridgeUrl}/events?client_id=...[&last_event_id=...]
    /// single source of truth: the engine's real call passes lastEventId=nil here —
    /// last_event_id is appended by NativeEventSource.connect() from its init
    /// parameter, NOT by this method. There must not be two appending sites
    /// (or the parameter appears in the URL twice).
    static func eventsURL(bridgeUrl: String, clientId: String, lastEventId: String?) -> String {
        var items = [URLQueryItem(name: "client_id", value: clientId)]
        if let lastEventId, !lastEventId.isEmpty {
            items.append(URLQueryItem(name: "last_event_id", value: lastEventId))
        }
        return build(base: bridgeUrl, path: "events", items: items)
    }

    /// POST {bridgeUrl}/message?client_id=...&to=...&ttl=...[&topic=...]
    /// topic = request.method (spec/bridge.md); ttl is in seconds per spec, default 300.
    static func messageURL(bridgeUrl: String, myClientId: String, to: String,
                           ttl: Int = 300, topic: String?) -> String {
        var items = [
            URLQueryItem(name: "client_id", value: myClientId),
            URLQueryItem(name: "to", value: to),
            URLQueryItem(name: "ttl", value: String(ttl)),
        ]
        if let topic {
            items.append(URLQueryItem(name: "topic", value: topic))
        }
        return build(base: bridgeUrl, path: "message", items: items)
    }

    /// POST /message body: DTO → JSON → encrypt (raw nonce||ciphertext) → base64.
    /// The raw base64 bytes, WITHOUT a {"message":...} JSON wrapper. Standard
    /// RFC4648 alphabet (Data.base64EncodedData == nacl.encodeBase64), NOT base64url.
    static func rpcBody<T: Encodable>(_ request: T, sessionCrypto: SessionCrypto,
                                      walletPublicKey: [UInt8]) throws -> Data {
        let json = try JSONEncoder().encode(request)
        let plaintext = String(decoding: json, as: UTF8.self)
        let cipherBytes = try sessionCrypto.encrypt(plaintext, to: walletPublicKey)
        return Data(cipherBytes).base64EncodedData()
    }

    /// Incoming SSE frame: { "from": "<sender's hex pk>", "message": "<base64>", "trace_id"? }
    /// trace_id is a SHOULD per spec — we do not add it to outgoing frames yet (minimalism).
    struct BridgeMessageEnvelope: Decodable {
        let from: String
        let message: String
        let traceId: String?

        enum CodingKeys: String, CodingKey {
            case from, message
            case traceId = "trace_id"
        }
    }

    /// A decrypted incoming frame + the envelope's sender.
    /// IMPORTANT (SDK parity, bundle.js:4017): the session's walletPublicKey is the
    /// ENVELOPE's from (the wallet's session client_id), NOT the publicKey from the
    /// ton_addr payload (that one is the account key). The engine takes
    /// senderPublicKeyHex from here.
    struct DecodedIncoming {
        let senderPublicKeyHex: String
        let json: String
    }

    /// Envelope → base64-decode → SessionCrypto.decrypt → JSON string + from.
    /// ANY crypto failure is rethrown as-is (forged ciphertext is never
    /// swallowed silently) — NativeErrorMapper maps it into the 3 families.
    static func decodeIncoming(sseData: String, sessionCrypto: SessionCrypto) throws -> DecodedIncoming {
        let envelope = try JSONDecoder().decode(BridgeMessageEnvelope.self, from: Data(sseData.utf8))
        guard let cipherData = decodeBase64Lenient(envelope.message) else {
            throw TonConnectError.decodeFailure("bad base64 in BridgeMessage.message")
        }
        let senderPublicKey = try HexCoding.hexToByteArray(envelope.from)
        let json = try sessionCrypto.decrypt(Array(cipherData), from: senderPublicKey)
        return DecodedIncoming(senderPublicKeyHex: envelope.from, json: json)
    }

    static func decode(sseData: String, sessionCrypto: SessionCrypto) throws -> String {
        try decodeIncoming(sseData: sseData, sessionCrypto: sessionCrypto).json
    }

    /// The registry may list a bridge URL with a trailing slash (e.g. MyTonWallet's
    /// ".../bridge/"): naive joining yields "bridge//events", which that bridge
    /// answers with a 404 (observed on a live wallet). The JS SDK is immune via
    /// new URL('events', base) relative resolution — we normalize the base instead.
    private static func build(base: String, path: String, items: [URLQueryItem]) -> String {
        var normalizedBase = base
        while normalizedBase.hasSuffix("/") { normalizedBase.removeLast() }
        var components = URLComponents(string: "\(normalizedBase)/\(path)")
        components?.queryItems = items
        return components?.string ?? "\(normalizedBase)/\(path)"
    }
    
    /// The spec means standard RFC4648 base64, but wallets vary (style):
    /// the base64url alphabet and missing padding are normalized before decoding.
    private static func decodeBase64Lenient(_ string: String) -> Data? {
        var normalized = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = normalized.count % 4
        if remainder != 0 { normalized += String(repeating: "=", count: 4 - remainder) }
        return Data(base64Encoded: normalized)
    }
}
