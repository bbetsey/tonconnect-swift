import Foundation

/// Actor-backed in-memory TonConnectStorage — for tests and previews.
/// Second subject of the storage-parity conformance suite.
public actor InMemoryStorage: TonConnectStorage {
    private var storage: [String: String] = [:]

    public init() {}

    public func get(_ key: String) async throws -> String? {
        storage[key]
    }

    public func set(_ value: String, forKey key: String) async throws {
        storage[key] = value
    }

    public func remove(_ key: String) async throws {
        storage[key] = nil
    }
}
