# ``TonConnectUI``

The connect flow as SwiftUI views: a button, a wallet picker, and one sheet that
narrates every operation.

## Overview

Adding ``TonConnectButton`` to a screen is the whole connect flow — the picker,
the QR for connecting from a second device, the connected state with a disconnect
menu. Attaching `tonConnectOperationSheet(_:)` to the app's root gives every
send and sign a window that follows it from "waiting for you" to an outcome.

The facade is passed explicitly rather than read from the environment: a
forgotten dependency should be a compile error, not a crash in front of a user.

## Topics

### Views

- ``TonConnectButton``
- ``WalletPickerSheet``

### The wallet registry

- ``WalletsListEntry``
- ``WalletsListLoader``

### Connecting from a second device

For an app that draws its own QR instead of using the picker: the bridges of
every wallet in the registry, or of the wallets you choose, and the link arrives
in `TonConnect.connectLink`.

- ``TonConnectCore/TonConnect/connectWithQR(items:timeout:)``
- ``TonConnectCore/TonConnect/connectWithQR(wallets:items:timeout:)``
