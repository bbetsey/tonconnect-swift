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

`KeychainStorage` is written for iOS, where there is one keychain and
`kSecAttrAccessibleAfterFirstUnlock` means what it says. macOS has two, and these
calls land in the older file-based one, where that accessibility attribute has no
effect. Switching to the data protection keychain would fix that and is
deliberately not done: it is reachable only by code that can carry an entitlement
— a main executable — so a library cannot request it on its own behalf, and a
host without one gets `errSecMissingEntitlement` (-34018) on every write. Treat
macOS as unsupported: the package builds there so that `swift build`,
`swift test` and DocC have a platform to run on, not because the flow works.

#### The secret, and the trade-off it was stored under

A session is not a token the wallet can revoke by itself: it is a Curve25519
secret key, held as hex, and it is what decrypts everything the wallet sends and
authenticates everything sent back — the transport is NaCl's `crypto_box`, so the
same key does both. Whoever holds it holds the session. That is the thing being
stored, and the choices below are trade-offs made against it rather than settings
picked for convenience.

The item is filed under `kSecAttrAccessibleAfterFirstUnlock` — deliberately not
the `…ThisDeviceOnly` variant. The device-only variants are tied to the device
UID, which means they do not survive onto another device at all; the plain one
does, and it is what keeps a session alive across a restore. The cost is the
other side of the same sentence: an encrypted device backup carries the secret
with it, and restoring that backup onto a different device brings a live session
along. If your threat model puts a stolen backup above the annoyance of
reconnecting, construct your own ``TonConnectStorage`` and use the device-only
attribute; the protocol does not mind, only the user's patience does.

`kSecAttrSynchronizable` is never set, so the item defaults to non-syncing and
does not travel through iCloud Keychain. This is not a choice you can reverse
from the outside — write your own storage if you want it.

Nothing in this target writes key material to the log. Failures to store report
the operation and the error under the subsystem `tonconnect-swift`, and neither
carries the key. Note that this promise covers this target: the JavaScriptCore
engine forwards the bundled JS SDK's own console output to the system log
unredacted, which is one more reason it is not the default engine.

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
