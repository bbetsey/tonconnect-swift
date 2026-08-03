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
}
