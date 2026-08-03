import SwiftUI

/// The package's own loader (@tonconnect/ui parity — a rotating arc), replacing
/// the system ProgressView so the spinner looks identical everywhere.
struct TCSpinner: View {
    var size: CGFloat = 24
    var color: Color = .secondary
    @State private var isSpinning = false

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.72)
            .stroke(color, style: StrokeStyle(lineWidth: max(2, size * 0.11), lineCap: .round))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(isSpinning ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                    isSpinning = true
                }
            }
    }
}
