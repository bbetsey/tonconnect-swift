import Foundation
import Testing
import TonConnectCore
import TonConnectTestSupport
@testable import TonConnectNativeEngine

/// This suite's isolated scenario (fake v3 — per-class state).
private final class DeinitFakeBridge: FakeBridgeURLProtocol {}

private final class SpyOpener: WalletOpener, @unchecked Sendable {
    func open(_ url: URL) {}
}

private struct WalletSimulator {
    let crypto = SessionCrypto()
    var publicKeyHex: String { HexCoding.toHexString(crypto.keyPair.publicKey) }
    func frame(_ json: String, to clientIdHex: String) -> String {
        let clientKey = (try? HexCoding.hexToByteArray(clientIdHex)) ?? []
        let cipher = (try? crypto.encrypt(json, to: clientKey)) ?? []
        return "{\"from\":\"\(publicKeyHex)\",\"message\":\"\(Data(cipher).base64EncodedString())\"}"
    }
}

/// Engine lifetime hygiene: a dropped NativeEngine must close its SSE line
/// behind itself. An orphaned gateway with a live stream + a real 30s watchdog
/// re-subscribes to the bridge and steals the next test's connect frame —
/// exactly how the full `swift test` used to hang (observed, 2026-07-25/26).
@Suite(.serialized) struct NativeEngineDeinitTests {

    static let connectSuccessJSON = """
    {"event":"connect","id":1,"payload":{"items":[{"name":"ton_addr","address":"0:fake","network":"-3","publicKey":"deadbeef","walletStateInit":"te6ccFakeInit"}],"device":{"platform":"iphone","appName":"FakeWallet","appVersion":"1.0.0","maxProtocolVersion":2,"features":[{"name":"SendTransaction","maxMessages":4},{"name":"SignData","types":["text","binary","cell"]}]}}}
    """

    private func waitUntil(_ condition: @escaping @Sendable () -> Bool,
                           timeoutNanoseconds: UInt64 = 2_000_000_000) async -> Bool {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while DispatchTime.now().uptimeNanoseconds < deadline {
            if condition() { return true }
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        return condition()
    }

    /// A separate function scope: the engine is guaranteed to release on exit
    /// (a local variable in the test's async body could live until the function's end).
    private func connectAndDrop() async throws {
        let wallet = WalletSimulator()
        DeinitFakeBridge.eventsFrameProvider = { url in
            guard let clientId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "client_id" })?.value else { return [] }
            return [(id: "1", data: wallet.frame(Self.connectSuccessJSON, to: clientId))]
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [DeinitFakeBridge.self]
        let engine = NativeEngine(manifestUrl: "https://example.com/tonconnect-manifest.json",
                                  storage: InMemoryStorage(), opener: SpyOpener(),
                                  sessionConfiguration: config,
                                  clock: ManualReconnectClock())
        _ = try await engine.connect(
            source: WalletConnectionSource(universalLink: "https://wallet.deinit/tc",
                                           bridgeUrl: "https://bridge.deinit/bridge"),
            items: [.tonAddress(network: nil)])
    }

    @Test func testDroppedEngineClosesItsSSEStream() async throws {
        DeinitFakeBridge.reset()
        var script = DeinitFakeBridge.Script()
        script.keepEventsStreamOpen = true
        DeinitFakeBridge.script = script

        try await connectAndDrop() // the engine died on function exit

        // deinit must close the gateway: source.close() → task.cancel() →
        // the fake's stopLoading() → the stream is deregistered.
        #expect(await waitUntil { DeinitFakeBridge.liveEventStreamCount == 0 },
                "orphaned engine must close its SSE stream on deinit")
    }
}
