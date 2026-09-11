import Foundation
import Testing
import TonConnectCore
@testable import TonConnectUI

/// The "second device" QR connect from this module: the bridges are gathered
/// from wallet entries, and the facade extension hands them to the engine.
@MainActor
struct QRConnectTests {

    /// Four wallets on two bridges: two share the first, one has the second,
    /// one has only a JS bridge. The registry looks like this in miniature.
    private static let wallets = """
    [
      {"app_name":"a","name":"A","image":"https://x/a.png","universal_url":"https://a.wallet/tc",
       "bridge":[{"type":"sse","url":"https://bridge.one/bridge"}],"platforms":["ios"]},
      {"app_name":"b","name":"B","image":"https://x/b.png","universal_url":"https://b.wallet/tc",
       "bridge":[{"type":"js","key":"b"},{"type":"sse","url":"https://bridge.two/bridge"}],"platforms":["ios"]},
      {"app_name":"c","name":"C","image":"https://x/c.png","universal_url":"https://c.wallet/tc",
       "bridge":[{"type":"sse","url":"https://bridge.one/bridge"}],"platforms":["ios"]},
      {"app_name":"d","name":"D","image":"https://x/d.png","universal_url":"https://d.wallet/tc",
       "bridge":[{"type":"js","key":"d"}],"platforms":["ios"]}
    ]
    """

    private func entries() throws -> [WalletsListEntry] {
        try WalletsListEntry.decodeList(from: Data(Self.wallets.utf8))
    }

    // MARK: - gathering bridges

    @Test func testSSEBridgeURLsListsEachBridgeOnceInFirstSeenOrder() throws {
        let bridges = WalletsListEntry.sseBridgeURLs(of: try entries())
        #expect(bridges == ["https://bridge.one/bridge", "https://bridge.two/bridge"])
    }

    @Test func testSSEBridgeURLsOfWalletsWithoutAnSSEBridgeIsEmpty() throws {
        let jsOnly = try entries().filter { $0.appName == "d" }
        #expect(WalletsListEntry.sseBridgeURLs(of: jsOnly).isEmpty)
    }

    // MARK: - the facade extension

    @Test func testConnectWithQRForWalletsHandsTheirBridgesToTheEngine() async throws {
        let engine = RecordingEngine()
        let facade = TonConnect(engine: engine, autoRestore: false)
        try await facade.connectWithQR(wallets: try entries(), items: [.tonAddress(network: nil)])
        #expect(engine.bridgeURLs == ["https://bridge.one/bridge", "https://bridge.two/bridge"])
        #expect(facade.isConnected)
    }

    /// A QR nobody could answer is refused up front, before the engine is asked.
    @Test func testConnectWithQRForWalletsWithoutBridgesThrowsBeforeTheEngine() async throws {
        let engine = RecordingEngine()
        let facade = TonConnect(engine: engine, autoRestore: false)
        let jsOnly = try entries().filter { $0.appName == "d" }
        await #expect(throws: TonConnectError.self) {
            try await facade.connectWithQR(wallets: jsOnly, items: [.tonAddress(network: nil)])
        }
        #expect(engine.calls == 0)
        #expect(facade.state == .disconnected)
    }

    /// The registry default, read from the bundled snapshot through a loader
    /// pointed at an empty cache directory — nothing on this machine leaks in.
    @Test func testConnectWithQRFromTheRegistryUsesTheSnapshotBridges() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("qr-connect-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let engine = RecordingEngine()
        let facade = TonConnect(engine: engine, autoRestore: false)
        try await facade.connectWithQR(items: [.tonAddress(network: nil)], timeout: nil,
                                       registry: WalletsListLoader(cacheDirectory: dir))
        #expect(engine.bridgeURLs.count > 1, "the snapshot carries many bridges")
        #expect(engine.bridgeURLs.contains("https://bridge.tonapi.io/bridge"))
        #expect(Set(engine.bridgeURLs).count == engine.bridgeURLs.count, "each bridge once")
    }
}

/// Records what connectUniversal was asked for and answers with a canned success.
private final class RecordingEngine: TonConnectEngine, @unchecked Sendable {
    let events: AsyncStream<TonConnectEvent>
    private let continuation: AsyncStream<TonConnectEvent>.Continuation
    private let lock = NSLock()
    private var _bridgeURLs: [String] = []
    private var _calls = 0

    var bridgeURLs: [String] { lock.withLock { _bridgeURLs } }
    var calls: Int { lock.withLock { _calls } }

    init() {
        var continuation: AsyncStream<TonConnectEvent>.Continuation!
        self.events = AsyncStream { continuation = $0 }
        self.continuation = continuation
    }

    private static let connected = ConnectEvent.success(
        id: 1,
        payload: ConnectSuccessPayload(
            items: [.tonAddress(TonAddressItemReply(address: "0:qr", network: "-3",
                                                    publicKey: "00", walletStateInit: "te6"))],
            device: DeviceInfo(platform: .iphone, appName: "QRWallet", appVersion: "1",
                               maxProtocolVersion: 2, features: [])),
        response: nil)

    func connect(source: WalletConnectionSource, items: [ConnectItem]) async throws -> ConnectEvent {
        lock.withLock { _calls += 1 }
        return Self.connected
    }
    func connectUniversal(bridgeURLs: [String], items: [ConnectItem]) async throws -> ConnectEvent {
        lock.withLock { _calls += 1; _bridgeURLs = bridgeURLs }
        return Self.connected
    }
    func restoreConnection() async throws { throw TonConnectError.decodeFailure("no saved session") }
    func sendTransaction(_ payload: SendTransactionPayload) async throws -> WalletResponse {
        .success(result: "", id: "1")
    }
    func signData(_ payload: SignDataPayload) async throws -> WalletResponse {
        .success(result: "", id: "1")
    }
    func disconnect() async throws {}
}
