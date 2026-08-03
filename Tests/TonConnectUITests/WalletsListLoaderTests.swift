import Foundation
import Testing
import TonConnectUI

@MainActor
struct WalletsListLoaderTests {

    private func makeTempDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("wallets-loader-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    @Test func testLoadWithEmptyCacheFallsBackToBundledSnapshotInstantly() throws {
        let loader = WalletsListLoader(cacheDirectory: try makeTempDirectory())
        loader.load()
        // Assert right after load(): the network Task has not had the MainActor yet — no race.
        #expect(!loader.wallets.isEmpty)
        let allApplicable = loader.wallets.allSatisfy(\.isApplicableOnIOS)
        #expect(allApplicable)
    }

    @Test func testLoadPrefersDiskCacheOverSnapshot() throws {
        let dir = try makeTempDirectory()
        try Data(WalletsListFixtures.threeWallets.utf8)
            .write(to: dir.appendingPathComponent("tonconnect-wallets-v2.json"))
        let loader = WalletsListLoader(cacheDirectory: dir)
        loader.load()
        #expect(loader.wallets.count == 1) // the fixture: exactly 1 applicable
        #expect(loader.wallets.first?.appName == "tonkeeper")
    }

    @Test func testLoadWithCorruptedCacheFallsBackToSnapshot() throws {
        let dir = try makeTempDirectory()
        try Data("not json at all".utf8)
            .write(to: dir.appendingPathComponent("tonconnect-wallets-v2.json"))
        let loader = WalletsListLoader(cacheDirectory: dir)
        loader.load()
        #expect(!loader.wallets.isEmpty) // a corrupt cache → the snapshot saved us (V5)
    }
}
