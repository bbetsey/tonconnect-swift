#if DEBUG
import SwiftUI
import TonConnectCore

/// A toy engine for the canvas: connect "thinks" for 1.5s and connects a fake
/// account — the whole flow is clickable in live previews without a device or network.
private final class PreviewEngine: TonConnectEngine, @unchecked Sendable {
    let events: AsyncStream<TonConnectEvent>
    private let continuation: AsyncStream<TonConnectEvent>.Continuation

    init() {
        var c: AsyncStream<TonConnectEvent>.Continuation!
        events = AsyncStream { c = $0 }
        continuation = c
    }

    func connect(source: WalletConnectionSource, items: [ConnectItem]) async throws -> ConnectEvent {
        continuation.yield(.connectLinkGenerated(URL(string: "https://app.tonkeeper.com/ton-connect?v=2&id=preview-session")!))
        try await Task.sleep(for: .seconds(1.5)) // the waiting phase stays visible
        return ConnectEvent.success(
            id: 1,
            payload: ConnectSuccessPayload(
                items: [.tonAddress(TonAddressItemReply(
                    // a valid TEP-2 vector — the button renders a real truncated address
                    address: "0:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
                    network: "-3",
                    publicKey: "deadbeef",
                    walletStateInit: "te6ccPreviewInit"
                ))],
                device: DeviceInfo(platform: .iphone, appName: "PreviewWallet",
                                   appVersion: "1.0", maxProtocolVersion: 2, features: [])
            ),
            response: nil
        )
    }
    
    func connectUniversal(bridgeURLs: [String], items: [ConnectItem]) async throws -> ConnectEvent {
        continuation.yield(.connectLinkGenerated(URL(string: "tc://preview-universal-qr")!))
        try await Task.sleep(for: .seconds(3600)) // the QR stays up — tinker in the canvas as long as you like
        throw TonConnectError.network(message: "preview never connects via QR")
    }

    func restoreConnection() async throws {
        throw TonConnectError.decodeFailure("no session in preview")
    }

    func sendTransaction(_ payload: SendTransactionPayload) async throws -> WalletResponse {
        try await Task.sleep(for: .seconds(1.5)) // the pending toast stays visible
        return .success(result: "te6ccPreviewBoc", id: "1")
    }

    func signData(_ payload: SignDataPayload) async throws -> WalletResponse {
        try await Task.sleep(for: .seconds(1.5))
        return .error(code: .userDeclined, message: "declined in preview", id: "2")
    }

    func disconnect() async throws {
        continuation.yield(.disconnected)
    }
}

/// The full rig: button + overlay + operation probes (a mini-Harness).
private struct FullFlowPreviewHost: View {
    @StateObject private var tonConnect = TonConnect(engine: PreviewEngine(), autoRestore: false)

    var body: some View {
        VStack(spacing: 24) {
            TonConnectButton(tonConnect)
            Button("Probe: send → success") {
                Task { _ = try? await tonConnect.sendTransaction(
                    SendTransactionPayload(validUntil: nil, network: nil, from: nil, messages: [])) }
            }
            .disabled(!tonConnect.isConnected)
            Button("Probe: sign → declined") {
                Task { _ = try? await tonConnect.signData(.text(text: "probe", network: nil, from: nil)) }
            }
            .disabled(!tonConnect.isConnected)
        }
    }
}

/// The picker in a real sheet context — detents behave as on a device.
private struct SheetPreviewHost: View {
    @StateObject private var tonConnect = TonConnect(engine: PreviewEngine(), autoRestore: false)
    @State private var isPresented = true

    var body: some View {
        Button("Open wallet picker") { isPresented = true }
            .sheet(isPresented: $isPresented) {
                WalletPickerSheet(tonConnect: tonConnect)
            }
    }
}

struct TonConnectUIPreviews: PreviewProvider {
    static var previews: some View {
        FullFlowPreviewHost()
            .previewDisplayName("Full flow (live ▶)")
        SheetPreviewHost()
            .previewDisplayName("Picker sheet (detents)")
        SheetPreviewHost()
            .preferredColorScheme(.dark)
            .previewDisplayName("Picker sheet (dark)")
    }
}
#endif
