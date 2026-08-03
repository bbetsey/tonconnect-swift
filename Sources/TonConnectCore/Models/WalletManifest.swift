import Foundation

/// spec/manifest.md — tonconnect-manifest.json
public struct WalletManifest: Codable, Equatable, Sendable {
    public let url: String
    public let name: String
    public let iconUrl: String
    public let termsOfUseUrl: String?
    public let privacyPolicyUrl: String?

    public init(
        url: String,
        name: String,
        iconUrl: String,
        termsOfUseUrl: String? = nil,
        privacyPolicyUrl: String? = nil
    ) {
        self.url = url
        self.name = name
        self.iconUrl = iconUrl
        self.termsOfUseUrl = termsOfUseUrl
        self.privacyPolicyUrl = privacyPolicyUrl
    }
}
