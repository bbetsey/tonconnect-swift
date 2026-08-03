import Foundation
import JavaScriptCore
import Testing
import TonConnectCore
import TonConnectTestSupport
@testable import TonConnectJSCoreEngine

private final class EngineTestFakeBridge: FakeBridgeURLProtocol {}

/// A wallet-opening spy — records the URL instead of UIApplication.open.
final class SpyOpener: WalletOpener, @unchecked Sendable {
    private let lock = NSLock()
    private var _openedURL: URL?
    var openedURL: URL? { lock.lock(); defer { lock.unlock() }; return _openedURL }
    func open(_ url: URL) { lock.lock(); _openedURL = url; lock.unlock() }
}

/// connect/restore against the FakeBridge (transport) + the event pump (the
/// wallet's reply). On a real bridge the wallet's reply is NaCl-box encrypted —
/// the honest full run through the SDK's crypto is done by the conformance E2E
/// (research Test Map). Here events are emitted into __tcEmitEvent
/// directly: we verify pump → continuation → mapping.
@Suite(.serialized) struct JSCoreEngineConnectTests {
    
    var returnStrategy: ReturnStrategy = .back

    static let source = WalletConnectionSource(
        universalLink: "https://wallet.test/ton-connect",
        bridgeUrl: "https://bridge.test/bridge"
    )

    private func makeEngine(
        storage: InMemoryStorage = InMemoryStorage(),
        returnStrategy: ReturnStrategy = .back
    ) throws
        -> (engine: JSCoreEngine, opener: SpyOpener) {
        EngineTestFakeBridge.script = EngineTestFakeBridge.Script()
        EngineTestFakeBridge.recordedRequestURLs = []
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [EngineTestFakeBridge.self]
        let opener = SpyOpener()
        let engine = try JSCoreEngine(
            manifestUrl: "https://example.com/tonconnect-manifest.json",
            storage: storage,
            opener: opener,
            returnStrategy: returnStrategy,
            bridge: JSCoreBridge(transportConfiguration: config)
        )
        return (engine, opener)
    }

