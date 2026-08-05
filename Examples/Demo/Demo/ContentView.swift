import SwiftUI
import TonConnectCore
import TonConnectUI

struct ContentView: View {
    @EnvironmentObject var tonConnect: TonConnect

    // Presets instead of input fields: every operation is one tap, and what it
    // will send is shown read-only. An example should demonstrate the SDK, not a
    // form validator.
    private let amountTON = "0.01"
    private let signTextPreset = "Hello from TonConnect Demo"
    private let signBinaryPreset = "Binary demo payload"
    // A fixed cell preset whose round-trip is verified: it decodes back to
    // "Demo cell payload"
    private let cellSchema = "message#_ text:string = Message;"
    private let cellPreset = "te6cckEBAQEAEwAAIkRlbW8gY2VsbCBwYXlsb2FkLLGnEA=="

    private var isConnected: Bool { tonConnect.account != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    network
                    sendSection
                    signSection
                        .padding(.bottom, 24)
                    connectArea
                }
                .padding(16)
            }
            .navigationTitle("TON Connect Demo")
        }
        .background(Color(.systemBackground))
        .tonConnectOperationSheet(tonConnect)
    }

    // MARK: - Header + connect

    private var network: some View {
        if let network = tonConnect.account?.network {
            NetworkBadge(network: network)
        } else {
            NetworkBadge(network: "0")
        }
    }

    private var connectArea: some View {
        VStack(spacing: 8) {
            TonConnectButton(tonConnect)
            if !isConnected {
                Text("Connect your wallet to try the full flow")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Send Transaction

    /// GRAM to nanotons through Decimal — money never goes through a binary float:
    /// "0.01" → "10000000"
    private var nanotonAmount: String {
        let ton = Decimal(string: amountTON) ?? 0
        var scaled = ton * Decimal(1_000_000_000)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        return NSDecimalNumber(decimal: rounded).stringValue
    }
    
    private var sendSection: some View {
        sectionCard("Send Transaction") {
            VStack(alignment: .leading) {
                presetPreview("\(amountTON) GRAM → your own address (send to self)")
                Button("Send Transaction") {
                    // the recipient is your own address, so a live run costs nothing
                    guard let recipient = tonConnect.account?.userFriendlyAddress() else { return }
                    let network = tonConnect.account?.network   // from the session, never hard-coded
                    let amount = nanotonAmount
                    Task {
                        // The closure overload, because validUntil expires: a Retry
                        // after a connection problem can land minutes later, and a
                        // replayed deadline would reach the wallet already stale.
                        do {
                            _ = try await tonConnect.sendTransaction {
                                SendTransactionPayload(
                                    validUntil: Int(Date().timeIntervalSince1970) + 300,
                                    network: network,
                                    from: nil,
                                    messages: [SendTransactionPayload.Message(
                                        address: recipient,
                                        amount: amount,
                                        payload: nil,
                                        stateInit: nil)]
                                )
                            }
                        }
                        catch { } // the operation sheet shows the outcome
                    }
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 8))
                .controlSize(.regular)
                .disabled(!isConnected)
                .padding(.top, 16)
                
            }
        }
    }

    // MARK: - Sign Data

    private var signSection: some View {
        sectionCard("Sign Data") {
            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 8) {
                    VStack(alignment: .leading) {
                        Text("Text").font(.headline)
                        presetPreview("“\(signTextPreset)”")
                    }
                    Spacer()
                    Button {
                        Task {
                            do {
                                _ = try await tonConnect.signData(.text(
                                    text: signTextPreset,
                                    network: tonConnect.account?.network,
                                    from: nil))
                            } catch { }
                        }
                    } label: {
                        Text("Sign Text")
                            .frame(width: 90)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 8))
                    .controlSize(.regular)
                    .disabled(!isConnected)
                }
                
                HStack(spacing: 8) {
                    VStack(alignment: .leading) {
                        Text("Binary").font(.headline)
                        presetPreview("“\(signBinaryPreset)”")
                        Text("Encoded to base64 before signing")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        // the user never sees base64; the example encodes it
                        let encoded = Data(signBinaryPreset.utf8).base64EncodedString()
                        Task {
                            do {
                                _ = try await tonConnect.signData(.binary(
                                    bytes: encoded,
                                    network: tonConnect.account?.network,
                                    from: nil))
                            } catch { }
                        }
                    } label: {
                        Text("Sign Binary")
                            .frame(width: 90)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 8))
                    .controlSize(.regular)
                    .disabled(!isConnected)
                }
                
                
                HStack(spacing: 8) {
                    VStack (alignment: .leading) {
                        Text("Cell (fixed preset)").font(.headline)
                        presetPreview("Demo cell payload")
                    }
                    Spacer()
                    Button {
                        Task {
                            do {
                                _ = try await tonConnect.signData(.cell(
                                    schema: cellSchema,
                                    cell: cellPreset,
                                    network: tonConnect.account?.network,
                                    from: nil))
                            } catch { }
                        }
                    } label: {
                        Text("Sign Cell")
                            .frame(width: 90)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 8))
                    .controlSize(.regular)
                    .disabled(!isConnected)
                }
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Building blocks

    private func sectionCard<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.title2).fontWeight(.semibold)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func presetPreview(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}

/// The network badge is informational only — there is no network switch, and the
/// value comes from the connected account.
private struct NetworkBadge: View {
    let network: String

    var body: some View {
        Text(label)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
    }

    private var label: String {
        switch network {
        case "-3":   return "TESTNET"
        case "-239": return "MAINNET"
        default:     return "NETWORK"
        }
    }

    private var color: Color {
        switch network {
        case "-3":   return Color(.systemOrange)
        case "-239": return Color(.systemGreen)
        default:     return Color(.systemGray)
        }
    }
}
