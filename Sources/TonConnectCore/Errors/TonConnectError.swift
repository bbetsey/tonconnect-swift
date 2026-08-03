import Foundation

/// Errors leaving the engine — THREE families, the foundation of the UI's outcomes:
/// "the wallet declined" is visually distinct from "a connectivity problem".
public enum TonConnectError: Error, Equatable, Sendable {
    /// Family 1: the wallet deliberately declined (a spec code — spec/rpc.md/connect.md).
    case walletDeclined(code: Int, message: String)
    /// Family 2: a transport/network problem (no connectivity, a URLSession request timeout).
    case network(message: String)
    /// Family 3: an internal/JS error (a bridge bug, ReferenceError, malformed JSON).
    case internalError(message: String)

    // — family 3's internal sub-cases —
    case storageFailure(status: OSStatus)
    case decodeFailure(String)
}

extension TonConnectError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .walletDeclined(let code, let message):
            return "Wallet declined the request (code \(code)): \(message)"
        case .network(let message):
            return "TON Connect network error: \(message)"
        case .internalError(let message):
            return "TON Connect internal error: \(message)"
        case .storageFailure(let status):
            return "TON Connect storage operation failed (OSStatus \(status))"
        case .decodeFailure(let message):
            return "TON Connect decode failure: \(message)"
        }
    }
}
