import Foundation
import Testing
import TonConnectCore
import TonConnectUI

/// Inline fixtures — shared by the Decoding/Filter tests (one test module).
enum WalletsListFixtures {
    /// 1 sse+iOS (passes the filter) + 1 js-only iOS + 1 non-iOS.
    static let threeWallets = """
    [
      {
        "app_name": "tonkeeper",
        "name": "Tonkeeper",
        "image": "https://tonkeeper.com/assets/tonconnect-icon.png",
        "about_url": "https://tonkeeper.com",
        "universal_url": "https://app.tonkeeper.com/ton-connect",
        "deepLink": "tonkeeper-tc://",
        "bridge": [
          { "type": "sse", "url": "https://bridge.tonapi.io/bridge" },
          { "type": "js", "key": "tonkeeper" }
        ],
        "platforms": ["ios", "android", "chrome"],
        "features": [
          { "name": "SendTransaction", "maxMessages": 4, "extraCurrencySupported": true },
          { "name": "SignData", "types": ["text", "binary", "cell"] }
        ]
      },
      {
        "app_name": "jsonly",
        "name": "JS Only Wallet",
        "image": "https://example.com/js.png",
        "universal_url": "https://example.com/tc",
        "bridge": [ { "type": "js", "key": "jsonly" } ],
        "platforms": ["ios", "chrome"]
      },
      {
        "app_name": "desktoponly",
        "name": "Desktop Wallet",
        "image": "https://example.com/d.png",
        "universal_url": "https://example.com/tc",
        "bridge": [ { "type": "sse", "url": "https://bridge.example.com" } ],
        "platforms": ["windows", "macos"]
      }
    ]
    """

    /// Like the real chrome entries: no universal_url — the decoder must skip it, not fail.
    static let oneBrokenOneGood = """
    [
      {
        "app_name": "extension",
        "name": "Chrome Extension",
        "image": "https://example.com/e.png",
        "bridge": [ { "type": "js", "key": "extension" } ],
        "platforms": ["chrome"]
      },
      {
        "app_name": "tonkeeper",
        "name": "Tonkeeper",
        "image": "https://tonkeeper.com/assets/tonconnect-icon.png",
        "universal_url": "https://app.tonkeeper.com/ton-connect",
        "bridge": [ { "type": "sse", "url": "https://bridge.tonapi.io/bridge" } ],
        "platforms": ["ios"]
      }
    ]
    """
}

struct WalletsListDecodingTests {

    @Test func testDecodingReadsImageFieldNotImageURL() throws {
        let entries = try WalletsListEntry.decodeList(from: Data(WalletsListFixtures.threeWallets.utf8))
        let tonkeeper = try #require(entries.first { $0.appName == "tonkeeper" })
        #expect(tonkeeper.image.absoluteString == "https://tonkeeper.com/assets/tonconnect-icon.png")
    }

    @Test func testDecodingReadsSnakeCaseFieldsIntoCamelCase() throws {
        let entries = try WalletsListEntry.decodeList(from: Data(WalletsListFixtures.threeWallets.utf8))
        let tonkeeper = try #require(entries.first { $0.appName == "tonkeeper" })
        #expect(tonkeeper.universalURL.absoluteString == "https://app.tonkeeper.com/ton-connect")
        #expect(tonkeeper.aboutURL?.absoluteString == "https://tonkeeper.com")
        #expect(tonkeeper.deepLink == "tonkeeper-tc://")
    }

    @Test func testDecodingReusesCoreFeatureModel() throws {
        let entries = try WalletsListEntry.decodeList(from: Data(WalletsListFixtures.threeWallets.utf8))
        let tonkeeper = try #require(entries.first { $0.appName == "tonkeeper" })
        #expect(tonkeeper.features?.contains(
            Feature.sendTransaction(maxMessages: 4, extraCurrencySupported: true, itemTypes: nil)
        ) == true)
    }

    @Test func testOptionalFieldsAbsentDecodeAsNil() throws {
        let entries = try WalletsListEntry.decodeList(from: Data(WalletsListFixtures.threeWallets.utf8))
        let jsonly = try #require(entries.first { $0.appName == "jsonly" })
        #expect(jsonly.aboutURL == nil)
        #expect(jsonly.deepLink == nil)
        #expect(jsonly.features == nil)
    }

    @Test func testDecodeListSkipsEntryWithoutUniversalURL() throws {
        let entries = try WalletsListEntry.decodeList(from: Data(WalletsListFixtures.oneBrokenOneGood.utf8))
        #expect(entries.count == 1)
        #expect(entries.first?.appName == "tonkeeper")
    }
}
