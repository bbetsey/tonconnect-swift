# TonConnect for Swift

A native Swift implementation of [TON Connect](https://docs.ton.org/develop/dapps/ton-connect/overview)
for the dApp side, with a SwiftUI interface included.

No web view, no JavaScript runtime on the critical path: the protocol — session
crypto, the SSE bridge, the RPC envelope — is implemented in Swift, and the
wallet picker, the connect button and the operation sheet are plain SwiftUI views.

> **Status: pre-release.** The package works end to end and is exercised against
> live wallets on a real device, but no version has been tagged yet and the
> public API may still change.

> **Unofficial.** This is an independent implementation, not affiliated with or
> endorsed by the TON Foundation or tonkeeper. It implements the dApp side of the
> protocol; the official iOS package, [ton-connect/kit-ios](https://github.com/ton-connect/kit-ios),
> is for the wallet side. "TON Connect" is used here to name the protocol this
> package speaks.

## Requirements

- iOS 16+ / macOS 14+
- Swift 5.10+
- A TON Connect manifest hosted over HTTPS

## Installation

Add the package with Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/bbetsey/tonconnect-swift.git", from: "0.1.0")
]
```

Then depend on the products you need:

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "TonConnectSDK", package: "tonconnect-swift"),  // the facade + the default engine
    .product(name: "TonConnectUI",  package: "tonconnect-swift"),  // the SwiftUI views (optional)
])
```

## Quick start

**1. Host a manifest.** TON Connect requires a small JSON file at a public HTTPS
URL — wallets fetch it to show the user who is asking for a connection:

```json
{
  "url": "https://example.com",
  "name": "My App",
  "iconUrl": "https://example.com/icon-180.png"
}
```

**2. Create the facade once, at the composition root.** It restores a previous
session by itself on creation:

```swift
import TonConnectCore
import TonConnectSDK

let tonConnect = try TonConnect(manifestUrl: "https://example.com/tonconnect-manifest.json")
```

The session is stored in the Keychain by default; pass your own
`any TonConnectStorage` to change that.

**3. Drop in the UI.** The button carries the whole connect flow — the wallet
picker, the QR for connecting from a second device, the connected state with a
disconnect menu. The sheet modifier shows every send/sign operation:

```swift
import SwiftUI
import TonConnectCore
import TonConnectUI

struct ContentView: View {
    @EnvironmentObject var tonConnect: TonConnect

    var body: some View {
        VStack {
            if let account = tonConnect.account {
                Text(account.address)
            }
            TonConnectButton(tonConnect)
        }
        .tonConnectOperationSheet(tonConnect)
    }
}
```

`TonConnect` is an `ObservableObject`: `state`, `account`, `operation` and
`connectLink` drive your own views just as well.

## Sending a transaction

```swift
let payload = SendTransactionPayload(
    validUntil: Int(Date().timeIntervalSince1970) + 300,
    network: tonConnect.account?.network,
    from: nil,
    messages: [SendTransactionPayload.Message(
        address: "UQ…",
        amount: "10000000",      // nanotons
        payload: nil,
        stateInit: nil)]
)
_ = try await tonConnect.sendTransaction(payload)
```

## Signing data

```swift
_ = try await tonConnect.signData(.text(text: "Hello",
                                        network: tonConnect.account?.network,
                                        from: nil))
```

`.binary(bytes:…)` and `.cell(schema:cell:…)` are available too.

A wallet's refusal is not an error you have to catch: `sendTransaction` and
`signData` return a typed `WalletResponse`, and the operation sheet renders the
outcome — succeeded, declined by the user, refused by the wallet, or a
connection problem with a retry.

## The example app

[`Examples/Demo`](Examples/Demo) is a small SwiftUI app that runs the whole flow
against a real wallet — connect, restore, send, sign, disconnect. It builds
against the package in this repository rather than a published version, so CI
uses it as an integration test of the public API.

## What is inside

| Product | What it is |
|---|---|
| `TonConnectCore` | The protocol types, the `TonConnect` facade, storage, the engine protocol. No UI, no engine. |
| `TonConnectSDK` | Convenience: `TonConnect(manifestUrl:)` builds the default engine for you. |
| `TonConnectNativeEngine` | The default engine — session crypto, bridge, RPC, all in Swift. |
| `TonConnectUI` | SwiftUI: the connect button, the wallet picker with QR, the operation sheet. |
| `TonConnectTransport` | The SSE client and the HTTP POST helper the engine runs on. |
| `TonConnectJSCoreEngine` | A second engine driving the official JavaScript SDK in JavaScriptCore. Kept for differential testing (see below). |
| `TonConnectConformance` | An engine test suite any implementation can be run against, plus a fake engine for consumers' tests. |

## Two engines, one test suite

The package carries two independent implementations of the same
`TonConnectEngine` protocol, and both are run against the same conformance
suite. The JavaScriptCore engine wraps the official `@tonconnect/sdk`; the
native engine is the product. Agreeing with an independent implementation of the
protocol is a stronger statement than agreeing with our own expectations, which
is why the JS engine stays in the repository even though it is no longer the
default.

Run everything with:

```bash
swift test
```

## Wallets

The flows have been exercised on a physical device against Tonkeeper,
MyTonWallet, Gram Wallet, Tonhub and Telegram Wallet — connect, restore,
send, sign and disconnect. Wallets disagree with the specification in small ways
(the type of a field, a non-spec error code, how a Telegram Mini App link carries
its parameters), so the package is deliberately tolerant on the wire: an
unexpected shape is accommodated rather than allowed to break a session.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Apache License 2.0 — see [LICENSE](LICENSE).

This package redistributes third-party software, including a bundled build of
the official TON Connect JavaScript SDK and the TweetNaCl C reference
implementation. See [NOTICE](NOTICE) and
[THIRD-PARTY-LICENSES.txt](THIRD-PARTY-LICENSES.txt).
