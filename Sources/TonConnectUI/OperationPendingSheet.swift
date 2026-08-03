import SwiftUI
import TonConnectCore
#if canImport(UIKit)
import UIKit
#endif

/// Operation modal (ActionsModal parity from @tonconnect/ui), now the single
/// status window for send/sign: pending → ~1.2s pause → jump to the wallet
/// (ret=back brings us back) → animated result. StatusOverlay is retired.
/// The cross/swipe: on pending it closes only the modal (the operation lives on),
/// on a result it acknowledges "seen" (clearOperation).
struct OperationPendingSheetModifier: ViewModifier {
    @ObservedObject var tonConnect: TonConnect
    @State private var isPresented = false

    func body(content: Content) -> some View {
        content
            .onChange(of: tonConnect.operation) { operation in
                isPresented = operation != nil
            }
            .sheet(isPresented: $isPresented, onDismiss: {
                if let operation = tonConnect.operation, !operation.isPendingState {
                    tonConnect.clearOperation() // swiping a result away = "seen"
                }
            }) {
                OperationSheet(tonConnect: tonConnect)
            }
    }
}

public extension View {
    /// Attached to the app root: one modal for all operations.
    func tonConnectOperationSheet(_ tonConnect: TonConnect) -> some View {
        modifier(OperationPendingSheetModifier(tonConnect: tonConnect))
    }
}

private extension OperationState {
    var isPendingState: Bool {
        if case .pending = self { return true }
        return false
    }
}

