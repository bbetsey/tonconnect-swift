import Foundation

/// The return strategy from the wallet (TON Connect spec, the ret parameter):
/// where the wallet should send the user after approval/rejection.
/// On iOS 'back' is unreliable (universal-link limitations) — native apps are
/// recommended to use their own URL (a custom scheme, e.g. "myapp://").
public enum ReturnStrategy: Equatable, Sendable {
    case back
    case none
    case url(String)

    public var queryValue: String {
        switch self {
        case .back: return "back"
        case .none: return "none"
        case .url(let url): return url
        }
    }
}
