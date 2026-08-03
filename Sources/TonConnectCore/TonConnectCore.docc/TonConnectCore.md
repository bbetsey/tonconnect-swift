# ``TonConnectCore``

Connect a TON wallet, ask it to sign, and observe what happens — natively.

## Overview

This module is the protocol and the state, with no user interface and no engine
of its own. ``TonConnect`` is the facade an app talks to: it holds the connection
state, exposes the wallet's account, and turns a wallet's answer into something a
view can render. The engine behind it is injected, which is how the same app code
ran on a JavaScript core first and on the native one later.

Two ideas are worth knowing before reading further.

**A refusal is an outcome, not an error.** `TonConnect.sendTransaction(_:)` and
`TonConnect.signData(_:)` return a ``WalletResponse``; a user pressing Cancel
comes back as `WalletResponse.error`, not as a thrown Swift error. Throwing is
reserved for a request that never got an answer at all.

**The wire is treated with suspicion, the model is not.** Live wallets disagree
with the specification in small ways — a timestamp as a string, a missing `id`, a
rejection under the wrong code. Decoding accommodates that; the typed values
handed to you stay exact, including the ones the wallet got wrong.

## Topics

### Getting started

- ``TonConnect``
- ``ConnectionState``
- ``Account``
- ``WalletConnectionSource``

### Asking the wallet for something

- ``SendTransactionPayload``
- ``SignDataPayload``
- ``WalletResponse``
- ``RPCErrorCode``

### Watching an operation

- ``OperationState``
- ``OperationKind``
- ``TonConnectEvent``
- ``ReturnStrategy``

### Connecting

- ``ConnectRequest``
- ``ConnectItem``
- ``ConnectEvent``
- ``ConnectSuccessPayload``
- ``TonProof``
- ``DeviceInfo``

### Storing the session

- ``TonConnectStorage``
- ``KeychainStorage``
- ``InMemoryStorage``

### Errors

- ``TonConnectError``
- ``ConnectErrorCode``
- ``ConnectItemErrorCode``

### Writing an engine

- ``TonConnectEngine``
- ``WalletOpener``

The shipped opener, `SystemWalletOpener`, is iOS-only — it lives behind
`#if canImport(UIKit)` and therefore does not appear in documentation built on
macOS.
