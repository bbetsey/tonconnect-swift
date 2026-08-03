import Foundation
import Testing
import TonConnectCore
import TonConnectConformance
import TonConnectTestSupport
@testable import TonConnectNativeEngine

/// This suite's isolated scenario (fake v3 — per-class state).
final class NativeE2EFakeBridge: FakeBridgeURLProtocol {}

private final class SpyOpener: WalletOpener, @unchecked Sendable {
    private let lock = NSLock()
    private var urls: [URL] = []
    func open(_ url: URL) { lock.lock(); urls.append(url); lock.unlock() }
    var openedURLs: [URL] { lock.lock(); defer { lock.unlock() }; return urls }
}

/// A PER-client_id subscription counter: a late GET /events from an
/// already-closed gateway (restore/re-subscription cancelled by close() with a
/// startLoading in flight) lands after the next scenario's reset() under load —
/// it used to steal the global counter (`calls == 1` went to a foreign client),
/// and the new engine waited for its frame forever.
private final class PerClientCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var counts: [String: Int] = [:]
    func next(_ clientId: String) -> Int {
        lock.lock(); defer { lock.unlock() }
        counts[clientId, default: 0] += 1
        return counts[clientId]!
    }
}

/// A Swift wallet simulator WITHOUT a JSContext (native crypto — simpler than the counterpart).
private struct WalletSimulator {
    let crypto = SessionCrypto()
    var publicKeyHex: String { HexCoding.toHexString(crypto.keyPair.publicKey) }

    func frame(_ json: String, to clientIdHex: String) -> String {
        let clientKey = (try? HexCoding.hexToByteArray(clientIdHex)) ?? []
        let cipher = (try? crypto.encrypt(json, to: clientKey)) ?? []
        return "{\"from\":\"\(publicKeyHex)\",\"message\":\"\(Data(cipher).base64EncodedString())\"}"
    }

    func decryptRPCBody(_ base64Body: String, from clientIdHex: String) -> String? {
        guard let clientKey = try? HexCoding.hexToByteArray(clientIdHex),
              let data = Data(base64Encoded: base64Body) else { return nil }
        return try? crypto.decrypt(Array(data), from: clientKey)
    }
}

@Suite(.serialized) struct NativeEngineFakeBridgeE2ETests {

    static let connectSuccessJSON = """
    {"event":"connect","id":1,"payload":{"items":[{"name":"ton_addr","address":"0:fake","network":"-3","publicKey":"deadbeef","walletStateInit":"te6ccFakeInit"}],"device":{"platform":"iphone","appName":"FakeWallet","appVersion":"1.0.0","maxProtocolVersion":2,"features":[{"name":"SendTransaction","maxMessages":4},{"name":"SignData","types":["text","binary","cell"]}]}}}
    """

    /// The host from the EngineConformanceSuite.source fixture — guard isolation.
    static let bridgeHost = "bridge.tonapi.io"

    private static func clientID(from url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "client_id" }?.value
    }

    /// The "examiner wallet": connect-success on the first subscription; a
    /// per-method reply to every POST (sendTransaction→result, signData→error 300,
    /// disconnect→result).
    static func attachWalletSimulator() {
        let wallet = WalletSimulator()
        let calls = PerClientCounter()
        NativeE2EFakeBridge.eventsFrameProvider = { url in
            guard url.host == bridgeHost, let clientId = clientID(from: url) else { return [] }
            guard calls.next(clientId) == 1 else { return [] } // restore's re-subscriptions are empty
            return [(id: "1", data: wallet.frame(connectSuccessJSON, to: clientId))]
        }
        NativeE2EFakeBridge.messageHandler = { url, body in
            guard url.host == bridgeHost,
                  let clientId = clientID(from: url),
                  let decrypted = wallet.decryptRPCBody(body, from: clientId),
                  let data = decrypted.data(using: .utf8),
                  let request = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let method = request["method"] as? String else { return }
            let id = (request["id"] as? String) ?? "0"
            let responseJSON: String
            switch method {
            case "sendTransaction":
                responseJSON = "{\"result\":\"te6ccFakeBoc\",\"id\":\"\(id)\"}"
            case "signData":
                responseJSON = "{\"error\":{\"code\":300,\"message\":\"user declined\"},\"id\":\"\(id)\"}"
            default: // disconnect
                responseJSON = "{\"result\":\"ok\",\"id\":\"\(id)\"}"
            }
            NativeE2EFakeBridge.pushFrame(id: "2", data: wallet.frame(responseJSON, to: clientId))
        }
    }

    struct NativeEngineFactory: EngineFactory {
        let label = "NativeEngine+FakeBridge"
        func makeEngine() async throws -> any TonConnectEngine {
            NativeE2EFakeBridge.reset()
            var script = NativeE2EFakeBridge.Script()
            script.keepEventsStreamOpen = true
            NativeE2EFakeBridge.script = script
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [NativeE2EFakeBridge.self]
            // ManualReconnectClock: the watchdog never ticks — on a slow run a
            // live engine will not re-subscribe and lose the simulator's frames.
            let engine = NativeEngine(manifestUrl: "https://example.com/tonconnect-manifest.json",
                                      storage: InMemoryStorage(),
                                      opener: SpyOpener(),
                                      sessionConfiguration: config,
                                      clock: ManualReconnectClock())
            NativeEngineFakeBridgeE2ETests.attachWalletSimulator()
            return engine
        }
    }

    /// The phase's criterion #3: the same suite that is green on
    /// JSCoreEngine/FakeEngine, WITHOUT a single edit to EngineConformanceSuite.swift.
    @Test func testNativeEngineAgainstFakeBridgePassesConformanceSuite() async throws {
        try await EngineConformanceSuite.runAll(factory: NativeEngineFactory())
    }
}
