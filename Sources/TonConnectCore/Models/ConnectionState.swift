import Foundation

/// The observable connection state. One enum — not a set of booleans, so
/// "connecting and connected at once" is inexpressible. The @tonconnect/ui
/// pattern: the facade passes through .restoring at startup.
public enum ConnectionState: Equatable, Sendable {
    case disconnected
    case restoring
    case connecting
    case connected(Account)

    /// Computed shortcuts (permissible on top of the enum).
    public var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
    public var account: Account? {
        if case .connected(let account) = self { return account }
        return nil
    }
}
