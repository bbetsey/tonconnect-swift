import Foundation

/// Errors leaving the engine — THREE families, the foundation of the UI's outcomes:
/// "the wallet declined" is visually distinct from "a connectivity problem".
public enum TonConnectError: Error, Equatable, Sendable {
    /// Family 1: the wallet deliberately declined (a spec code — spec/rpc.md/connect.md).
    case walletDeclined(code: Int, message: String)
    /// Family 2: a transport/network problem (no connectivity, a URLSession request timeout).
    case network(message: String)
    /// Family 2 as well, but by the caller's own clock: the wallet did not answer
    /// within the `timeout:` handed to the facade, and the request was cancelled.
    /// Distinct from ``network(message:)`` so an app can word it differently —
    /// "the wallet is not responding" rather than "check your connection".
    case timeout(after: Duration)
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
        case .timeout(let duration):
            return "TON Connect request timed out after \(Self.seconds(in: duration))s"
        case .internalError(let message):
            return "TON Connect internal error: \(message)"
        case .storageFailure(let status):
            return "TON Connect storage operation failed (OSStatus \(status))"
        case .decodeFailure(let message):
            return "TON Connect decode failure: \(message)"
        }
    }

    /// `Duration` prints as attoseconds by default — "90.0 seconds" is what a
    /// log reader wants. Whole seconds stay whole ("90"), fractions keep up to
    /// three decimals ("0.25").
    private static func seconds(in duration: Duration) -> String {
        let (seconds, attoseconds) = duration.components
        let total = Double(seconds) + Double(attoseconds) / 1e18
        if total == total.rounded() { return String(Int(total)) }
        return String((total * 1000).rounded() / 1000)
    }
}