    private func waitUntil(_ condition: () -> Bool, iterations: Int = 200) async {
        for _ in 0..<iterations where !condition() {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    /// Simulates the wallet's reply: what the SDK emits into onStatusChange on success.
    private func emitWalletConnectedEvent(on engine: JSCoreEngine) {
        engine.bridge.perform { ctx in
            _ = ctx.evaluateScript("""
                __tcEmitEvent(JSON.stringify({kind:'status', wallet:{
                  device:{platform:'iphone', appName:'FakeWallet', appVersion:'1.0.0', maxProtocolVersion:2, features:[]},
                  account:{address:'0:fake', chain:'-3', publicKey:'deadbeef', walletStateInit:'init'}
                }}))
                """)
        }
    }

    @Test func testConnectOpensWalletSynchronouslyBeforeAwaitingResult() async throws {
        let (engine, opener) = try makeEngine()
        let task = Task { try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)]) }
        // The link is generated synchronously (bridge.perform): the opener
        // receives the URL before any wallet event — none have been emitted yet.
        await waitUntil { engine.hasPendingConnect }
        let opened = try #require(opener.openedURL, "open() must be called BEFORE the first await")
        #expect(opened.host == "wallet.test", "the universal link is built from source")
        emitWalletConnectedEvent(on: engine) // resolve the pending connect
        _ = try await task.value
    }

    @Test func testConnectReturnsSuccessConnectEventWithTonAddress() async throws {
        let (engine, _) = try makeEngine()
        let task = Task { try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)]) }
        await waitUntil { engine.hasPendingConnect }
        emitWalletConnectedEvent(on: engine)
        let event = try await task.value
        guard case .success(_, let payload, _) = event else {
            Issue.record("expected .success, got \(event)")
            return
        }
        guard case .tonAddress(let reply) = payload.items.first else {
            Issue.record("expected ton_addr item first")
            return
        }
        #expect(reply.address == "0:fake")
        #expect(reply.network == "-3")
    }

    @Test func testConnectWithTonProofPassesProofInRequest() async throws {
        let (engine, opener) = try makeEngine()
        let task = Task {
            try await engine.connect(source: Self.source,
                                     items: [.tonAddress(network: nil), .tonProof(payload: "nonce123")])
        }
        await waitUntil { engine.hasPendingConnect }
        let opened = try #require(opener.openedURL)
        // The universal link carries r=<InitialRequest JSON> — the proof payload must be inside .
        #expect(opened.absoluteString.contains("nonce123"),
                "the ton_proof payload must go into the connect request, got \(opened)")
        emitWalletConnectedEvent(on: engine)
        _ = try await task.value
    }

    @Test func testRestoreConnectionWithSeededSessionSucceeds() async throws {
        let storage = InMemoryStorage()
        let hex64 = String(repeating: "11", count: 32)
        let seeded = """
        {"type":"http","connectEvent":{"event":"connect","id":1,"payload":{"items":[{"name":"ton_addr","address":"0:seeded","network":"-3","publicKey":"deadbeef","walletStateInit":"init"}],"device":{"platform":"iphone","appName":"FakeWallet","appVersion":"1.0.0","maxProtocolVersion":2,"features":[]}}},"session":{"sessionKeyPair":{"publicKey":"\(hex64)","secretKey":"\(String(repeating: "22", count: 32))"},"walletPublicKey":"\(String(repeating: "33", count: 32))","bridgeUrl":"https://bridge.test/bridge"},"lastWalletEventId":7,"nextRpcRequestId":1}
        """
        try await storage.set(seeded, forKey: "ton-connect-storage_bridge-connection")
        let (engine, _) = try makeEngine(storage: storage)

        try await engine.restoreConnection() // the SDK assembled the session from the blob itself
        // Proof that restore was not "silently skipped": the SDK reopened SSE to the bridge.
        await waitUntil {
            EngineTestFakeBridge.recordedRequestURLs.contains { $0.path.contains("/events") }
        }
        #expect(EngineTestFakeBridge.recordedRequestURLs.contains { $0.path.contains("/events") },
                "after restore the SDK must reopen GET /events")
    }

    @Test func testConnectErrorIsMappedToWalletDeclined() async throws {
        let (engine, _) = try makeEngine()
        let task = Task { try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)]) }
        await waitUntil { engine.hasPendingConnect }
        engine.bridge.perform { ctx in
            _ = ctx.evaluateScript(
                "__tcEmitEvent(JSON.stringify({kind:'error', message:'Error: User rejects the action in the wallet.'}))"
            )
        }
        do {
            _ = try await task.value
            Issue.record("connect should have thrown walletDeclined")
        } catch let error as TonConnectError {
            guard case .walletDeclined(let code, _) = error else {
                Issue.record("expected .walletDeclined, got \(error)")
                return
            }
            #expect(code == 300, "user reject → the spec's code 300")
        }
    }
    
    /// Honest cancellation: cancelling the Swift task wakes the pending
    /// connect with a CancellationError (previously — .connecting forever, on-device 2026-07-19).
    @Test func testCancellingConnectTaskResumesPendingConnectWithCancellationError() async throws {
        let (engine, _) = try makeEngine()
        let task = Task { try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)]) }
        await waitUntil { engine.hasPendingConnect }
        task.cancel()
        do {
            _ = try await task.value
            Issue.record("Expected a CancellationError after cancel()")
        } catch {
            #expect(error is CancellationError)
        }
        #expect(engine.hasPendingConnect == false)
    }

    /// The hole from the 2026-07-19 device log: a second connect used to overwrite
    /// the first one's ticket without a resume ("performConnect leaked its
    /// continuation"). Now the first attempt must finish with a CancellationError,
    /// the second — keep waiting for the wallet.
    @Test func testSecondConnectCancelsFirstPendingAttemptInsteadOfLeaking() async throws {
        let (engine, _) = try makeEngine()
        let first = Task { try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)]) }
        await waitUntil { engine.hasPendingConnect }
        let second = Task { try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)]) }
        do {
            _ = try await first.value
            Issue.record("Expected a CancellationError for the first attempt")
        } catch {
            #expect(error is CancellationError)
        }
        #expect(engine.hasPendingConnect) // the second attempt honestly waits
        second.cancel()
        _ = try? await second.value
    }
    
    /// Auto-return from the wallet: the opened connect link carries ret=back
    /// (the wallet returns to the app after approval/rejection — TON Connect spec).
    @Test func testConnectOpensWalletLinkWithRetBackReturnStrategy() async throws {
        let (engine, opener) = try makeEngine()
        let task = Task { try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)]) }
        await waitUntil { opener.openedURL != nil }
        #expect(opener.openedURL?.query?.contains("ret=back") == true)
        task.cancel()
        _ = try? await task.value
    }
    
    /// The iOS strategy: a ret with the app's own scheme goes into the opened link.
    @Test func testConnectAppendsCustomURLReturnStrategyToOpenedLink() async throws {
        let (engine, opener) = try makeEngine(returnStrategy: .url("tcharness://"))
        let task = Task { try await engine.connect(source: Self.source, items: [.tonAddress(network: nil)]) }
        await waitUntil { opener.openedURL != nil }
        #expect(opener.openedURL?.query?.contains("ret=tcharness://") == true)
        task.cancel()
        _ = try? await task.value
    }
}
