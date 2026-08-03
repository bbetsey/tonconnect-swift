import Foundation
import Testing
import TonConnectCore
import TonConnectUI

/// Waking an already connected wallet for a pending send/sign.
struct WalletWakeLinkTests {

    /// Real values from wallets-v2.json (checked 2026-08-03): the Telegram entry
    /// spells itself "telegram-wallet" / "Wallet" and its universal_url is the
    /// attach form.
    private static let twoWallets = """
    [
      {
        "app_name": "telegram-wallet",
        "name": "Wallet",
        "image": "https://wallet.tg/images/logo-288.png",
        "universal_url": "https://t.me/wallet?attach=wallet",
        "bridge": [{ "type": "sse", "url": "https://walletbot.me/tonconnect-bridge/bridge" }],
        "platforms": ["ios", "android"]
      },
      {
        "app_name": "tonkeeper",
        "name": "Tonkeeper",
        "image": "https://tonkeeper.com/assets/tonconnect-icon.png",
        "universal_url": "https://app.tonkeeper.com/ton-connect",
        "bridge": [{ "type": "sse", "url": "https://bridge.tonapi.io/bridge" }],
        "platforms": ["ios", "android"]
      }
    ]
    """

    private func entries() throws -> [WalletsListEntry] {
        try WalletsListEntry.decodeList(from: Data(Self.twoWallets.utf8))
    }

    // MARK: - the link itself

    @Test func testWakeLinkForTelegramWalletTravelsInsideStartapp() throws {
        let telegram = try #require(try entries().first { $0.appName == "telegram-wallet" })
        #expect(telegram.wakeLink(returnStrategy: .back).absoluteString
                == "https://t.me/wallet/start?startapp=tonconnect-ret__back")
    }

    @Test func testWakeLinkForRegularWalletAppendsRetQueryItem() throws {
        let tonkeeper = try #require(try entries().first { $0.appName == "tonkeeper" })
        #expect(tonkeeper.wakeLink(returnStrategy: .back).absoluteString
                == "https://app.tonkeeper.com/ton-connect?ret=back")
    }

    @Test func testWakeLinkCarriesACustomReturnURL() throws {
        let tonkeeper = try #require(try entries().first { $0.appName == "tonkeeper" })
        #expect(tonkeeper.wakeLink(returnStrategy: .url("myapp://")).absoluteString
                == "https://app.tonkeeper.com/ton-connect?ret=myapp://")
    }

    // MARK: - finding the wallet the user is connected to

    @Test func testMatchingWalletNameIgnoresCaseAndSeparators() throws {
        let found = WalletsListEntry.matching(walletName: "Telegram Wallet", in: try entries())
        #expect(found?.appName == "telegram-wallet")
    }

    @Test func testMatchingWalletNameAcceptsTheDisplayName() throws {
        let found = WalletsListEntry.matching(walletName: "Wallet", in: try entries())
        #expect(found?.appName == "telegram-wallet")
    }

    @Test func testMatchingWalletNameReturnsNilForAnUnknownWallet() throws {
        #expect(WalletsListEntry.matching(walletName: "Ghost Wallet", in: try entries()) == nil)
    }
}
