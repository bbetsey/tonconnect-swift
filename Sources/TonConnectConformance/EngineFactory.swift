import Foundation
import TonConnectCore

/// Factory seam: each engine's test target supplies its own factory
/// and runs the identical conformance suite — no suite edits required.
public protocol EngineFactory: Sendable {
    func makeEngine() async throws -> any TonConnectEngine
    var label: String { get }
}
