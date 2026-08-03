import Testing
import TonConnectCore

struct InMemoryStorageSmokeTests {

    @Test func testInMemoryStorageSetThenGetReturnsStoredValue() async throws {
        let storage = InMemoryStorage()
        try await storage.set("v", forKey: "k")
        #expect(try await storage.get("k") == "v")
    }

    @Test func testInMemoryStorageRemoveThenGetReturnsNil() async throws {
        let storage = InMemoryStorage()
        try await storage.set("v", forKey: "k")
        try await storage.remove("k")
        #expect(try await storage.get("k") == nil)
    }

    @Test func testInMemoryStorageGetOnNeverSetKeyReturnsNil() async throws {
        let storage = InMemoryStorage()
        #expect(try await storage.get("never-set") == nil)
    }

    @Test func testSessionKeyMakeProducesScopedKey() {
        #expect(SessionKey.make(sessionId: "default", field: "lastEventId") == "session.default.lastEventId")
    }
}