private struct OperationSheet: View {
    @ObservedObject var tonConnect: TonConnect
    @StateObject private var loader = WalletsListLoader()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    /// The operation we already jumped to the wallet for. `.task(id:)` restarts on
    /// every view re-appearance (returning from the wallet, a re-presented sheet),
    /// and a second wake deeplink resets wallets that show a "waiting for request"
    /// placeholder — the request screen visibly flips back to a skeleton.
    @State private var jumpedForOperation: OperationState?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.regular))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .tcCircleGlassBackground()
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)

            Spacer()

            Group {
                switch tonConnect.operation {
                case .pending(let kind):
                    pendingView(kind)
                case .success(let kind):
                    SuccessResultView(kind: kind)
                case .walletDeclined:
                    DeclinedResultView()
                case .networkProblem(let message):
                    NetworkProblemResultView(
                        message: message,
                        onRetry: { tonConnect.retryLastOperation() },
                        onClose: { dismiss() }
                    )
                case .walletError(let message):
                    WalletErrorResultView(message: message, onClose: { dismiss() })
                case nil:
                    EmptyView() // the brief moment of the dismiss animation
                }
            }
            .transition(.asymmetric(
                insertion: .scale(scale: 0.85).combined(with: .opacity),
                removal: .opacity
            ))

            Spacer()

            // Hidden when the consumer opted out of deeplinking into the wallet:
            // the button fires the very same wake link as the automatic jump.
            if case .pending = tonConnect.operation,
               tonConnect.opensWalletAutomatically,
               let link = walletReturnLink {
                Button { openURL(link) } label: {
                    Text("Open wallet")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .tcSecondaryButtonStyle()
                .padding(.bottom, 24)
            }
        }
        .overlay {
            if case .success = tonConnect.operation {
                ConfettiBurstView()
                    .ignoresSafeArea()
            }
        }
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.hidden)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: tonConnect.operation)
        .onAppear { loader.load() }
        // The timing conductor. id = operation: a state change cancels the old task
        // and starts a new one — the pre-wallet pause cannot outlive an arriving result.
        .task(id: tonConnect.operation) {
            switch tonConnect.operation {
            case .pending:
                // Exactly one wake per operation (see jumpedForOperation).
                guard jumpedForOperation != tonConnect.operation else { break }
                // SDK parity (onRequestSent → redirectAfterRequestSent): wake the
                // wallet only once the bridge accepted the request. Waking earlier
                // leaves wallets that show a "waiting for request" placeholder
                // spinning until they give up with "Dapp Not Responding" — and
                // backgrounding us mid-POST can stall the delivery itself.
                // The ceiling keeps engines that never emit .requestSent (JSCore)
                // on the previous timer-based behaviour.
                let deadline = Date().addingTimeInterval(5)
                while !tonConnect.isOperationRequestSent, Date() < deadline {
                    try? await Task.sleep(nanoseconds: 50_000_000)
                }
                // A short beat so the user can read the sheet before the jump.
                try? await Task.sleep(nanoseconds: 400_000_000)
                if case .pending = tonConnect.operation,
                   tonConnect.opensWalletAutomatically,
                   let link = walletReturnLink {
                    jumpedForOperation = tonConnect.operation
                    openURL(link)
                }
            case .success:
                // Auto-dismiss on success: checkmark animation (~0.6s) + time to "see" it.
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                tonConnect.clearOperation()
            default:
                break // declined/network wait for an explicit user action
            }
        }
    }

    private func pendingView(_ kind: OperationKind) -> some View {
        VStack(spacing: 0) {
            TCSpinner(size: 44)
                .padding(.bottom, 24)
            Text(pendingTitle(kind))
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
            Text("It will only take a moment.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
    }

    private func pendingTitle(_ kind: OperationKind) -> String {
        let wallet = tonConnect.connectedWalletName ?? "your wallet"
        return kind == .signData
            ? "Confirm the request\nin \(wallet)"
            : "Confirm the transaction\nin \(wallet)"
    }

    /// The link that wakes the connected wallet for the pending request
    /// (the Telegram special case lives in WalletsListEntry.wakeLink).
    private var walletReturnLink: URL? {
        guard let name = tonConnect.connectedWalletName else { return nil }
        return WalletsListEntry.matching(walletName: name, in: loader.wallets)?
            .wakeLink(returnStrategy: tonConnect.returnStrategy)
    }
}

// MARK: - results (steps 3-4)

/// Success: the ring draws around, then the checkmark strokes in with a spring.
private struct SuccessResultView: View {
    let kind: OperationKind
    @State private var ringProgress: CGFloat = 0
    @State private var checkProgress: CGFloat = 0
    @State private var badgeScale: CGFloat = 0.85

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .trim(from: 0, to: ringProgress)
                    .stroke(Color(.systemGreen), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 72, height: 72)
                CheckmarkShape()
                    .trim(from: 0, to: checkProgress)
                    .stroke(Color(.systemGreen), style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                    .frame(width: 34, height: 26)
            }
            .scaleEffect(badgeScale)
            .padding(.bottom, 24)

            Text(kind == .sendTransaction ? "Transaction sent" : "Data signed")
                .font(.title3.weight(.bold))
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { ringProgress = 1 }
            withAnimation(.easeOut(duration: 0.25).delay(0.3)) { checkProgress = 1 }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5).delay(0.3)) { badgeScale = 1 }
            notifyHaptic(.success)
        }
    }
}

/// Declined: a palm with a soft spring — neutral tone, the user changed their own mind.
private struct DeclinedResultView: View {
    @State private var scale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color(.systemOrange))
                .scaleEffect(scale)
                .padding(.bottom, 24)
            Text("Declined in wallet")
                .font(.title3.weight(.bold))
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { scale = 1 }
            notifyHaptic(.warning)
        }
    }
}

/// Network: a red glyph + Retry (the only outcome with a retry).
private struct NetworkProblemResultView: View {
    let message: String
    let onRetry: () -> Void
    let onClose: () -> Void
    @State private var scale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 52))
                .foregroundStyle(Color(.systemRed))
                .scaleEffect(scale)
                .padding(.bottom, 24)
            Text("Connection lost")
                .font(.title3.weight(.bold))
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.top, 4)
                .padding(.horizontal, 32)
            HStack(spacing: 12) {
                Button("Close") { onClose() }
                    .tcSecondaryButtonStyle()
                Button("Retry") { onRetry() }
                    .tcProminentButtonStyle()
            }
            .padding(.top, 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { scale = 1 }
            notifyHaptic(.error)
        }
    }
}

