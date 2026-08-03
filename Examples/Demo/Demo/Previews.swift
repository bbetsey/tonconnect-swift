#if DEBUG
import SwiftUI
import TonConnectCore
import TonConnectUI

/// A toy engine for the Xcode canvas. It implements the PUBLIC TonConnectEngine
/// protocol from Core, so the previews never import a real engine — which also
/// proves the protocol is enough to build against. Operations "think" for a
/// moment and then succeed, so the screen can be clicked through with no network.
private final class PreviewEngine: TonConnectEngine, @unchecked Sendable {
    let events: AsyncStream<TonConnectEvent>
    private let continuation: AsyncStream<TonConnectEvent>.Continuation

    init(autoConnected: Bool) {
        var c: AsyncStream<TonConnectEvent>.Continuation!
        events = AsyncStream { c = $0 }
        continuation = c
        if autoConnected {
            // the event waits in the stream's buffer and connects the facade as soon as it is observed
            continuation.yield(.connected(Self.fakeConnectEvent))
        }
    }

    private static let fakeConnectEvent = ConnectEvent.success(
        id: 1,
        payload: ConnectSuccessPayload(
            items: [.tonAddress(TonAddressItemReply(
                // a valid TEP-2 vector, so userFriendlyAddress() produces a real
                // UQ… address and the truncated address on the button looks live
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

    func connect(source: WalletConnectionSource, items: [ConnectItem]) async throws -> ConnectEvent {
        continuation.yield(.connectLinkGenerated(URL(string: "https://app.tonkeeper.com/ton-connect?v=2&id=preview")!))
        try await Task.sleep(for: .seconds(1.5))        // long enough to see the connecting state
        return Self.fakeConnectEvent
    }

    func connectUniversal(bridgeURLs: [String], items: [ConnectItem]) async throws -> ConnectEvent {
        continuation.yield(.connectLinkGenerated(URL(string: "tc://preview-universal-qr")!))
        try await Task.sleep(for: .seconds(3600))       // the QR stays up for as long as you want to look at it
        throw TonConnectError.network(message: "preview never connects via QR")
    }

    func restoreConnection() async throws {
        throw TonConnectError.decodeFailure("no session in preview")
    }

    func sendTransaction(_ payload: SendTransactionPayload) async throws -> WalletResponse {
        try await Task.sleep(for: .seconds(1.2))        // long enough to see the pending sheet
        return .success(result: "te6ccPreviewBoc", id: "1")
    }

    func signData(_ payload: SignDataPayload) async throws -> WalletResponse {
        try await Task.sleep(for: .seconds(1.2))
        return .success(result: "te6ccPreviewSignature", id: "2")
    }

    func disconnect() async throws {
        continuation.yield(.disconnected)
    }
}

private struct DemoPreviewHost: View {
    @StateObject private var tonConnect: TonConnect

    init(connected: Bool) {
        _tonConnect = StateObject(wrappedValue: TonConnect(
            engine: PreviewEngine(autoConnected: connected),
            autoRestore: false))
    }

    var body: some View {
        ContentView().environmentObject(tonConnect)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        DemoPreviewHost(connected: true)
            .previewDisplayName("Connected (live ▶)")
        DemoPreviewHost(connected: false)
            .previewDisplayName("Disconnected")
        DemoPreviewHost(connected: true)
            .preferredColorScheme(.dark)
            .previewDisplayName("Connected (dark)")
    }
}
#endif
