import Foundation

/// spec/connect.md + rpc.md — wallet-initiated event surface.
/// Delivered via the engine's AsyncStream, not as method return values:
/// the wallet can emit these at any moment (e.g. remote disconnect).
public enum TonConnectEvent: Equatable, Sendable {
    case connected(ConnectEvent)
    case disconnected
    case transactionResponse(WalletResponse)
    case connectLinkGenerated(URL)
    /// An RPC request has been accepted by the bridge. SDK parity: the reference
    /// client opens the wallet only after `gateway.send` resolves
    /// (bridge-provider.ts → onRequestSent → redirectAfterRequestSent). Waking a
    /// wallet earlier makes it show a "waiting for request" placeholder that
    /// times out with "Dapp Not Responding" (observed on a live wallet).
    case requestSent
}
