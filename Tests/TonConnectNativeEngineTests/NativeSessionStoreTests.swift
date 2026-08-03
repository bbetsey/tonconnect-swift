import Foundation
import Testing
import TonConnectCore
@testable import TonConnectNativeEngine

@Suite struct NativeSessionStoreTests {

    private func makeSession() -> NativeSession {
        NativeSession(
            publicKeyHex: "aa11",
            secretKeyHex: "bb22",
            sessionId: "aa11",
            walletPublicKeyHex: "cc33",
            bridgeUrl: "https://bridge.example.com/bridge",
            lastEventId: "42",
            nextRpcRequestId: 7,
            lastWalletEventId: 3
        )
    }

    // MARK: - happy path

    @Test func testColdRestartPreservesAllFieldsIncludingCounters() async throws {
        let storage = InMemoryStorage()
        let session = makeSession()
        try await NativeSessionStore(storage: storage).save(session)
        // a "restart" — a new store over the same storage
        let reloaded = try await NativeSessionStore(storage: storage).load()
        #expect(reloaded == session)
    }

    @Test func testLoadOnEmptyStorageReturnsNil() async throws {
        let store = NativeSessionStore(storage: InMemoryStorage())
        let loaded = try await store.load()
        #expect(loaded == nil)
    }

    @Test func testIncrementNextRPCRequestIDSurvivesReload() async throws {
        let storage = InMemoryStorage()
        try await NativeSessionStore(storage: storage).save(makeSession())
        let store = NativeSessionStore(storage: storage)
        let first = try await store.incrementNextRpcRequestId()
        let second = try await store.incrementNextRpcRequestId()
        #expect(first == 7)
        #expect(second == 8)
        // cold restart: the next id continues the sequence, does NOT reset 
        let afterRestart = try await NativeSessionStore(storage: storage).incrementNextRpcRequestId()
        #expect(afterRestart == 9)
    }

    @Test func testRoundTripPreservesNilVersusFilledLastEventID() async throws {
        let storage = InMemoryStorage()
        let store = NativeSessionStore(storage: storage)

        var session = makeSession()
        session.lastEventId = nil
        try await store.save(session)
        let reloadedNil = try await store.load()
        #expect(reloadedNil?.lastEventId == nil)

        session.lastEventId = "42"
        try await store.save(session)
        let reloadedFilled = try await store.load()
        #expect(reloadedFilled?.lastEventId == "42")
    }

    @Test func testUpdateLastEventIDAndWalletEventIDTouchOnlyTheirFields() async throws {
        let storage = InMemoryStorage()
        let store = NativeSessionStore(storage: storage)
        try await store.save(makeSession())

        try await store.updateLastEventId("100")
        try await store.updateLastWalletEventId(5)

        // a "restart": the updated values read back, the other fields untouched
        let reloaded = try await NativeSessionStore(storage: storage).load()
        var expected = makeSession()
        expected.lastEventId = "100"
        expected.lastWalletEventId = 5
        #expect(reloaded == expected)
    }

    // MARK: - error paths

    @Test func testClearRemovesOnlyNativeKeyLeavingForeignUntouched() async throws {
        let storage = InMemoryStorage()
        let foreignKey = "session.default.bridge_connection"
        try await storage.set("{\"js\":\"sdk\"}", forKey: foreignKey)

        let store = NativeSessionStore(storage: storage)
        try await store.save(makeSession())
        try await store.clear()

        let loaded = try await store.load()
        #expect(loaded == nil)
        let foreign = try await storage.get(foreignKey)
        #expect(foreign == "{\"js\":\"sdk\"}") // the foreign JS record survives 
    }

    @Test func testLoadWithCorruptJSONThrowsDecodeFailure() async throws {
        let storage = InMemoryStorage()
        try await storage.set("not json", forKey: "session.default.native.v1")
        let store = NativeSessionStore(storage: storage)
        await #expect(throws: TonConnectError.decodeFailure("corrupt native session")) {
            _ = try await store.load()
        }
    }
}
