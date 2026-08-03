import Foundation

/// The native engine's own Codable schema for the persistent session:
/// its own keys and format, NOT a reverse of the @tonconnect/sdk storage schema.
/// The nextRpcRequestId/lastWalletEventId counters are PERSISTENT fields
///: id monotonicity must survive a cold restart, or replay/BAD_REQUEST.
struct NativeSession: Codable, Equatable {
    /// Record format version; future schema migrations read this field.
    var schemaVersion: Int = 1
    /// Our keypair from SessionCrypto.stringifyKeypair() — both halves hex.
    let publicKeyHex: String
    let secretKeyHex: String
    /// hex(publicKey) — our client_id for GET /events.
    let sessionId: String
    /// The wallet's client_id ("to" in POST /message); appears after connect.
    var walletPublicKeyHex: String?
    /// The winning bridge (connectUniversal pins the first responder).
    var bridgeUrl: String?
    /// The last SSE frame's id — goes into last_event_id on reconnect.
    var lastEventId: String?
    /// The NEXT outgoing AppRequest id, strictly increasing (spec/rpc.md).
    var nextRpcRequestId: Int = 1
    /// The last seen incoming wallet-event id; ids ≤ this are rejected.
    var lastWalletEventId: Int?
    /// Raw JSON of the successful ConnectEvent — replayed as .connected on restore
    /// (after restore the facade waits for the event from the pump; the
    /// JSCore path received it from the JS SDK). Optional: old-format records
    /// without the field are not restorable as connected — restore throws, the
    /// consumer performs a fresh connect.
    var connectEventJSON: String? = nil
}
