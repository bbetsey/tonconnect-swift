import Foundation

/// The connected account — a projection of the wallet's ton_addr reply (spec/connect.md).
/// Populated by the engine/facade from TonAddressItemReply on a successful connect.
public struct Account: Equatable, Sendable {
    public let address: String
    public let network: String
    public let publicKey: String
    public let walletStateInit: String

    public init(address: String, network: String, publicKey: String, walletStateInit: String) {
        self.address = address
        self.network = network
        self.publicKey = publicKey
        self.walletStateInit = walletStateInit
    }
}
