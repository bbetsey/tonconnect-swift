import SwiftUI

/// Liquid Glass adoption (iOS 26+/macOS 26+). The package keeps its iOS 16
/// baseline, so every glass touch goes through these availability-gated helpers —
/// older systems keep the exact pre-glass look. Sheet backgrounds need no code:
/// the system applies Liquid Glass to sheets automatically on 26+.
extension View {
    /// The brand capsule: tinted interactive Liquid Glass on 26+, the flat
    /// accent-color capsule below.
    @ViewBuilder
    func tcBrandCapsuleBackground() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.glassEffect(.regular.tint(Color.accentColor).interactive(), in: Capsule())
        } else {
            self.background(Color.accentColor, in: Capsule())
        }
    }

    /// A utility circle (header buttons, the modal's close cross): interactive
    /// Liquid Glass on 26+, the quaternary fill below.
    @ViewBuilder
    func tcCircleGlassBackground() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.glassEffect(.regular.interactive(), in: Circle())
        } else {
            self.background(.quaternary, in: Circle())
        }
    }

    /// Secondary action buttons (Retry, Show QR, Get a Wallet, Open wallet,
    /// Close): .glass on 26+, the gray bordered capsule below.
    @ViewBuilder
    func tcSecondaryButtonStyle() -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.buttonStyle(.glass)
                .buttonBorderShape(.capsule)
        } else {
            self.buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .tint(.gray)
        }
    }

    /// Primary CTA buttons: .glassProminent on 26+, borderedProminent below.
    @ViewBuilder
    func tcProminentButtonStyle(shape: ButtonBorderShape = .capsule) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            self.buttonStyle(.glassProminent)
                .buttonBorderShape(shape)
        } else {
            self.buttonStyle(.borderedProminent)
                .buttonBorderShape(shape)
        }
    }
}
