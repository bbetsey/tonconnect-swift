import Foundation
import TonConnectCore

/// A thin typed wrapper over TonConnectStorage: the session is stored as ONE JSON
/// blob under its own versioned key. In production storage = Keychain;
/// secretKeyHex is never logged.
struct NativeSessionStore {
    private let storage: any TonConnectStorage
    private let sessionId: String

    init(storage: any TonConnectStorage, sessionId: String = SessionKey.defaultSessionId) {
        self.storage = storage
        self.sessionId = sessionId
    }

    /// Our own key; the schema version is right in the field name — NOT the @tonconnect/sdk keys.
    private var key: String { SessionKey.make(sessionId: sessionId, field: "native.v1") }

    /// nil = no session (not an error); corrupt JSON = decodeFailure (not a silent nil).
    ///
    /// A record that parses is not yet a record we can run on: the storage is
    /// shared with whatever else the app puts there, and a consumer may supply
    /// its own `TonConnectStorage`. A future schema version, a counter outside
    /// its range (the RPC id must stay incrementable — `Int.max` trapped on the
    /// first request, at every launch, with no way out short of a new connect)
    /// are refused here as `decodeFailure`, the contract for a corrupt record.
    func load() async throws -> NativeSession? {
        guard let json = try await storage.get(key) else { return nil }
        let session: NativeSession
        do {
            session = try JSONDecoder().decode(NativeSession.self, from: Data(json.utf8))
        } catch {
            throw TonConnectError.decodeFailure("corrupt native session")
        }
        guard session.schemaVersion == 1 else {
            throw TonConnectError.decodeFailure("native session schema \(session.schemaVersion) is not supported")
        }
        guard (1..<Int.max).contains(session.nextRpcRequestId),
              (session.lastWalletEventId ?? 0) >= 0 else {
            throw TonConnectError.decodeFailure("native session counters out of range")
        }
        return session
    }

    func save(_ session: NativeSession) async throws {
        let data = try JSONEncoder().encode(session)
        try await storage.set(String(decoding: data, as: UTF8.self), forKey: key)
    }

    /// Removes ONLY our own native key; foreign records (JS SDK) are left alone.
    func clear() async throws {
        try await storage.remove(key)
    }

    /// Returns the id for an outgoing AppRequest and persists the increment BEFORE
    /// returning: if the app dies right after a send, the next launch continues
    /// the sequence.
    func incrementNextRpcRequestId() async throws -> Int {
        guard var session = try await load() else {
            throw TonConnectError.internalError(message: "no native session for rpc id")
        }
        let current = session.nextRpcRequestId
        let (next, overflow) = current.addingReportingOverflow(1)
        guard !overflow else { // load() refuses Int.max already; belt and braces
            throw TonConnectError.internalError(message: "rpc request id counter exhausted")
        }
        session.nextRpcRequestId = next
        try await save(session)
        return current
    }

    /// A targeted re-persist on EVERY incoming SSE frame carrying an id (W2: replay
    /// protection must survive a cold restart, not just the first connect). No session → no-op.
    func updateLastEventId(_ id: String) async throws {
        guard var session = try await load() else { return }
        session.lastEventId = id
        try await save(session)
    }

    /// Symmetrically: on every VALID wallet event after the monotonicity check.
    func updateLastWalletEventId(_ id: Int) async throws {
        guard var session = try await load() else { return }
        session.lastWalletEventId = id
        try await save(session)
    }
}
