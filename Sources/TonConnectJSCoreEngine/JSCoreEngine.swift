import Foundation
import JavaScriptCore
import TonConnectCore
import TonConnectTransport
#if canImport(UIKit)
import UIKit
#endif

/// Stage 1 live engine: TonConnectEngine on top of JSCoreBridge + the vendored SDK.
/// connect(source:) — synchronous link generation,
/// events — a single __tcEmitEvent pump → AsyncStream,
/// the session is assembled by the SDK itself via StorageBridge,
/// lifecycle → pause/unpause, errors → 3 families.
public final class JSCoreEngine: TonConnectEngine, @unchecked Sendable {
    public let events: AsyncStream<TonConnectEvent>

    private let eventContinuation: AsyncStream<TonConnectEvent>.Continuation
    internal let bridge: JSCoreBridge // internal: 03-09/tests
    internal let lifecycle: LifecyclePolyfill // internal: simulateWake in tests, 03-09
    private let opener: any WalletOpener
    private let lock = NSLock()
    private var pendingConnect: CheckedContinuation<ConnectEvent, Error>?
    private var lifecycleObservers: [NSObjectProtocol] = []
    private let returnStrategy: ReturnStrategy

    public init(manifestUrl: String,
                storage: any TonConnectStorage,
                opener: any WalletOpener,
                returnStrategy: ReturnStrategy = .back,
                bridge: JSCoreBridge = JSCoreBridge()) throws {
        var continuation: AsyncStream<TonConnectEvent>.Continuation!
        self.events = AsyncStream { continuation = $0 }
        self.eventContinuation = continuation
        self.bridge = bridge
        self.opener = opener
        self.returnStrategy = returnStrategy
        self.lifecycle = LifecyclePolyfill(bridge: bridge)
        try bridge.loadBundle()
        // Order is mandatory: the glue expects the native functions BEFORE __tcCreateEngine.
        bridge.perform { ctx in
            StorageBridge(storage: storage, bridge: bridge).install(into: ctx)
            self.installEventReceiver(into: ctx)
            _ = ctx.evaluateScript("__tcCreateEngine(\(Self.jsString(manifestUrl)))")
        }
        if let exception = bridge.lastException {
            throw TonConnectError.internalError(message: "engine bootstrap failed: \(exception)")
        }
        subscribeToAppLifecycle()
    }

    deinit {
        eventContinuation.finish()
        for observer in lifecycleObservers { NotificationCenter.default.removeObserver(observer) }
    }

    // MARK: - connect

    public func connect(source: WalletConnectionSource, items: [ConnectItem]) async throws -> ConnectEvent {
        let sourceJSON: String
        do { sourceJSON = try Self.encodeJSON(source) }
        catch { throw EngineErrorMapper.map(error) }
        return try await performConnect(sourceJSON: sourceJSON, items: items, opensWallet: true)
    }

    /// Universal QR connect: the glue is transparent — the [{bridgeUrl}] array goes
    /// into sdk.connect as-is, which returns a tc:// link. The wallet is not opened.
    public func connectUniversal(bridgeURLs: [String], items: [ConnectItem]) async throws -> ConnectEvent {
        let sourceJSON: String
        do {
            let data = try JSONSerialization.data(withJSONObject: bridgeURLs.map { ["bridgeUrl": $0] })
            sourceJSON = String(decoding: data, as: UTF8.self)
        } catch { throw EngineErrorMapper.map(error) }
        return try await performConnect(sourceJSON: sourceJSON, items: items, opensWallet: false)
    }

