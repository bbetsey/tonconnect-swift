import SwiftUI
import TonConnectCore

/// Wallet-picker bottom sheet (v3 design after the current @tonconnect/ui):
/// home → allWallets / wallet / help / qr. The screen is a single enum, switched without animations.
/// No UIApplication.open here — opening the wallet is encapsulated in connect().
public struct WalletPickerSheet: View {

    /// Current sheet screen. fromAll — where we came from (for the detent and back navigation).
    private enum Screen: Equatable {
        case home
        case allWallets
        case wallet(WalletsListEntry, fromAll: Bool)
        case help
        case qr(WalletsListEntry, fromAll: Bool)
        case homeQR
    }

    @ObservedObject var tonConnect: TonConnect
    @StateObject private var loader = WalletsListLoader()
    @Environment(\.dismiss) private var dismiss

    @State private var screen: Screen = .home
    @State private var connectionFailed = false
    @State private var connectTask: Task<Void, Never>?
    @State private var detent: PresentationDetent = .medium

    private static let telegramWalletID = "telegram-wallet"

    /// Present this yourself only if you are not using ``TonConnectButton``,
    /// which opens the picker on its own.
    public init(tonConnect: TonConnect) {
        self.tonConnect = tonConnect
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Group {
                switch screen {
                case .home:
                    if loader.wallets.isEmpty { emptyStateView } else { homeView }
                case .allWallets:
                    gridView
                case .wallet(let wallet, let fromAll):
                    walletScreen(wallet, fromAll: fromAll)
                case .help:
                    helpView
                case .qr(let wallet, _):
                    qrScreen(wallet)
                case .homeQR:
                    universalQRScreen
                }
            }
            Spacer(minLength: 0)
            footer
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationDragIndicator(.hidden)
        .onChange(of: detent) { newDetent in
            if newDetent != detentTarget { detent = detentTarget }
        }
        .ignoresSafeArea()
        .onAppear { loader.load() } // lazily, on open
        .onChange(of: tonConnect.isConnected) { connected in
            if connected { dismiss() } // success — same as the original
        }
        .onDisappear { connectTask?.cancel() }
    }

    /// The "legitimate" detent: home and its QR are compact, the rest inherit their origin.
    private var detentTarget: PresentationDetent {
        switch screen {
        case .home: return .medium
        case .wallet(_, let fromAll): return fromAll ? .large : .medium
        case .allWallets, .help: return .large
        case .qr(_, let fromAll): return fromAll ? .large : .medium
        case .homeQR: return .medium
        }
    }

    private func show(_ newScreen: Screen) {
        screen = newScreen
        detent = detentTarget
    }

    // MARK: - header (circle buttons; title and subtitle depend on the screen)

    private var headerTitle: String {
        switch screen {
        case .home: return "Connect your TON wallet"
        case .allWallets: return "Wallets"
        case .wallet(let wallet, _): return wallet.name
        case .help: return "What is a wallet"
        case .qr(let wallet, _): return wallet.name
        case .homeQR: return "Connect your TON wallet"
        }
    }

    private var headerSubtitle: String? {
        switch screen {
        case .home: return "Use Wallet in Telegram or choose other application"
        default: return nil
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                if screen != .home {
                    Text(headerTitle)
                        .font(.title3.weight(.bold))
                        .lineLimit(1)
                        .padding(.horizontal, 56) // keep clear of the side circle buttons
                }
                HStack {
                    if screen == .home {
                        headerIconButton("qrcode") { startUniversalQR() }
                    } else {
                        headerIconButton("chevron.left") { goBack() }
                    }
                    Spacer()
                    headerIconButton("xmark") { dismiss() }
                }
            }
            if screen == .home {
                Text(headerTitle)
                    .font(.title3.weight(.bold))
            }
            if let subtitle = headerSubtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
    }

