import Foundation
import TonConnectCore // Feature, WalletConnectionSource

/// An entry of the official wallets-v2.json wallet registry.
/// Schema verified 2026-07-15 by fetching the file directly: the field is named
/// simply image, no _url suffix.
public struct WalletsListEntry: Codable, Equatable, Sendable, Identifiable {
    public var id: String { appName }
    public let appName: String
    public let name: String
    public let image: URL // the key is "image", not a _url-suffixed variant
    public let aboutURL: URL?
    public let universalURL: URL
    public let deepLink: String?
    public let bridge: [BridgeEntry]
    public let platforms: [String]
    public let features: [Feature]? // Core's Feature reused (the shape matches)

    private enum CodingKeys: String, CodingKey {
        case appName = "app_name"
        case name, image
        case aboutURL = "about_url"
        case universalURL = "universal_url"
        case deepLink, bridge, platforms, features
    }

    /// One bridge a wallet offers. A wallet may list several: an `sse` entry
    /// carries a `url` we can talk to, a `js` entry only a browser-extension key.
    public struct BridgeEntry: Codable, Equatable, Sendable {
        public let type: String // "sse" | "js"
        public let url: String? // "sse" only
        public let key: String? // "js" only
    }
}

extension WalletsListEntry {
    /// Bridge is an array of heterogeneous entries; we need an sse one with a non-empty url.
    public var sseBridge: BridgeEntry? { bridge.first { $0.type == "sse" && $0.url != nil } }

    /// Applicable on iOS = declares the ios platform AND has an sse bridge.
    public var isApplicableOnIOS: Bool { platforms.contains("ios") && sseBridge != nil }

    /// The connect() pairing — no repackaging, straight to the Core type.
    public func makeConnectionSource() -> WalletConnectionSource? {
        guard let bridgeURL = sseBridge?.url else { return nil }
        return WalletConnectionSource(universalLink: universalURL.absoluteString, bridgeUrl: bridgeURL)
    }

    /// The SSE bridges of the given wallets, each once, in first-seen order —
    /// the list a "second device" QR connect subscribes to. Several wallets share
    /// a bridge (the registry has 36 wallets on 25 bridges), and the engine keeps
    /// one subscription per bridge, so duplicates would only double the traffic.
    /// A wallet without an SSE bridge contributes nothing.
    public static func sseBridgeURLs(of wallets: [WalletsListEntry]) -> [String] {
        var seen = Set<String>()
        return wallets.compactMap { $0.sseBridge?.url }.filter { seen.insert($0).inserted }
    }
}

extension WalletsListEntry {
    /// Lenient list decoding: a broken entry is skipped instead of failing the
    /// whole array. The real wallets-v2.json contains 5 chrome entries WITHOUT a
    /// universal_url (verified 2026-07-15) — a strict decode([WalletsListEntry].self)
    /// would fail entirely.
    public static func decodeList(from data: Data) throws -> [WalletsListEntry] {
        try JSONDecoder().decode([FailableEntry].self, from: data).compactMap(\.entry)
    }

    private struct FailableEntry: Decodable {
        let entry: WalletsListEntry?
        init(from decoder: Decoder) throws { entry = try? WalletsListEntry(from: decoder) }
    }
}

extension WalletsListEntry: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(appName)
    }
}

extension WalletsListEntry {
    /// The link that brings an ALREADY connected wallet to the front so the user
    /// can confirm a pending request (SDK parity: url-strategy-helpers.ts,
    /// redirectToTelegram / redirectToWallet). There is no connect payload here —
    /// only the return strategy — but a Telegram wallet still needs the Mini App
    /// transport: a direct `/start` link plus `startapp`. A plain `ret=` query is
    /// dropped by Telegram and the wallet opens on its default screen instead of
    /// the request (the same root cause as bug 8 on connect).
    public func wakeLink(returnStrategy: ReturnStrategy) -> URL {
        var link = universalURL
        if WalletLink.isTelegram(link),
           var components = URLComponents(url: link, resolvingAgainstBaseURL: false) {
            WalletLink.convertToDirectLink(&components)
            link = components.url ?? link
        }
        return WalletLink.appendingReturnStrategy(returnStrategy.queryValue, to: link)
    }

    /// Finds the registry entry for the name the wallet reported in its
    /// `DeviceInfo.appName`. The two sides spell the same wallet differently —
    /// the registry has `app_name: "telegram-wallet"` and `name: "Wallet"`, and a
    /// wallet may answer "Telegram Wallet" — so the comparison drops case and
    /// every separator instead of demanding equality. No match means no wake link,
    /// and the user is left tapping into the wallet by hand.
    public static func matching(walletName: String,
                                in wallets: [WalletsListEntry]) -> WalletsListEntry? {
        let needle = normalizedName(walletName)
        guard !needle.isEmpty else { return nil }
        return wallets.first {
            normalizedName($0.appName) == needle || normalizedName($0.name) == needle
        }
    }

    private static func normalizedName(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }
}
