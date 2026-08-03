import Foundation

/// Which operation is currently in flight.
public enum OperationKind: Equatable, Sendable {
    case sendTransaction
    case signData
}

/// The observable send/sign operation state — the status overlay's foundation.
/// Like ConnectionState, but for operations: one enum — incompatible states are inexpressible.
public enum OperationState: Equatable, Sendable {
    case pending(kind: OperationKind)
    case success(kind: OperationKind)
    case walletDeclined(message: String) // neutral tone (orange), no retry
    case networkProblem(message: String) // red, with retry
    /// The request reached the wallet and the wallet refused to carry it out
    /// (a malformed payload, an unsupported method). Red like a network problem,
    /// but WITHOUT a retry: repeating the same request hits the same wall.
    case walletError(message: String)

    /// Maps a thrown engine error into a visual outcome.
    public static func failure(from error: Error) -> OperationState {
        guard let tc = error as? TonConnectError else {
            return .networkProblem(message: String(describing: error))
        }
        switch tc {
        case .walletDeclined(_, let message):
            return .walletDeclined(message: message)
        case .network(let message):
            return .networkProblem(message: message)
        case .internalError(let message):
            return .networkProblem(message: message)
        case .decodeFailure(let message):
            return .networkProblem(message: message)
        case .storageFailure(let status):
            return .networkProblem(message: "storage error (OSStatus \(status))")
        }
    }

    /// Maps a WalletResponse.error (RPC level) — a wallet rejection also arrives this way.
    ///
    /// The spec reserves code 300 for "user declined", but live wallets do not
    /// honour it: Telegram Wallet answers a rejection with code 1 (BAD_REQUEST)
    /// and puts the truth in the message — `{"code":1,"message":"Wallet declined
    /// the request"}` (observed on a live wallet). Trusting the code alone turned a normal
    /// user action into a red "Connection lost" with a Retry button that could
    /// only fail again. Same wire-tolerance rule as everywhere else in the
    /// package: believe the more specific signal the wallet gives us.
    ///
    /// The raw response keeps the code the wallet actually sent — this is the
    /// presentation layer, not the wire DTO.
    public static func failure(fromWalletResponseError code: RPCErrorCode, message: String = "") -> OperationState {
        if code == .userDeclined || readsAsDecline(message) {
            return .walletDeclined(message: message)
        }
        return .walletError(message: message)
    }

    /// Does the wallet's own message say "the user said no"? Substring matching on
    /// purpose: the wording varies between wallets ("Wallet declined the request",
    /// "User rejected", "Canceled by user") and none of them localises it so far.
    /// A false positive costs a neutral "declined" screen instead of a red one —
    /// a false negative costs the user a scary error for pressing Cancel.
    private static func readsAsDecline(_ message: String) -> Bool {
        let text = message.lowercased()
        return ["declin", "reject", "cancel"].contains { text.contains($0) }
    }
}
