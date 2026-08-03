import Foundation

/// The connection source for a specific wallet.
/// The shape is 1:1 with @tonconnect/sdk's WalletConnectionSourceHTTP
/// {universalLink, bridgeUrl} (checked against Tonkeeper's entry in
/// wallets-v2.json — universal_url / bridge[].url), so the wallet picker passes
/// a registry entry straight through without repackaging.
public struct WalletConnectionSource: Codable, Equatable, Sendable {
    public let universalLink: String
    public let bridgeUrl: String

    public init(universalLink: String, bridgeUrl: String) {
        self.universalLink = universalLink
        self.bridgeUrl = bridgeUrl
    }
}
