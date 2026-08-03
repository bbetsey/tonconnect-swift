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
        if error is URLError { return .network(message: String(describing: error)) }
        return .internalError(message: String(describing: error))
    }

    /// A separate entry point for a typed wallet rejection (RPCErrorCode 300 = userDeclined).
    static func walletDeclined(code: Int, message: String) -> TonConnectError {
        .walletDeclined(code: code, message: message)
    }
}
