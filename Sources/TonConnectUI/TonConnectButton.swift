import SwiftUI
import TonConnectCore
#if canImport(UIKit)
import UIKit
#endif

/// The wallet-connect button — "one line = a working flow".
/// The facade is passed EXPLICITLY in init — a forgotten .environmentObject
/// would be a runtime crash for the consumer, while a missing parameter is a
/// compile error. The shape is constant across all states (@tonconnect/ui parity):
/// one capsule, only the content changes — glyph+CTA / spinner / glyph+address with a menu.
public struct TonConnectButton: View {
    @ObservedObject private var tonConnect: TonConnect
    @State private var isPickerPresented = false

    /// - Parameter tonConnect: the facade this button drives. Passing it here
    ///   rather than reading it from the environment turns a forgotten
    ///   dependency into a compile error instead of a crash.
    public init(_ tonConnect: TonConnect) {
        self.tonConnect = tonConnect
    }

    public var body: some View {
        Group {
            switch tonConnect.state {
            case .disconnected:
                Button {
                    isPickerPresented = true
                } label: {
                    capsuleContent {
                        tonGlyph
                        Text("Connect Wallet")
                    }
                }
                .buttonStyle(.plain)
            case .restoring, .connecting:
                capsuleContent {
                    TCSpinner(size: 16, color: .white)
                    Text("Connecting…")
                }
            case .connected(let account):
                Menu {
                    Button("Copy Address") {
                        #if canImport(UIKit)
                        UIPasteboard.general.string = account.userFriendlyAddress() ?? account.address
                        #endif
                    }
                    Button("Disconnect", role: .destructive) {
                        Task { try? await tonConnect.disconnect() }
                    }
                } label: {
                    capsuleContent {
                        tonGlyph
                        Text(displayAddress(account))
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .opacity(0.7)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.default, value: tonConnect.state)
        .sheet(isPresented: $isPickerPresented) {
            WalletPickerSheet(tonConnect: tonConnect)
        }
    }

    /// The constant button body: height, font and the capsule are state-independent.
    private func capsuleContent(@ViewBuilder _ content: () -> some View) -> some View {
        HStack(spacing: 8) { content() }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .frame(height: 48)
            .tcBrandCapsuleBackground()
    }

    private var tonGlyph: some View {
        Image("TonGlyph", bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(height: 16)
    }

    /// Middle truncation: "UQAb…3xYz". Falls back to the raw prefix — no crashing.
    private func displayAddress(_ account: Account) -> String {
        guard let friendly = account.userFriendlyAddress() else {
            return String(account.address.prefix(6))
        }
        return truncatedMiddle(friendly)
    }

    private func truncatedMiddle(_ address: String) -> String {
        guard address.count > 8 else { return address }
        return "\(address.prefix(4))…\(address.suffix(4))"
    }
}
