import Foundation
import Testing
import TonConnectCore

/// Reusable storage conformance suite: the same
/// assertions must pass for every TonConnectStorage backend. Each runner cleans
/// up its keys — Keychain items outlive the test process on a host Mac.
public enum StorageConformanceSuite {

    public static func runAll(factory: any StorageFactory) async throws {
        try await runSetThenGetReturnsStoredValue(factory: factory)
        try await runOverwriteReplacesPreviousValue(factory: factory)
        try await runRemoveThenGetReturnsNil(factory: factory)
        try await runGetOnNeverSetKeyReturnsNil(factory: factory)
        try await runSessionScopedKeyRoundTrips(factory: factory)
    }

    public static func runSetThenGetReturnsStoredValue(factory: any StorageFactory) async throws {
        let storage = try await factory.makeStorage()
        let key = "conformance.set-get"
        try await storage.set("value-1", forKey: key)
        let got = try await storage.get(key)
        #expect(got == "value-1", "[\(factory.label)]")
        try await storage.remove(key)
    }

    public static func runOverwriteReplacesPreviousValue(factory: any StorageFactory) async throws {
        let storage = try await factory.makeStorage()
        let key = "conformance.overwrite"
        try await storage.set("first", forKey: key)
        try await storage.set("second", forKey: key)
        let got = try await storage.get(key)
        #expect(got == "second", "[\(factory.label)] set on existing key must overwrite")
        try await storage.remove(key)
    }

    public static func runRemoveThenGetReturnsNil(factory: any StorageFactory) async throws {
        let storage = try await factory.makeStorage()
        let key = "conformance.remove"
        try await storage.set("gone", forKey: key)
        try await storage.remove(key)
        let got = try await storage.get(key)
        #expect(got == nil, "[\(factory.label)]")
    }

    public static func runGetOnNeverSetKeyReturnsNil(factory: any StorageFactory) async throws {
        let storage = try await factory.makeStorage()
        let got = try await storage.get("conformance.never-set")
        #expect(got == nil, "[\(factory.label)] missing key must be nil, not an error")
    }

    public static func runSessionScopedKeyRoundTrips(factory: any StorageFactory) async throws {
        let storage = try await factory.makeStorage()
        let key = SessionKey.make(sessionId: SessionKey.defaultSessionId, field: "lastEventId")
        try await storage.set("42", forKey: key)
        let got = try await storage.get(key)
        #expect(got == "42", "[\(factory.label)] a session-scoped key must round-trip")
        try await storage.remove(key)
    }
}
