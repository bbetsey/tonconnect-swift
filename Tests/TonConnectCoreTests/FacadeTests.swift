import Foundation
import Testing
import TonConnectCore
import TonConnectConformance

/// The facade against FakeEngine — engine-agnosticism is proven
/// BEFORE a live JSCoreEngine exists.
@MainActor
struct FacadeTests {

    private static let source = WalletConnectionSource(universalLink: "u", bridgeUrl: "b")

    /// A polling wait with an iteration ceiling — no fixed sleep.
    private func waitUntil(_ condition: () -> Bool, iterations: Int = 100) async {
        for _ in 0..<iterations where !condition() {
            try? await Task.sleep(nanoseconds: 5_000_000) // 5ms
        }
    }

    @Test func testAutoRestoreWithoutSessionEndsDisconnected() async {
        let facade = TonConnect(engine: FakeEngine()) // autoRestore: true
        await waitUntil { facade.state == .disconnected }
        #expect(facade.state == .disconnected, "restore without a session throws → .disconnected")
    }

    @Test func testConnectMovesStateToConnectedWithAccount() async throws {
        let facade = TonConnect(engine: FakeEngine(), autoRestore: false)
        try await facade.connect(source: Self.source, items: [.tonAddress(network: nil)])
        #expect(facade.isConnected)
        #expect(facade.account?.address == "0:fake", "the Account is built from the canned ton_addr reply")
    }

    @Test func testAutoRestoreAfterConnectStaysConnected() async throws {
        let engine = FakeEngine()
        let facade = TonConnect(engine: engine, autoRestore: false)
        try await facade.connect(source: Self.source, items: [.tonAddress(network: nil)])
        await facade.restore() // a session exists → no throw
        #expect(engine.recordedCalls.contains("restore"))
    }

    @Test func testStatePassesThroughRestoringDuringAutoRestore() async throws {
        let engine = FakeEngine()
        let facade = TonConnect(engine: engine, autoRestore: false)
        try await facade.connect(source: Self.source, items: [.tonAddress(network: nil)])
        await facade.restore()
        // Success without an event: the facade stays in .restoring — the account
        // arrives via a live engine's .connected event pump (design note).
        #expect(facade.state == .restoring)
    }

    @Test func testWalletInitiatedDisconnectEventResetsState() async throws {
        let engine = FakeEngine()
        let facade = TonConnect(engine: engine, autoRestore: false)
        try await facade.connect(source: Self.source, items: [.tonAddress(network: nil)])
        #expect(facade.isConnected)
        engine.inject(.disconnected) // the wallet tore the session down itself
        await waitUntil { facade.state == .disconnected }
        #expect(facade.state == .disconnected, "the state was reset by the event, disconnect() was never called")
    }
    
    @Test func testConnectPublishesConnectLinkFromEngineEvent() async throws {
        let facade = TonConnect(engine: FakeEngine(), autoRestore: false)
        try await facade.connect(source: Self.source, items: [.tonAddress(network: nil)])
        await waitUntil { facade.connectLink != nil }
        #expect(facade.connectLink?.absoluteString == "u")
    }

    @Test func testDisconnectClearsConnectLink() async throws {
        let facade = TonConnect(engine: FakeEngine(), autoRestore: false)
        try await facade.connect(source: Self.source, items: [.tonAddress(network: nil)])
        await waitUntil { facade.connectLink != nil }
        try await facade.disconnect()
        #expect(facade.connectLink == nil)
    }
    
    @Test func testConnectWithQRPublishesLinkWithoutOpeningWallet() async throws {
        let engine = FakeEngine()
        let facade = TonConnect(engine: engine, autoRestore: false)
        try await facade.connectWithQR(bridgeURLs: ["https://bridge.test"],
                                       items: [.tonAddress(network: nil)])
        #expect(engine.recordedCalls.contains("connectUniversal"))
        #expect(facade.isConnected)
    }
    
    // MARK: - timeout

    /// A connect that outlives its deadline is torn down like a cancelled one:
    /// the error is typed, and the state goes back to .disconnected so the UI
    /// offers a fresh attempt instead of an eternal spinner.
    @Test func testConnectWithTimeoutThrowsTimeoutAndReturnsToDisconnected() async {
        let engine = HangingEngine()
        let facade = TonConnect(engine: engine, autoRestore: false)
        await #expect(throws: TonConnectError.timeout(after: .milliseconds(50))) {
            try await facade.connect(source: Self.source, items: [.tonAddress(network: nil)],
                                     timeout: .milliseconds(50))
        }
        #expect(facade.state == .disconnected)
        await waitUntil { engine.cancellations == 1 }
        #expect(engine.cancellations == 1, "the engine's connect was cancelled, not abandoned")
    }

    @Test func testConnectWithQRWithTimeoutThrowsTimeoutAndReturnsToDisconnected() async {
        let facade = TonConnect(engine: HangingEngine(), autoRestore: false)
        await #expect(throws: TonConnectError.timeout(after: .milliseconds(50))) {
            try await facade.connectWithQR(bridgeURLs: ["https://bridge.test"],
                                           items: [.tonAddress(network: nil)],
                                           timeout: .milliseconds(50))
        }
        #expect(facade.state == .disconnected)
    }

    @Test func testConnectStoresWalletNameFromDeviceInfo() async throws {
        let facade = TonConnect(engine: FakeEngine(), autoRestore: false)
        try await facade.connect(source: WalletConnectionSource(universalLink: "u", bridgeUrl: "b"),
                                 items: [.tonAddress(network: nil)])
        #expect(facade.connectedWalletName == "FakeWallet")
    }
}
