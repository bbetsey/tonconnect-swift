import Foundation
import TonConnectCore

/// Translates errors at the JSCoreEngine boundary into the three TonConnectError
/// families. Rules:
///  - a wallet rejection with a spec code (userDeclined=300 et al.) → .walletDeclined
///  - a transport/URLSession error (network, request timeout) → .network
///  - everything else (ReferenceError, JSBridgeError, corrupt JSON) → .internalError
/// Never lets a JSBridgeError/JSValue/raw string escape.
enum EngineErrorMapper {
    static func map(_ error: Error) -> TonConnectError {
        if let tonConnectError = error as? TonConnectError { return tonConnectError } // already typed
        if let jsError = error as? JSBridgeError { return classifyMessage(message(from: jsError)) }
        if error is URLError { return .network(message: String(describing: error)) }
        return .internalError(message: String(describing: error))
    }

    /// A separate entry point for a wallet reply with a code (from WalletResponse.error/ConnectEvent.error).
    static func walletDeclined(code: Int, message: String) -> TonConnectError {
        .walletDeclined(code: code, message: message)
    }

    /// The {kind:'error'} event from the pump arrives as a String(error) from JS —
    /// classify by text. A user rejection: the SDK throws UserRejectsError
    /// ("User rejects...") — that is the spec's connect_error code 300.
    static func classifyMessage(_ message: String) -> TonConnectError {
        if message.range(of: #"(?i)user reject"#, options: .regularExpression) != nil {
            return .walletDeclined(code: 300, message: message)
        }
        if message.range(of: #"(?i)network|timeout|fetch|bridge send failed"#, options: .regularExpression) != nil {
            return .network(message: message)
        }
        return .internalError(message: message)
    }

    private static func message(from jsError: JSBridgeError) -> String {
        switch jsError {
        case .jsException(let message): return message
        case .bundleLoadFailed(let message): return "bundle load failed: \(message)"
        case .notAPromise: return "expected a JS Promise"
        case .contextUnavailable: return "JSContext unavailable"
        case .promiseCollected: return "promise was garbage-collected before settling"
        }
    }
}
