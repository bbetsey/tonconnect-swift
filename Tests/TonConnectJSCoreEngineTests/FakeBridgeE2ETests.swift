import Foundation
import JavaScriptCore
import Testing
import TonConnectCore
import TonConnectConformance
import TonConnectTestSupport
@testable import TonConnectJSCoreEngine

final class E2EFakeBridge: FakeBridgeURLProtocol {}

/// JSCoreEngine passes THE SAME conformance suite that is green on
/// FakeEngine. The "wallet" is simulated in the same JSC with the SDK's own
/// crypto (__tcTestWallet*): bridge messages are genuinely NaCl-box encrypted —
/// the full protocol path.
struct FakeBridgeE2ETests {

    /// The connect-success wire form (spec/connect.md) — what the wallet sends.
    static let connectSuccessJSON = """
    {"event":"connect","id":1,"payload":{"items":[{"name":"ton_addr","address":"0:fake","network":"-3","publicKey":"deadbeef","walletStateInit":"te6ccFakeInit"}],"device":{"platform":"iphone","appName":"FakeWallet","appVersion":"1.0.0","maxProtocolVersion":2,"features":[{"name":"SendTransaction","maxMessages":4},{"name":"SignData","types":["text","binary","cell"]}]}}}
    """

    /// The host from the EngineConformanceSuite.source fixture — isolation from other suites.
    static let bridgeHost = "bridge.tonapi.io"

    static func js(_ value: String) -> String {
        if let data = try? JSONEncoder().encode([value]), let json = String(data: data, encoding: .utf8) {
            return String(json.dropFirst().dropLast())
        }
        return "\"\""
    }

    static func attachWalletSimulator(to bridge: JSCoreBridge) {
        let walletPub = bridge.perform { ctx in
            ctx.evaluateScript("__tcTestWalletCreate()")?.toString() ?? ""
        }

        // The first GET /events: encrypt a connect-success to the URL's client_id.
        E2EFakeBridge.eventsFrameProvider = { [weak bridge] url in
            guard url.host == Self.bridgeHost, let bridge,
                  let clientId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                      .queryItems?.first(where: { $0.name == "client_id" })?.value else { return [] }
            let frame = bridge.perform { ctx -> String in
                let encrypted = ctx.evaluateScript(
                    "__tcTestWalletEncrypt(\(js(clientId)), \(js(connectSuccessJSON)))")?.toString() ?? ""
                return "{\"from\":\"\(walletPub)\",\"message\":\"\(encrypted)\"}"
            }
            return [(id: "1", data: frame)]
        }

        // Every POST /message: decrypt the request, reply per method.
        E2EFakeBridge.messageHandler = { [weak bridge] url, body in
            guard url.host == Self.bridgeHost, let bridge,
                  let clientId = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                      .queryItems?.first(where: { $0.name == "client_id" })?.value else { return }
            let responseFrame: String? = bridge.perform { ctx -> String? in
                guard let decrypted = ctx.evaluateScript(
                          "__tcTestWalletDecrypt(\(js(clientId)), \(js(body)))")?.toString(),
                      let data = decrypted.data(using: .utf8),
                      let request = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let method = request["method"] as? String else { return nil }
                let id = (request["id"] as? String) ?? String(describing: request["id"] ?? "0")
                let responseJSON: String
                switch method {
                case "sendTransaction":
                    responseJSON = "{\"result\":\"te6ccFakeBoc\",\"id\":\"\(id)\"}"
                case "signData":
                    responseJSON = "{\"error\":{\"code\":300,\"message\":\"user declined\"},\"id\":\"\(id)\"}"
                default: // disconnect
                    responseJSON = "{\"result\":{},\"id\":\"\(id)\"}"
                }
                let encrypted = ctx.evaluateScript(
                    "__tcTestWalletEncrypt(\(js(clientId)), \(js(responseJSON)))")?.toString() ?? ""
                return "{\"from\":\"\(walletPub)\",\"message\":\"\(encrypted)\"}"
            }
            if let responseFrame {
                // The reply must land AFTER the POST it answers has completed. The
                // SDK awaits gateway.send() and only then registers the pending
                // request (pendingRequests.set after the yield); a reply that beats
                // the POST's completion finds no ticket and is dropped, and signData
                // never settles. This handler runs inside the POST's startLoading,
                // so a synchronous push is exactly that early - on the simulator the
                // SSE path won the race often enough to hang the suite (2026-09-07).
                // A real wallet answers after the request has been delivered, which
                // is what the delay models; the native engine registers its ticket
                // before posting and does not depend on this ordering.
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                    E2EFakeBridge.pushFrame(id: "2", data: responseFrame)
                }
            }
        }
    }

    struct JSCoreEngineFactory: EngineFactory {
        let label = "JSCoreEngine+FakeBridge"
        func makeEngine() async throws -> any TonConnectEngine {
            E2EFakeBridge.reset()
            var script = E2EFakeBridge.Script()
            script.keepEventsStreamOpen = true
            E2EFakeBridge.script = script
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [E2EFakeBridge.self]
            let engine = try JSCoreEngine(
                manifestUrl: "https://example.com/tonconnect-manifest.json",
                storage: InMemoryStorage(),
                opener: SpyOpener(),
                bridge: JSCoreBridge(transportConfiguration: config)
            )
            FakeBridgeE2ETests.attachWalletSimulator(to: engine.bridge)
            return engine
        }
    }

    @Test func testJSCoreEngineAgainstFakeBridgePassesConformanceSuite() async throws {
        try await EngineConformanceSuite.runAll(factory: JSCoreEngineFactory())
    }
}
