import Foundation
import Testing
import TonConnectCore
import TonConnectConformance

struct OperationStateMappingTests {

    // MARK: - thrown TonConnectError → visual outcome

    @Test func testFailureFromWalletDeclinedMapsToWalletDeclinedOutcome() {
        let outcome = OperationState.failure(from: TonConnectError.walletDeclined(code: 300, message: "x"))
        #expect(outcome == .walletDeclined(message: "x"))
    }

    @Test func testFailureFromNetworkErrorMapsToNetworkProblem() {
        let outcome = OperationState.failure(from: TonConnectError.network(message: "y"))
        #expect(outcome == .networkProblem(message: "y"))
    }

    @Test func testFailureFromInternalErrorMapsToNetworkProblem() {
        let outcome = OperationState.failure(from: TonConnectError.internalError(message: "z"))
        #expect(outcome == .networkProblem(message: "z"))
    }

    @Test func testFailureFromDecodeFailureMapsToNetworkProblem() {
        let outcome = OperationState.failure(from: TonConnectError.decodeFailure("d"))
        #expect(outcome == .networkProblem(message: "d"))
    }

    @Test func testFailureFromStorageFailureMapsToNetworkProblemWithNonEmptyMessage() {
        let outcome = OperationState.failure(from: TonConnectError.storageFailure(status: -34018))
        guard case .networkProblem(let message) = outcome else {
            Issue.record("expected networkProblem, got \(outcome)")
            return
        }
        #expect(!message.isEmpty)
    }

    /// A deadline that passed reads like a dropped connection: red, with a Retry.
    /// The user has nothing to correct, and the same request may well succeed.
    @Test func testFailureFromTimeoutMapsToNetworkProblemWithNonEmptyMessage() {
        let outcome = OperationState.failure(from: TonConnectError.timeout(after: .seconds(30)))
        guard case .networkProblem(let message) = outcome else {
            Issue.record("expected networkProblem, got \(outcome)")
            return
        }
        #expect(!message.isEmpty)
    }

    @Test func testFailureFromNonTonConnectErrorMapsToNetworkProblem() {
        struct SomeOtherError: Error {}
        let outcome = OperationState.failure(from: SomeOtherError())
        guard case .networkProblem = outcome else {
            Issue.record("expected networkProblem, got \(outcome)")
            return
        }
    }

    // MARK: - WalletResponse.error (RPC-level) → visual outcome

    @Test func testFailureFromUserDeclinedRPCCodeMapsToWalletDeclined() {
        let outcome = OperationState.failure(fromWalletResponseError: .userDeclined, message: "no")
        #expect(outcome == .walletDeclined(message: "no"))
    }

    @Test func testFailureFromBadRequestRPCCodeMapsToWalletError() {
        let outcome = OperationState.failure(fromWalletResponseError: .badRequest, message: "bad")
        #expect(outcome == .walletError(message: "bad"))
    }
    
    /// The live wire, verified on device 2026-08-03: Telegram Wallet answers a
    /// user rejection with the WRONG code and the RIGHT message.
    @Test func testFailureFromNonSpecCodeWithDeclineMessageMapsToWalletDeclined() {
        let outcome = OperationState.failure(fromWalletResponseError: .badRequest,
                                             message: "Wallet declined the request")
        #expect(outcome == .walletDeclined(message: "Wallet declined the request"))
    }

    @Test func testFailureFromDeclineMessageIsCaseInsensitive() {
        let outcome = OperationState.failure(fromWalletResponseError: .unknownError,
                                             message: "USER REJECTED THE TRANSACTION")
        #expect(outcome == .walletDeclined(message: "USER REJECTED THE TRANSACTION"))
    }

    @Test func testFailureFromCancelledMessageMapsToWalletDeclined() {
        let outcome = OperationState.failure(fromWalletResponseError: .unknown(42),
                                             message: "Cancelled by user")
        #expect(outcome == .walletDeclined(message: "Cancelled by user"))
    }

    @Test func testFailureFromGenuineWalletErrorMapsToWalletError() {
        let outcome = OperationState.failure(fromWalletResponseError: .badRequest,
                                             message: "Malformed transaction payload")
        #expect(outcome == .walletError(message: "Malformed transaction payload"))
    }

    // MARK: - Equatable distinguishes states

    @Test func testPendingDiffersFromSuccessForSameKind() {
        #expect(OperationState.pending(kind: .sendTransaction) != OperationState.success(kind: .sendTransaction))
    }

    /// The two red outcomes must never collapse into one: only networkProblem
    /// offers a Retry, and a wallet refusal would repeat into the same refusal.
    @Test func testWalletErrorDiffersFromNetworkProblemForTheSameMessage() {
        #expect(OperationState.walletError(message: "m") != OperationState.networkProblem(message: "m"))
    }
}

// MARK: - facade level: operation around send/sign (FakeEngine canned responses)

@MainActor
struct OperationFacadeTests {

