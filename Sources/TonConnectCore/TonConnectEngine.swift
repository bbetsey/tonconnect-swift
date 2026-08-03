import Foundation

/// Engine abstraction — the swap boundary of this package.
/// Stage 1 implements it over JSCore, Stage 2 natively;
/// both must pass the identical EngineConformanceSuite.
public protocol TonConnectEngine: Sendable {
    /// spec/connect.md § ConnectRequest → ConnectEvent.
    /// The wallet parameter (universal link + bridge URL). manifestUrl is now
    /// set at engine construction (JSCoreEngine.init), not on every connect.
    func connect(source: WalletConnectionSource, items: [ConnectItem]) async throws -> ConnectEvent
    /// "Second device" QR connect (@tonconnect/ui parity): the bridge URLs of all
    /// wallets; the SDK builds a universal tc:// link — it leaves via the
    /// .connectLinkGenerated event; no wallet is opened on THIS device.
    func connectUniversal(bridgeURLs: [String], items: [ConnectItem]) async throws -> ConnectEvent
    /// spec/session.md — restore a persisted session without a wallet round-trip
    func restoreConnection() async throws
    /// spec/rpc.md § sendTransaction
    func sendTransaction(_ payload: SendTransactionPayload) async throws -> WalletResponse
    /// spec/rpc.md § signData
    func signData(_ payload: SignDataPayload) async throws -> WalletResponse
    /// spec/rpc.md § disconnect
    func disconnect() async throws
    /// Wallet-initiated events
    var events: AsyncStream<TonConnectEvent> { get }
}

public extension TonConnectEngine {
    func connectUniversal(bridgeURLs: [String], items: [ConnectItem]) async throws -> ConnectEvent {
        throw TonConnectError.internalError(message: "connectUniversal is not supported by this engine")
    }
}
