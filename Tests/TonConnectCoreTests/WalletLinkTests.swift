import Foundation
import Testing
@testable import TonConnectCore

/// Link building for the two wallet families. The expectations are written
/// against the SDK sources (url.ts / universal-link.ts / url-strategy-helpers.ts),
/// not against what we assumed the wallets accept — bug 8 was exactly that
/// mistake, and the fixtures agreed with it.
struct WalletLinkTests {

    // MARK: - family test

    @Test func testIsTelegramRecognizesTMEHostAndTGScheme() {
        #expect(WalletLink.isTelegram("https://t.me/wallet?attach=wallet"))
        #expect(WalletLink.isTelegram("tg://resolve?domain=wallet"))
        #expect(!WalletLink.isTelegram("https://app.tonkeeper.com/ton-connect"))
    }

    // MARK: - Telegram transport

    @Test func testConvertToDirectLinkDropsAttachAndAppendsStart() throws {
        var components = try #require(URLComponents(string: "https://t.me/wallet?attach=wallet"))
        WalletLink.convertToDirectLink(&components)
        #expect(components.url?.absoluteString == "https://t.me/wallet/start")
    }

    @Test func testConvertToDirectLinkLeavesLinkWithoutAttachAlone() throws {
        var components = try #require(URLComponents(string: "https://t.me/wallet/start"))
        WalletLink.convertToDirectLink(&components)
        #expect(components.url?.absoluteString == "https://t.me/wallet/start")
    }

    @Test func testEncodeTelegramParametersAppliesSubstitutionsInOrder() {
        // . - _ are protected first, then & and = become the separators,
        // and only then every surviving % turns into the -- marker.
        #expect(WalletLink.encodeTelegramParameters("v=2&id=a.b-c_d")
                == "v__2-id__a--2Eb--2Dc--5Fd")
    }

    // MARK: - return strategy

    @Test func testAppendingReturnStrategyOnRegularLinkAddsRetQueryItem() throws {
        let url = try #require(URL(string: "https://app.tonkeeper.com/ton-connect"))
        #expect(WalletLink.appendingReturnStrategy("back", to: url).absoluteString
                == "https://app.tonkeeper.com/ton-connect?ret=back")
    }

    @Test func testAppendingReturnStrategyOnTelegramLinkRidesInsideStartapp() throws {
        let url = try #require(URL(string: "https://t.me/wallet/start?startapp=tonconnect-v__2"))
        #expect(WalletLink.appendingReturnStrategy("back", to: url).absoluteString
                == "https://t.me/wallet/start?startapp=tonconnect-v__2-ret__back")
    }

    @Test func testAppendingReturnStrategyOnTelegramLinkWithoutPayloadAddsBareStartapp() throws {
        let url = try #require(URL(string: "https://t.me/wallet/start"))
        #expect(WalletLink.appendingReturnStrategy("back", to: url).absoluteString
                == "https://t.me/wallet/start?startapp=tonconnect-ret__back")
    }
}