/// Wallet error: the wallet got the request and refused to carry it out. Red like
/// a network problem, but the only button is Close — Retry would send the very
/// same request into the very same refusal.
private struct WalletErrorResultView: View {
    let message: String
    let onClose: () -> Void
    @State private var scale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 52))
                .foregroundStyle(Color(.systemRed))
                .scaleEffect(scale)
                .padding(.bottom, 24)
            Text("Wallet couldn't complete it")
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
            // A wallet may send an error with no message at all (ErrorBody.message
            // is optional on the wire) — an empty caption would just push the button down.
            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .padding(.horizontal, 32)
            }
            Button("Close") { onClose() }
                .tcSecondaryButtonStyle()
                .padding(.top, 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) { scale = 1 }
            notifyHaptic(.error)
        }
    }
}

/// Checkmark: two strokes from the left edge down and up — trim draws it "by hand".
private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY + rect.height * 0.1))
        path.addLine(to: CGPoint(x: rect.width * 0.35, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

/// Result haptics — iOS-only; on macOS (tests) it compiles to a no-op.
private func notifyHaptic(_ type: HapticType) {
    #if canImport(UIKit)
    let generator = UINotificationFeedbackGenerator()
    switch type {
    case .success: generator.notificationOccurred(.success)
    case .warning: generator.notificationOccurred(.warning)
    case .error: generator.notificationOccurred(.error)
    }
    #endif
}
private enum HapticType { case success, warning, error }

// MARK: - confetti (success)

/// A one-shot confetti burst: Canvas + TimelineView, no third-party libraries.
/// Physics: initial velocity fanned upward + gravity; rotation and "flip"
/// (height squash) fake a paper piece's 3D tumble. Lives ~1.4s and fades.
private struct ConfettiBurstView: View {
    private struct Particle {
        let angle: Double // launch direction, rad (upward fan)
        let speed: Double // pt/s
        let size: CGSize
        let color: Color
        let spin: Double // rotation, rad/s
        let flip: Double // "flip" speed, rad/s
        let delay: Double // start jitter — the burst is not in lockstep
    }

    private let particles: [Particle]
    private let start = Date()
    private let lifetime: Double = 1.4
    private static let gravity: Double = 900 // pt/s²

    init(count: Int = 80) {
        let palette: [Color] = [
            Color(red: 0.0, green: 0.596, blue: 0.918),
            Color(.systemGreen), Color(.systemOrange),
            Color(.systemYellow), Color(.systemPink), Color(.systemPurple)
        ]
        particles = (0..<count).map { _ in
            Particle(
                angle: Double.random(in: (-Double.pi * 0.85)...(-Double.pi * 0.15)),
                speed: Double.random(in: 220...520),
                size: CGSize(width: Double.random(in: 5...9), height: Double.random(in: 8...14)),
                color: palette.randomElement()!,
                spin: Double.random(in: -6...6),
                flip: Double.random(in: 4...10),
                delay: Double.random(in: 0...0.12)
            )
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSince(start)
                guard t < lifetime else { return }
                let origin = CGPoint(x: size.width / 2, y: size.height * 0.42)
                for particle in particles {
                    let life = t - particle.delay
                    guard life > 0 else { continue }
                    let progress = life / (lifetime - particle.delay)
                    guard progress < 1 else { continue }

                    let x = origin.x + cos(particle.angle) * particle.speed * life
                    let y = origin.y + sin(particle.angle) * particle.speed * life
                            + 0.5 * Self.gravity * life * life
                    let flipScale = max(abs(cos(particle.flip * life)), 0.15)

                    var ctx = context
                    ctx.translateBy(x: x, y: y)
                    ctx.rotate(by: .radians(particle.spin * life))
                    ctx.opacity = progress > 0.7 ? (1 - progress) / 0.3 : 1
                    let rect = CGRect(x: -particle.size.width / 2,
                                      y: -particle.size.height * flipScale / 2,
                                      width: particle.size.width,
                                      height: particle.size.height * flipScale)
                    ctx.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(particle.color))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
