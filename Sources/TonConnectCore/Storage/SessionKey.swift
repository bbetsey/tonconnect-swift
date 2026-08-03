import Foundation

/// Session-scoped storage key scheme: "session.<sessionId>.<field>".
/// A single default session exists today; the prefix is present from day one
/// so multi-session support later needs no storage-format migration.
public enum SessionKey {
    public static let defaultSessionId = "default"

    public static func make(sessionId: String, field: String) -> String {
        "session.\(sessionId).\(field)"
    }
}
