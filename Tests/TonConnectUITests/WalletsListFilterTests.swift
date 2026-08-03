import Foundation
import Testing
import TonConnectCore
import TonConnectUI

struct WalletsListFilterTests {

    private func entries() throws -> [WalletsListEntry] {
        try WalletsListEntry.decodeList(from: Data(WalletsListFixtures.threeWallets.utf8))
    }

    @Test func testEntryWithIOSPlatformAndSSEBridgeIsApplicable() throws {
        let tonkeeper = try #require(try entries().first { $0.appName == "tonkeeper" })
        #expect(tonkeeper.isApplicableOnIOS)
    }

    @Test func testEntryWithoutIOSPlatformIsNotApplicable() throws {
        let desktop = try #require(try entries().first { $0.appName == "desktoponly" })
        #expect(!desktop.isApplicableOnIOS)
    }

    @Test func testEntryWithOnlyJSBridgeIsNotApplicable() throws {
        let jsonly = try #require(try entries().first { $0.appName == "jsonly" })
        #expect(!jsonly.isApplicableOnIOS)
    }

    @Test func testFilterOnFixtureYieldsExactlyOneApplicableEntry() throws {
        let applicable = try entries().filter(\.isApplicableOnIOS)
        #expect(applicable.count == 1)
        #expect(applicable.first?.appName == "tonkeeper")
    }

    @Test func testMakeConnectionSourceUsesSSEBridgeURLNotJSKey() throws {
        let tonkeeper = try #require(try entries().first { $0.appName == "tonkeeper" })
        let source = try #require(tonkeeper.makeConnectionSource())
        #expect(source.bridgeUrl == "https://bridge.tonapi.io/bridge")
        #expect(source.universalLink == "https://app.tonkeeper.com/ton-connect")
    }

    @Test func testMakeConnectionSourceReturnsNilWithoutSSEBridge() throws {
        let jsonly = try #require(try entries().first { $0.appName == "jsonly" })
        #expect(jsonly.makeConnectionSource() == nil)
    }
}