    /// Header circle button (original's style): an icon on a gray circle.
    private func headerIconButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body.weight(.regular))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
                .tcCircleGlassBackground()
        }
        .buttonStyle(.plain)
    }

    /// Back: from the wallet/QR screen — cancel the connection attempt and return whence we came.
    private func goBack() {
        switch screen {
        case .wallet(_, let fromAll):
            connectTask?.cancel()
            connectionFailed = false
            show(fromAll ? .allWallets : .home)
        case .allWallets, .help:
            show(.home)
        case .home:
            break
        case .qr(let wallet, let fromAll):
            show(.wallet(wallet, fromAll: fromAll))
        case .homeQR:
            connectTask?.cancel()
            show(.home)
        }
    }

    // MARK: - home: CTA + "Choose other application" section + icons + folder

    private var homeView: some View {
        VStack(spacing: 20) {
            if let telegram = telegramWallet {
                Button { select(telegram) } label: {
                    HStack {
                        Image("AtWalletGlyph", bundle: .module)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .foregroundStyle(.white)
                        Spacer()
                        Text("Connect Wallet in Telegram").font(.headline)
                        Spacer()
                        Image("TelegramPlane", bundle: .module)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .cornerRadius(6)
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .padding(.horizontal, 8)
                }
                .tcProminentButtonStyle(shape: .roundedRectangle(radius: 16))
            }
            Text("Choose other application")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 0) {
                ForEach(topWallets) { wallet in
                    walletCell(wallet, iconSize: 64)
                    Spacer(minLength: 8)
                }
                viewAllTile
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    private var telegramWallet: WalletsListEntry? {
        loader.wallets.first { $0.appName == Self.telegramWalletID }
    }

    /// Wallets without telegram-wallet (it lives in the CTA): first few in the row, the next go into the folder collage.
    private var otherWallets: [WalletsListEntry] {
        loader.wallets.filter { $0.appName != Self.telegramWalletID }
    }
    private var topWallets: [WalletsListEntry] { Array(otherWallets.prefix(3)) }
    private var collageWallets: [WalletsListEntry] { Array(otherWallets.dropFirst(4).prefix(4)) }

    /// An iOS-style "folder": a 2×2 collage of the next wallets' thumbnails.
    private var viewAllTile: some View {
        Button { show(.allWallets) } label: {
            VStack(spacing: 4) {
                VStack(spacing: 5) {
                    HStack(spacing: 5) {
                        collageIcon(0); collageIcon(1)
                    }
                    HStack(spacing: 5) {
                        collageIcon(2); collageIcon(3)
                    }
                }
                .padding(8)
                .frame(width: 64, height: 64)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
                Text("View all\nwallets")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func collageIcon(_ index: Int) -> some View {
        if index < collageWallets.count {
            walletIcon(collageWallets[index], size: 20)
        } else {
            RoundedRectangle(cornerRadius: 8).fill(.quaternary).frame(width: 20, height: 20)
        }
    }

    // MARK: - full grid

    private var gridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 84))], spacing: 16) {
                ForEach(loader.wallets) { wallet in
                    walletCell(wallet, iconSize: 64)
                }
            }
            .padding(16)
        }
    }

    // MARK: - shared wallet cell

    private func walletCell(_ wallet: WalletsListEntry, iconSize: CGFloat) -> some View {
        Button { select(wallet) } label: {
            VStack(spacing: 4) {
                walletIcon(wallet, size: iconSize)
                Text(wallet.name).font(.caption).lineLimit(1)
            }
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
    }

    private func walletIcon(_ wallet: WalletsListEntry, size: CGFloat) -> some View {
        AsyncImage(url: wallet.image) { image in
            image.resizable().aspectRatio(contentMode: .fit)
        } placeholder: {
            TCSpinner(size: 14)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: (size * 0.24).rounded()))
    }

    // MARK: - select (facade only)

    private func select(_ wallet: WalletsListEntry) {
        guard let source = wallet.makeConnectionSource() else { return }
        if case .wallet = screen {} else {
            show(.wallet(wallet, fromAll: screen == .allWallets))
        }
        connectionFailed = false
        connectTask = Task {
            do {
                try await tonConnect.connect(source: source,
                                              items: [.tonAddress(network: nil),
                                                      .tonProof(payload: "tcui-\(UUID().uuidString)")])
            } catch {
                connectionFailed = true // stay on the wallet screen
            }
        }
    }

    // MARK: - wallet screen

    private func walletScreen(_ wallet: WalletsListEntry, fromAll: Bool) -> some View {
        VStack(spacing: 24) {
            Spacer()
            TCSpinner(size: 40)
                .padding(.top, 24)
            Text(connectionFailed ? "Connection failed" : "Continue in \(wallet.name)…")
                .font(.body)
                .foregroundStyle(connectionFailed ? .primary : .secondary)
            HStack(spacing: 12) {
                Button { select(wallet) } label: {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .foregroundStyle(.primary)
                }
                .tcSecondaryButtonStyle()
                if tonConnect.connectLink != nil {
                    Button { show(.qr(wallet, fromAll: fromAll)) } label: {
                        Label("Show QR Code", systemImage: "qrcode")
                            .foregroundStyle(.primary)
                    }
                    .tcSecondaryButtonStyle()
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: - help "What is a wallet" (via the "?" button)

    private var helpView: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                helpSection(icon: "lock",
                            title: "Secure digital assets storage",
                            text: "A wallet protects and manages your digital assets including TON, tokens and collectables.")
                helpSection(icon: "person.crop.circle",
                            title: "Control your Web3 identity",
                            text: "Manage your digital identity and access decentralized applications with ease. Maintain control over your data and engage securely in the blockchain ecosystem.")
                helpSection(icon: "arrow.left.arrow.right",
                            title: "Effortless crypto transactions",
                            text: "Easily send, receive, monitor your cryptocurrencies. Streamline your operations with decentralized applications.")
                Button { show(.allWallets) } label: {
                    HStack(spacing: 8) {
                        Text("Get a Wallet").font(.headline)
                        Image("WalletGlyph", bundle: .module)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17, height: 16)
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .tcSecondaryButtonStyle()
                Spacer()
            }
            .padding(.horizontal, 36)
        }
    }

    private func helpSection(icon: String, title: String, text: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            VStack(spacing: 8) {
                Text(title).font(.headline)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - degraded empty state

    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Text("No wallets available").font(.headline)
            Text("Check your connection and try again").font(.body)
            Button("Try Again") { loader.load() }
                .tint(Color.accentColor)
        }
        .padding(.top, 24)
    }

    // MARK: - QR (the link lives while a connection attempt is in flight)

    /// Universal QR (the left button on home): one QR for any wallet on any
    /// device — we gather every sse bridge of the list.
    private func startUniversalQR() {
        let wallets = loader.wallets
        guard !WalletsListEntry.sseBridgeURLs(of: wallets).isEmpty else { return }
        show(.homeQR)
        connectTask = Task {
            try? await tonConnect.connectWithQR(wallets: wallets,
                                                items: [.tonAddress(network: nil),
                                                        .tonProof(payload: "tcui-\(UUID().uuidString)")])
        }
    }

    private var universalQRScreen: some View {
        VStack(spacing: 20) {
            qrCard {
                Image("TonGlyph", bundle: .module)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(Color.tonBrandBlue, in: Circle())
                    .padding(4)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
            }
            Text("Scan with your mobile wallet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 16)
    }

    private func qrScreen(_ wallet: WalletsListEntry) -> some View {
        VStack(spacing: 20) {
            qrCard {
                walletIcon(wallet, size: 52)
                    .padding(4)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
            }
            Text("Scan the QR code with \(wallet.name) on another device")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 16)
    }

    /// A white near-full-width QR card; the overlay is a centered logo
    /// (a QR with correctionLevel H survives its center being covered).
    private func qrCard(@ViewBuilder overlay: () -> some View) -> some View {
        ZStack {
            if let link = tonConnect.connectLink {
                QRCodeView(url: link)
            } else {
                TCSpinner(size: 32)
            }
            overlay()
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 24)
    }

    // MARK: - footer: branding strip; on the wallet/QR screen — the wallet row with GET

    @ViewBuilder
    private var footer: some View {
        VStack(spacing: 0) {
            Divider()
            switch screen {
            case .wallet(let wallet, _), .qr(let wallet, _):
                walletFooter(wallet)
            default:
                brandFooter
            }
        }
        .padding(.bottom, 16)
        .background(footerBackground)
    }
    
    private var footerBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGray5)
        #else
        Color(nsColor: .windowBackgroundColor)
        #endif
    }

    private var brandFooter: some View {
        HStack(spacing: 8) {
            Image("TonGlyph", bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.tonBrandBlue, in: Circle())
            Text("TON ").font(.callout.weight(.heavy)) + Text("Connect").font(.callout)
            Spacer()
            headerIconButton("questionmark") { show(.help) }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func walletFooter(_ wallet: WalletsListEntry) -> some View {
        HStack(spacing: 12) {
            walletIcon(wallet, size: 36)
            Text(wallet.name).font(.body.weight(.semibold))
            Spacer()
            if let about = wallet.aboutURL {
                Link("GET", destination: about)
                    .font(.callout.weight(.bold))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

private extension Color {
    /// TON brand blue (#0098EA) — FIXED, not the system .blue: the badges sit on
    /// the always-white QR card and the footer backdrop, while systemBlue is an
    /// adaptive chameleon (#007AFF light / #0A84FF dark) that drifts toward cyan
    /// on a white background in dark mode.
    static let tonBrandBlue = Color(red: 0.0, green: 0.596, blue: 0.918)
}
