import Foundation
import Testing
import TonConnectCore

/// Reusable engine conformance suite (mechanism).
///
/// Suite contract for factories: makeEngine() returns a FRESH engine with no
/// saved session, primed deterministically so that connect() succeeds,
/// sendTransaction() returns .success, signData() returns a typed .error,
/// and disconnect() emits .disconnected on the events stream.
///
/// Runner-style API (public static funcs) instead of @Test(arguments:):
/// @Test arguments are fixed at the declaration site, so a library-declared
/// @Test cannot receive factories from an importing test target. Each engine's
/// test target declares thin @Test wrappers that call these runners.
public enum EngineConformanceSuite {

    /// Runs every conformance check against the factory's engine.
    public static func runAll(factory: any EngineFactory) async throws {
        try await runConnectHappyPathReturnsSuccessEvent(factory: factory)
        try await runRestoreAfterConnectSucceeds(factory: factory)
        try await runRestoreWithoutSessionThrowsTypedError(factory: factory)
        try await runDisconnectEmitsDisconnectedEvent(factory: factory)
        try await runSendTransactionReturnsTypedSuccess(factory: factory)
        try await runSignDataErrorIsTyped(factory: factory)
    }

    public static func runConnectHappyPathReturnsSuccessEvent(factory: any EngineFactory) async throws {
        let engine = try await factory.makeEngine()
        let event = try await engine.connect(source: source, items: [.tonAddress(network: nil)])
        guard case .success = event else {
            Issue.record("[\(factory.label)] connect() must return ConnectEvent.success, got \(event)")
            return
        }
    }

    public static func runRestoreAfterConnectSucceeds(factory: any EngineFactory) async throws {
        let engine = try await factory.makeEngine()
        _ = try await engine.connect(source: source, items: [.tonAddress(network: nil)])
        try await engine.restoreConnection()
    }

    public static func runRestoreWithoutSessionThrowsTypedError(factory: any EngineFactory) async throws {
        let engine = try await factory.makeEngine()
        await #expect(throws: TonConnectError.self) {
            try await engine.restoreConnection()
        }
    }

    public static func runDisconnectEmitsDisconnectedEvent(factory: any EngineFactory) async throws {
        let engine = try await factory.makeEngine()
        _ = try await engine.connect(source: source, items: [.tonAddress(network: nil)])
        try await engine.disconnect()
        let received = await awaitEvent({ $0 == .disconnected }, from: engine)
        #expect(received, "[\(factory.label)] disconnect() must emit .disconnected on the events stream")
    }

    public static func runSendTransactionReturnsTypedSuccess(factory: any EngineFactory) async throws {
        let engine = try await factory.makeEngine()
        _ = try await engine.connect(source: source, items: [.tonAddress(network: nil)])
        // The protocol-valid minimum: the live SDK requires the user-friendly address
        // form (base64url with a checksum) and non-empty messages; FakeEngine is payload-agnostic.
        let payload = SendTransactionPayload(
            validUntil: nil, network: nil, from: nil,
            messages: [SendTransactionPayload.Message(
                address: "UQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAJKZ", // the zero address, SDK checksum
                amount: "1", payload: nil, stateInit: nil
            )]
        )
        let response = try await engine.sendTransaction(payload)
        guard case .success = response else {
            Issue.record("[\(factory.label)] primed sendTransaction() must return .success, got \(response)")
            return
        }
    }

    public static func runSignDataErrorIsTyped(factory: any EngineFactory) async throws {
        let engine = try await factory.makeEngine()
        _ = try await engine.connect(source: source, items: [.tonAddress(network: nil)])
        let response = try await engine.signData(.text(text: "probe", network: nil, from: nil))
        guard case .error = response else {
            Issue.record("[\(factory.label)] primed signData() must surface a typed .error, got \(response)")
            return
        }
    }

    // MARK: - Helpers

    static let source = WalletConnectionSource(
        universalLink: "https://app.tonkeeper.com/ton-connect",
        bridgeUrl: "https://bridge.tonapi.io/bridge"
    )

    /// Awaits the first event matching the predicate, bounded by a timeout so a
    /// silent engine fails the assertion instead of hanging the test run.
    static func awaitEvent(
        _ predicate: @escaping @Sendable (TonConnectEvent) -> Bool,
        from engine: any TonConnectEngine,
        timeoutNanoseconds: UInt64 = 2_000_000_000
    ) async -> Bool {
        await withTaskGroup(of: Bool.self) { group in
            group.addTask {
                for await event in engine.events where predicate(event) { return true }
                return false
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: timeoutNanoseconds)
                return false
            }
            let first = await group.next() ?? false
            group.cancelAll()
            return first
        }
    }
}

/// Empirical probe: if this @Test shows
/// up in `swift test` output, library-target @Tests are discovered transitively
/// through the linking test target.
@Suite struct ConformanceLibraryDiscoveryProbe {
    @Test func testLibraryTargetTestsAreDiscoveredBySwiftTest() {
        #expect(Bool(true))
    }
}