    private func makePayload() -> SendTransactionPayload {
        SendTransactionPayload(validUntil: nil, network: nil, from: nil, messages: [])
    }

    @Test func testSendTransactionSetsOperationToSuccess() async throws {
        let facade = TonConnect(engine: FakeEngine(), autoRestore: false)
        _ = try await facade.sendTransaction(makePayload())
        #expect(facade.operation == .success(kind: .sendTransaction))
    }

    @Test func testSignDataWithUserDeclinedResponseSetsWalletDeclined() async throws {
        // FakeEngine's default canned reply for signData is .error(userDeclined)
        let facade = TonConnect(engine: FakeEngine(), autoRestore: false)
        _ = try await facade.signData(.text(text: "probe", network: nil, from: nil))
        #expect(facade.operation == .walletDeclined(message: "user declined"))
    }

    @Test func testSendTransactionWithRPCErrorSetsWalletError() async throws {
        let engine = FakeEngine()
        engine.cannedSendTransactionResponse = .error(code: .badRequest, message: "bad", id: "9")
        let facade = TonConnect(engine: engine, autoRestore: false)
        _ = try await facade.sendTransaction(makePayload())
        #expect(facade.operation == .walletError(message: "bad"))
    }

    /// The defect this overload exists for: a captured payload carries the
    /// `validUntil` computed at the first attempt, so a retry minutes later sends a
    /// transaction the wallet must reject as expired.
    @Test func testRetryWithAPayloadClosureRebuildsThePayload() async throws {
        let engine = FakeEngine()
        let facade = TonConnect(engine: engine, autoRestore: false)
        let builds = Counter()
        _ = try await facade.sendTransaction {
            builds.increment()
            return SendTransactionPayload(validUntil: builds.value, network: nil, from: nil, messages: [])
        }
        #expect(builds.value == 1)

        facade.retryLastOperation()
        for _ in 0..<200 {
            if builds.value == 2, facade.operation == .success(kind: .sendTransaction) { break }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        // Built a second time — a fresh validUntil went out, not the stale one.
        #expect(builds.value == 2)
    }

    /// The value overload keeps its old contract: the very same payload is resent.
    @Test func testRetryWithAPayloadValueResendsTheSamePayload() async throws {
        let engine = FakeEngine()
        let facade = TonConnect(engine: engine, autoRestore: false)
        let payload = SendTransactionPayload(validUntil: 42, network: nil, from: nil, messages: [])
        _ = try await facade.sendTransaction(payload)

        facade.retryLastOperation()
        for _ in 0..<200 {
            if engine.recordedCalls.filter({ $0 == "sendTransaction" }).count == 2 { break }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        #expect(engine.lastSentTransaction?.validUntil == 42)
    }

    @Test func testClearOperationResetsToNil() async throws {
        let facade = TonConnect(engine: FakeEngine(), autoRestore: false)
        _ = try await facade.sendTransaction(makePayload())
        facade.clearOperation()
        #expect(facade.operation == nil)
    }

    @Test func testRetryLastOperationRepeatsSend() async throws {
        let engine = FakeEngine()
        let facade = TonConnect(engine: engine, autoRestore: false)
        _ = try await facade.sendTransaction(makePayload())
        facade.retryLastOperation()
        // The retry runs in a detached Task, so the test polls instead of awaiting.
        // Wait for BOTH signals, not just the counter: FakeEngine records a call on
        // ENTRY, while the facade publishes .success only after the engine returns.
        // Polling the counter alone lands in that window and reads .pending — the
        // flake this loop replaces (2 red runs out of 9). A retry is not "done"
        // until the outcome is visible, so that is what the test waits for.
        //
        // Polling by state alone would not do either: operation is deliberately NOT
        // reset before a retry (the sheet lives continuously, with no nil→pending
        // blink), so the previous .success is already there and the wait returns
        // instantly, before the second call even starts.
        var sends: Int { engine.recordedCalls.filter { $0 == "sendTransaction" }.count }
        for _ in 0..<200 {
            if sends == 2, facade.operation == .success(kind: .sendTransaction) { break }
            try? await Task.sleep(nanoseconds: 5_000_000)   // ceiling: 1s
        }
        #expect(sends == 2)
        #expect(facade.operation == .success(kind: .sendTransaction))
    }
    
    @Test func testDisconnectClearsStaleOperation() async throws {
        let facade = TonConnect(engine: FakeEngine(), autoRestore: false)
        _ = try await facade.sendTransaction(makePayload())
        #expect(facade.operation != nil)
        try await facade.disconnect()
        #expect(facade.operation == nil)
    }

    // MARK: - timeout

    @Test func testSendTransactionWithTimeoutThrowsTimeoutAndCancelsTheEngineCall() async throws {
        let engine = HangingEngine()
        let facade = TonConnect(engine: engine, autoRestore: false)
        await #expect(throws: TonConnectError.timeout(after: .milliseconds(50))) {
            _ = try await facade.sendTransaction(makePayload(), timeout: .milliseconds(50))
        }
        // The loser of the race is cancelled, not abandoned: the engine saw it.
        for _ in 0..<200 where engine.cancellations == 0 {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        #expect(engine.cancellations == 1)
    }

    /// The UI contract: a deadline that passed is shown as a connection problem,
    /// which is the outcome that carries a Retry.
    @Test func testSendTransactionTimeoutSetsOperationToNetworkProblem() async {
        let facade = TonConnect(engine: HangingEngine(), autoRestore: false)
        _ = try? await facade.sendTransaction(makePayload(), timeout: .milliseconds(50))
        guard case .networkProblem = facade.operation else {
            Issue.record("expected networkProblem, got \(String(describing: facade.operation))")
            return
        }
    }

    @Test func testSignDataWithTimeoutThrowsTimeout() async {
        let facade = TonConnect(engine: HangingEngine(), autoRestore: false)
        await #expect(throws: TonConnectError.timeout(after: .milliseconds(50))) {
            _ = try await facade.signData(.text(text: "probe", network: nil, from: nil),
                                          timeout: .milliseconds(50))
        }
    }

    /// A deadline that is not reached changes nothing: the answer comes back as
    /// it always did, and the timer is cancelled rather than left running.
    @Test func testTimeoutThatIsNotReachedLeavesTheAnswerUntouched() async throws {
        let facade = TonConnect(engine: FakeEngine(), autoRestore: false)
        let response = try await facade.sendTransaction(makePayload(), timeout: .seconds(30))
        #expect(response == .success(result: "te6ccFakeBoc", id: "1"))
        #expect(facade.operation == .success(kind: .sendTransaction))
    }

    /// The contract before this parameter existed, kept verbatim for `nil`:
    /// the call waits, and only cancelling the Task ends it.
    @Test func testSendTransactionWithoutTimeoutEndsOnlyWithTaskCancellation() async throws {
        let engine = HangingEngine()
        let facade = TonConnect(engine: engine, autoRestore: false)
        let payload = makePayload()
        let call = Task { try await facade.sendTransaction(payload) }
        for _ in 0..<200 where engine.calls == 0 {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        #expect(engine.calls == 1, "the engine call started")
        call.cancel()
        await #expect(throws: CancellationError.self) { _ = try await call.value }
    }

    /// Retry repeats the request under the same deadline it was given.
    @Test func testRetryLastOperationReusesTheTimeout() async throws {
        let engine = HangingEngine()
        let facade = TonConnect(engine: engine, autoRestore: false)
        _ = try? await facade.sendTransaction(makePayload(), timeout: .milliseconds(50))
        #expect(engine.cancellations == 1)

        facade.retryLastOperation()
        for _ in 0..<200 where engine.cancellations < 2 {
            try? await Task.sleep(nanoseconds: 5_000_000)   // ceiling: 1s ≫ 50ms
        }
        #expect(engine.cancellations == 2, "the retry timed out too — it carried the deadline")
    }
}

/// An engine that never answers. Every wallet round trip sleeps until its Task is
/// cancelled and then rethrows the CancellationError, the way both real engines
/// resolve a pending ticket on cancel. Records how many calls started and how many
/// were cancelled, so a test can tell "timed out and cleaned up" from "timed out
/// and left the request hanging".
final class HangingEngine: TonConnectEngine, @unchecked Sendable {
    let events: AsyncStream<TonConnectEvent>
    private let continuation: AsyncStream<TonConnectEvent>.Continuation
    private let lock = NSLock()
    private var _calls = 0
    private var _cancellations = 0

    var calls: Int { lock.withLock { _calls } }
    var cancellations: Int { lock.withLock { _cancellations } }

    init() {
        var continuation: AsyncStream<TonConnectEvent>.Continuation!
        self.events = AsyncStream { continuation = $0 }
        self.continuation = continuation
    }

    private func hang<T>() async throws -> T {
        lock.withLock { _calls += 1 }
        do {
            while true { try await Task.sleep(nanoseconds: 1_000_000_000) }
        } catch {
            lock.withLock { _cancellations += 1 }
            throw error
        }
    }

    func connect(source: WalletConnectionSource, items: [ConnectItem]) async throws -> ConnectEvent {
        try await hang()
    }
    func connectUniversal(bridgeURLs: [String], items: [ConnectItem]) async throws -> ConnectEvent {
        try await hang()
    }
    func restoreConnection() async throws {
        throw TonConnectError.decodeFailure("no saved session to restore")
    }
    func sendTransaction(_ payload: SendTransactionPayload) async throws -> WalletResponse {
        try await hang()
    }
    func signData(_ payload: SignDataPayload) async throws -> WalletResponse {
        try await hang()
    }
    func disconnect() async throws {}
}

/// A tiny thread-safe counter. The payload closure is @Sendable — it cannot reach
/// main-actor state — so the counter carries its own lock.
final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = 0
    var value: Int { lock.lock(); defer { lock.unlock() }; return _value }
    func increment() { lock.lock(); _value += 1; lock.unlock() }
}
