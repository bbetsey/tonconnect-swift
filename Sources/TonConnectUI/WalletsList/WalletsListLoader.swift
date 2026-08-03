import Foundation

/// The wallets-list loader — stale-while-revalidate:
/// instantly serves the best available (disk cache → bundled snapshot), then
/// quietly swaps in the network result. The sheet is never empty and never waits for the network.
@MainActor
public final class WalletsListLoader: ObservableObject {
    @Published public private(set) var wallets: [WalletsListEntry] = []

    private let remoteURL = URL(string: "https://raw.githubusercontent.com/ton-blockchain/wallets-list/main/wallets-v2.json")!
    private let session: URLSession
    private let bundle: Bundle
    private let cacheURL: URL

    /// The defaults are what an app wants; the parameters exist so tests can
    /// point the loader at their own session, cache directory and bundle.
    public init(session: URLSession = .shared, cacheDirectory: URL? = nil, bundle: Bundle? = nil) {
        self.session = session
        self.bundle = bundle ?? .module
        // The OS caches directory (not Documents): recoverable data, excluded from iCloud backups.
        let dir = cacheDirectory ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheURL = dir.appendingPathComponent("tonconnect-wallets-v2.json")
    }

    /// Publishes the best list available right now, then refreshes from the
    /// network in the background. Safe to call every time the sheet appears.
    public func load() {
        if let entries = readLocal() { wallets = entries.filter(\.isApplicableOnIOS) } // cache → snapshot, instantly
        Task { await refreshFromNetwork() } // quiet swap-in
    }

    private func readLocal() -> [WalletsListEntry]? {
        if let data = try? Data(contentsOf: cacheURL),
           let entries = try? WalletsListEntry.decodeList(from: data) { return entries }
        if let url = bundle.url(forResource: "wallets-v2.snapshot", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let entries = try? WalletsListEntry.decodeList(from: data) { return entries }
        return nil
    }

    private func refreshFromNetwork() async {
        // Any network/parsing error stays silent — the fallback is already shown.
        // An empty result does not clobber a working list (insurance against schema changes).
        guard let (data, _) = try? await session.data(from: remoteURL),
              let entries = try? WalletsListEntry.decodeList(from: data),
              !entries.isEmpty else { return }
        wallets = entries.filter(\.isApplicableOnIOS)
        try? data.write(to: cacheURL)
    }
}
