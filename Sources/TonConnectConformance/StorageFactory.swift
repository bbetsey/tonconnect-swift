import Foundation
import TonConnectCore

/// Factory seam for storage backends: the same suite must pass for
/// every TonConnectStorage implementation.
public protocol StorageFactory: Sendable {
    func makeStorage() async throws -> any TonConnectStorage
    var label: String { get }
}
