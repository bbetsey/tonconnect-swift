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
    func load() async throws -> NativeSession? {
        guard let json = try await storage.get(key) else { return nil }
        do {
            return try JSONDecoder().decode(NativeSession.self, from: Data(json.utf8))
        } catch {
            throw TonConnectError.decodeFailure("corrupt native session")
        }
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
        session.nextRpcRequestId = current + 1
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
