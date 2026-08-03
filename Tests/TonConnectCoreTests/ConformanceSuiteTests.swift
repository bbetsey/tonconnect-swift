import Foundation
import Testing
import TonConnectCore
import TonConnectConformance

struct ConformanceSuiteTests {

    // MARK: - FakeEngine double

    @Test func testFakeEngineConnectReturnsCannedSuccessAndRecordsCall() async throws {
        let engine = FakeEngine()
        let source = WalletConnectionSource(
            universalLink: "https://app.tonkeeper.com/ton-connect",
            bridgeUrl: "https://bridge.tonapi.io/bridge"
        )
        let event = try await engine.connect(source: source, items: [.tonProof(payload: "challenge")])
        #expect(event == FakeEngine.defaultConnectEvent)
        #expect(engine.recordedCalls == ["connect"])
        #expect(engine.lastConnectSource == source)
        #expect(engine.lastConnectItems == [.tonProof(payload: "challenge")])
    }

    @Test func testFakeEngineDisconnectRecordsCallAndClearsSession() async throws {
        let engine = FakeEngine()
        _ = try await engine.connect(
            source: WalletConnectionSource(universalLink: "https://e.com/tc", bridgeUrl: "https://e.com/bridge"),
            items: []
        )
        try await engine.disconnect()
        #expect(engine.recordedCalls == ["connect", "disconnect"])
        #expect(engine.hasSavedSession == false)
    }

    @Test func testFakeEngineInjectDeliversEventViaAsyncStream() async throws {
        let engine = FakeEngine()
        engine.inject(.disconnected)
        var received: TonConnectEvent?
        for await event in engine.events {
            received = event
            break
        }
        #expect(received == .disconnected)
    }

    @Test func testFakeEngineSendTransactionReturnsCannedSuccess() async throws {
        let engine = FakeEngine()
        let payload = SendTransactionPayload(validUntil: nil, network: nil, from: nil, messages: [])
        let response = try await engine.sendTransaction(payload)
        #expect(response == .success(result: "te6ccFakeBoc", id: "1"))
    }

    // MARK: - Engine conformance suite vs FakeEngine 

    struct FakeEngineFactory: EngineFactory {
        let label = "FakeEngine"
        func makeEngine() async throws -> any TonConnectEngine { FakeEngine() }
    }

    @Test func testFakeEnginePassesFullEngineConformanceSuite() async throws {
        try await EngineConformanceSuite.runAll(factory: FakeEngineFactory())
    }
}
