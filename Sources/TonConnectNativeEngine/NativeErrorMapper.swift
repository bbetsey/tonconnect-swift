import Foundation
import TonConnectCore

/// Translates errors at the NativeEngine boundary into the three TonConnectError
/// families. Rules (modeled on JSCoreEngine's EngineErrorMapper, but
/// WITHOUT the JS specifics):
///  - a crypto failure (SessionCryptoError) → .internalError
///  - a transport/URLSession error (network, timeout) → .network
///  - everything else (DecodingError, corrupt JSON) → .internalError
/// Never lets SessionCryptoError/URLError/DecodingError/a raw string escape.
///
/// A wallet rejection is SIMPLER here than in the JS counterpart: there it is
/// regex-sniffing of the exception text, here WalletResponse.error already
/// carries a typed RPCErrorCode — the engine maps by code via
/// walletDeclined(code:message:), no string parsing.
enum NativeErrorMapper {
    static func map(_ error: Error) -> TonConnectError {
        if let tonConnectError = error as? TonConnectError { return tonConnectError } // already typed
        if let cryptoError = error as? SessionCryptoError {
            return .internalError(message: "session crypto: \(cryptoError)")
        }
        if let urlError = error as? URLError { return .network(message: describe(urlError)) }
        return .internalError(message: describe(error))
    }

    /// The message without the NSError dump. `String(describing:)` on a URLError
    /// prints its userInfo, and that carries the failing URL — for a bridge POST
    /// that is the session's client_id, the wallet's key, the bridge host — into
    /// whatever the host app does with an error's text: its UI, its analytics.
    /// The code and the localized description say what went wrong; the rest is
    /// the engine's business.
    static func describe(_ error: Error) -> String {
        if let urlError = error as? URLError {
            return "URLError \(urlError.code.rawValue): \(urlError.localizedDescription)"
        }
        let nsError = error as NSError
        if nsError.userInfo.isEmpty { return String(describing: error) } // a plain Swift error prints its case
        return "\(nsError.domain) \(nsError.code): \(nsError.localizedDescription)"
    }

    /// A separate entry point for a typed wallet rejection (RPCErrorCode 300 = userDeclined).
    static func walletDeclined(code: Int, message: String) -> TonConnectError {
        .walletDeclined(code: code, message: message)
    }
}
