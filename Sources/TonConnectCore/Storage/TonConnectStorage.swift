import Foundation

/// String key-value storage abstraction for TON Connect session material.
/// Shape mirrors the JS SDK IStorage interface — same three ops,
/// so the JSCore engine can bridge it without an adapter.
public protocol TonConnectStorage: Sendable {
    func get(_ key: String) async throws -> String?
    func set(_ value: String, forKey key: String) async throws
    func remove(_ key: String) async throws
}
