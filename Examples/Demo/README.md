# Demo

A small SwiftUI app that exercises the whole flow against a real wallet:
connect, restore a session across launches, send a transaction, sign text,
binary and a cell, disconnect.

```bash
open Demo.xcodeproj
```

It depends on the package by relative path (`../..`), so it always builds against
the working tree rather than a published version. That is deliberate: the app is
also how CI notices that a change broke the public API — the compiler complains
here before a consumer ever sees a release.

## What is worth reading

- `CompositionRoot.swift` — the whole setup: one `TonConnect(manifestUrl:)`.
- `ContentView.swift` — `TonConnectButton`, `tonConnectOperationSheet`, and the
  four operations. Every operation is a fixed preset shown read-only, so the
  screen demonstrates the SDK instead of a form validator.
- `Previews.swift` — a toy engine written against the public `TonConnectEngine`
  protocol. The previews never import a real engine, which doubles as proof that
  the protocol is enough to build against.

## Running it against a wallet

The app points at a manifest hosted for this demo:

    https://bbetsey.github.io/tc-m/demo.json

TON Connect requires that file to be reachable over HTTPS — wallets fetch it to
show the user who is asking for a connection. Point `CompositionRoot.manifestUrl`
at your own if you fork this.

The send preset transfers 0.01 GRAM **to your own address**, so a live run on
mainnet costs only the network fee. Connect a testnet wallet if you would rather
it cost nothing at all.
