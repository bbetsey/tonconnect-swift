import Foundation
import TonConnectCore

/// The "second device" QR connect for an app that draws its own UI.
///
/// ``WalletPickerSheet`` offers one QR that any wallet can scan: it subscribes
/// to the bridge of every wallet in the registry, and whichever bridge answers
/// first wins. `TonConnect.connectWithQR(bridgeURLs:items:timeout:)` in Core
/// does the connecting but wants the bridge list spelled out, because Core
/// knows nothing about wallets. This is where the two meet: the registry lives
/// in this module, so this module can fill the list in.
///
/// The link to render arrives in `TonConnect.connectLink`, as for every connect.
public extension TonConnect {

    /// Connects over a QR that any wallet in the registry can scan.
    ///
    /// The bridges are the ones the wallet picker would use at this moment: the
    /// registry's disk cache if there is one, otherwise the snapshot bundled with
    /// the package — and, like the picker, this quietly refreshes the cache from
    /// the network for next time. To choose the wallets yourself, use
    /// ``connectWithQR(wallets:items:timeout:)``.
    ///
    /// - Parameters:
    ///   - items: what to ask the wallet for; `.tonAddress` at the least.
    ///   - timeout: how long to keep the QR offer open. `nil`, the default,
    ///     waits as long as it takes.
    func connectWithQR(items: [ConnectItem], timeout: Duration? = nil) async throws {
        try await connectWithQR(items: items, timeout: timeout, registry: WalletsListLoader())
    }

    /// Connects over a QR that any of the given wallets can scan — the registry
    /// filtered by you, for instance to the wallets that support a feature the
    /// app needs. The bridges are gathered with ``WalletsListEntry/sseBridgeURLs(of:)``.
    ///
    /// - Parameters:
    ///   - wallets: the wallets to reach; the ones without an SSE bridge are
    ///     skipped. Throws `TonConnectError.internalError` when none is left,
    ///     rather than offering a QR nobody could answer.
    ///   - items: what to ask the wallet for; `.tonAddress` at the least.
    ///   - timeout: how long to keep the QR offer open. `nil`, the default,
    ///     waits as long as it takes.
    func connectWithQR(wallets: [WalletsListEntry], items: [ConnectItem],
                       timeout: Duration? = nil) async throws {
        let bridges = WalletsListEntry.sseBridgeURLs(of: wallets)
        guard !bridges.isEmpty else {
            throw TonConnectError.internalError(message: "none of the given wallets offers an SSE bridge")
        }
        try await connectWithQR(bridgeURLs: bridges, items: items, timeout: timeout)
    }

    /// The seam behind the registry default: a test hands in a loader pointed at
    /// its own cache directory, so the assertion reads the bundled snapshot and
    /// nothing on the machine.
    internal func connectWithQR(items: [ConnectItem], timeout: Duration?,
                                registry: WalletsListLoader) async throws {
        registry.load() // cache → snapshot, published instantly; the network refresh runs behind
        try await connectWithQR(wallets: registry.wallets, items: items, timeout: timeout)
    }
}