    private func performConnect(sourceJSON: String, items: [ConnectItem], opensWallet: Bool) async throws -> ConnectEvent {
        let requestJSON = Self.buildRequestJSON(from: items) // ton_proof → {"tonProof":...}

        // SYNCHRONOUS prefix: queue.sync (bridge.perform), NOT await — no suspension
        // points between the tap and open().
        let link: String = bridge.perform { ctx in
            let script = "__tcConnect(\(Self.jsString(sourceJSON)), \(requestJSON.map(Self.jsString) ?? "null"))"
            return ctx.evaluateScript(script)?.toString() ?? ""
        }
        guard !link.isEmpty, link != "undefined", let url = URL(string: link) else {
            throw TonConnectError.internalError(
                message: "connect link generation failed: \(bridge.lastException ?? "no JS exception")")
        }
        eventContinuation.yield(.connectLinkGenerated(url)) // for QR (UI) — clean, no ret
        if opensWallet {
            // ret=back (TON Connect spec): the wallet returns to the app after
            // approval/rejection. Only in the opened link — in a QR for a second
            // device "back" would point at the wrong app.
            opener.open(appendingReturnStrategy(to: url)) // BEFORE the first await
        }

        // First await: wait for the wallet's reply from the single event pump (no
        // timeout), but with honest cancellation: cancelling the Swift task
        // resolves the ticket with CancellationError — previously cancellation never
        // crossed the continuation and the facade hung in .connecting forever
        // (on-device, 2026-07-19). A repeated connect while one is pending resolves
        // the OLD ticket with cancellation instead of silently overwriting it
        // ("performConnect leaked its continuation").
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                lock.lock()
                let previous = pendingConnect
                pendingConnect = continuation
                lock.unlock()
                previous?.resume(throwing: CancellationError())
                // Race: cancellation may arrive BEFORE the ticket lands in
                // pendingConnect — onCancel has already run to no effect.
                // Re-check the flag after registering.
                if Task.isCancelled {
                    resolvePendingConnect(.failure(CancellationError()))
                }
            }
        } onCancel: {
            resolvePendingConnect(.failure(CancellationError()))
        }
    }

    // MARK: - restore

    /// The SDK assembles the session from storage itself (Keychain in production).
    /// Success delivers the account via the .connected event through the event pump —
    /// agreed with the facade.
    public func restoreConnection() async throws {
        do { _ = try await bridge.awaitPromise { ctx in ctx.evaluateScript("__tcRestore()")! } }
        catch { throw EngineErrorMapper.map(error) }
        // The SDK finishes restore asynchronously (race — observed on device):
        // poll connected with a ~2s ceiling instead of an instant check.
        for _ in 0..<40 {
            let connected = bridge.perform { ctx in
                ctx.evaluateScript("__tcIsConnected()")?.toBool() ?? false
            }
            if connected { return }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        throw TonConnectError.decodeFailure("no saved session to restore")
    }

    // MARK: - RPC + honest cancellation

    public func sendTransaction(_ payload: SendTransactionPayload) async throws -> WalletResponse {
        let json: String
        do { json = try Self.encodeJSON(payload) } // messages form, NOT items
        catch { throw EngineErrorMapper.map(error) }
        do {
            let raw = try await awaitCancellable { ctx, signal in
                ctx.objectForKeyedSubscript("__tcSendTransaction")!.call(withArguments: [json, signal])!
            }
            return Self.walletSuccess(fromRPCResultJSON: raw)
        } catch {
            if let declined = Self.walletDeclined(from: error) { return declined } // typed, not a throw
            throw EngineErrorMapper.map(error)
        }
    }

    public func signData(_ payload: SignDataPayload) async throws -> WalletResponse {
        let json: String
        do { json = try Self.encodeJSON(payload) }
        catch { throw EngineErrorMapper.map(error) }
        do {
            let raw = try await awaitCancellable { ctx, signal in
                ctx.objectForKeyedSubscript("__tcSignData")!.call(withArguments: [json, signal])!
            }
            return .success(result: raw, id: "0")
        } catch {
            if let declined = Self.walletDeclined(from: error) { return declined }
            throw EngineErrorMapper.map(error)
        }
    }

    public func disconnect() async throws {
        do { _ = try await bridge.awaitPromise { ctx in ctx.evaluateScript("__tcDisconnect()")! } }
        catch { throw EngineErrorMapper.map(error) }
        eventContinuation.yield(.disconnected) // the conformance suite expects the event on the stream
    }

    /// Cancelling a Swift Task does NOT cross the runtime boundary
    /// on its own. Create a JS AbortController, pass its signal into the SDK call,
    /// and onCancel invoke .abort() on the JS queue — the SDK tears down fetch/SSE
    /// (the polyfill carries it through to NativeFetchTask.cancel()).
    private func awaitCancellable(_ call: @escaping (_ ctx: JSContext, _ signal: JSValue) -> JSValue) async throws -> String {
        let controllerBox = bridge.perform { ctx -> JSManagedValue in
            let controller = ctx.evaluateScript("new AbortController()")!
            return JSManagedValue(value: controller, andOwner: ctx)
        }
        return try await withTaskCancellationHandler {
            try await bridge.awaitPromise { ctx in
                let signal = controllerBox.value!.objectForKeyedSubscript("signal")!
                return call(ctx, signal)
            }
        } onCancel: {
            bridge.enqueue { _ = controllerBox.value?.invokeMethod("abort", withArguments: []) }
        }
    }

    /// RPC success: the SDK unwraps the protocol envelope itself — a {boc:...} JSON arrives.
    /// The SDK abstracts the protocol id away — synthetic "0" (like id=0 in the connect event).
    private static func walletSuccess(fromRPCResultJSON raw: String) -> WalletResponse {
        if let data = raw.data(using: .utf8),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let boc = object["boc"] as? String {
            return .success(result: boc, id: "0")
        }
        return .success(result: raw, id: "0")
    }

    /// A wallet rejection is a TYPED WalletResponse.error, not an exception.
    private static func walletDeclined(from error: Error) -> WalletResponse? {
        guard case JSBridgeError.jsException(let message) = error,
              message.range(of: #"(?i)user reject|declined"#, options: .regularExpression) != nil else {
            return nil
        }
        return .error(code: .userDeclined, message: message, id: "0")
    }

    // MARK: - event pump (the single source)

    /// __tcEmitEvent from the glue. [weak self] — otherwise a retain cycle
    /// engine→bridge→context→block→engine (DeinitLeakTests).
    private func installEventReceiver(into context: JSContext) {
        let receive: @convention(block) (String) -> Void = { [weak self] json in
            self?.handleGlueEvent(json)
        }
        context.setObject(receive, forKeyedSubscript: "__tcEmitEvent" as NSString)
    }

    private struct GlueEvent: Decodable {
        let kind: String
        let wallet: GlueWallet?
        let message: String?
    }
    private struct GlueWallet: Decodable {
        let device: DeviceInfo
        let account: GlueAccount
    }
    private struct GlueAccount: Decodable {
        let address: String
        let chain: String
        let publicKey: String?
        let walletStateInit: String?
    }

    /// Runs on the JS queue (the glue calls __tcEmitEvent from there). No JSValue
    /// makes it here — the glue passed a ready JSON string.
    private func handleGlueEvent(_ json: String) {
        guard let data = json.data(using: .utf8),
              let event = try? JSONDecoder().decode(GlueEvent.self, from: data) else {
            resolvePendingConnect(.failure(TonConnectError.internalError(message: "unparseable glue event: \(json)")))
            return
        }
        switch event.kind {
        case "status":
            if let wallet = event.wallet {
                let connectEvent = Self.connectEvent(from: wallet)
                eventContinuation.yield(.connected(connectEvent))
                resolvePendingConnect(.success(connectEvent))
            } else {
                eventContinuation.yield(.disconnected) // the wallet tore the session down itself
            }
        case "error":
            resolvePendingConnect(.failure(EngineErrorMapper.classifyMessage(event.message ?? "unknown JS error")))
        default:
            break
        }
    }

    /// Exactly one resume: the pending ticket is taken under the lock and nilled before resolving.
    private func resolvePendingConnect(_ result: Result<ConnectEvent, Error>) {
        lock.lock()
        let pending = pendingConnect
        pendingConnect = nil
        lock.unlock()
        guard let pending else { return }
        switch result {
        case .success(let event): pending.resume(returning: event)
        case .failure(let error): pending.resume(throwing: error)
        }
    }

    /// Test seam: a connect is already pending, awaiting the wallet's reply.
    internal var hasPendingConnect: Bool {
        lock.lock(); defer { lock.unlock() }
        return pendingConnect != nil
    }

    /// The SDK's wallet object (onStatusChange) → ConnectEvent.success. Synthetic
    /// id (0): the SDK has already protocol-validated the reply; what matters
    /// outward is the payload.
    private static func connectEvent(from wallet: GlueWallet) -> ConnectEvent {
        .success(
            id: 0,
            payload: ConnectSuccessPayload(
                items: [.tonAddress(TonAddressItemReply(
                    address: wallet.account.address,
                    network: wallet.account.chain,
                    publicKey: wallet.account.publicKey ?? "",
                    walletStateInit: wallet.account.walletStateInit ?? ""
                ))],
                device: wallet.device
            ),
            response: nil
        )
    }

    // MARK: - lifecycle

    private func subscribeToAppLifecycle() {
        #if canImport(UIKit)
        let center = NotificationCenter.default
        lifecycleObservers = [
            center.addObserver(forName: UIApplication.willResignActiveNotification,
                               object: nil, queue: .main) { [weak self] _ in
                self?.lifecycle.pause()
            },
            center.addObserver(forName: UIApplication.didBecomeActiveNotification,
                               object: nil, queue: .main) { [weak self] _ in
                self?.lifecycle.unpause()
            },
        ]
        #endif
    }

    // MARK: - helpers

    private struct AdditionalRequest: Encodable { let tonProof: String }

    /// ton_proof from items → JSON for __tcConnect; no proof → nil (the glue receives null).
    private static func buildRequestJSON(from items: [ConnectItem]) -> String? {
        for item in items {
            if case .tonProof(let payload) = item,
               let data = try? JSONEncoder().encode(AdditionalRequest(tonProof: payload)) {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }

    private static func encodeJSON<T: Encodable>(_ value: T) throws -> String {
        let data = try JSONEncoder().encode(value)
        guard let json = String(data: data, encoding: .utf8) else {
            throw TonConnectError.internalError(message: "JSON encoding produced non-UTF8")
        }
        return json
    }

    /// Safe string interpolation into evaluateScript: JSON encoding yields a
    /// correctly escaped JS literal (script-injection protection).
    private static func jsString(_ value: String) -> String {
        if let data = try? JSONEncoder().encode([value]),
           let json = String(data: data, encoding: .utf8) {
            return String(json.dropFirst().dropLast()) // ["..."] → "..."
        }
        return "\"\""
    }

    /// Appends ret=<strategy> to the wallet's universal link (auto-return).
    /// Telegram links need their own transport — see WalletLink.
    private func appendingReturnStrategy(to url: URL) -> URL {
        WalletLink.appendingReturnStrategy(returnStrategy.queryValue, to: url)
    }
}
