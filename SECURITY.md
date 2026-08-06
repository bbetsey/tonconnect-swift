# Security

## What this package holds

A connected session is a Curve25519 secret key. It decrypts everything the wallet
sends and authenticates everything sent back, and it lives in the Keychain under
the service `tonconnect-swift`. Whoever holds that key holds the session, so any
report that ends with "and then the key leaves the device" is worth sending, even
if the path to it looks impractical.

The trade-offs the default storage was written under — why the item is not
`…ThisDeviceOnly`, and what that means for encrypted backups — are documented in
`TonConnectCore`, under Storing the session. Those are deliberate choices rather
than oversights; a report arguing they are the wrong ones is welcome, but please
argue against what is written there rather than against the absence of it.

## Reporting a vulnerability

Report privately through GitHub: **Security → Report a vulnerability** on this
repository. That opens a private advisory visible only to the maintainers, which
is the right place for anything you would not want in a public issue.

Please do not open a public issue for a suspected vulnerability. A public issue
is the correct place for a bug that merely misbehaves; it is the wrong place for
one that lets somebody else spend a user's money.

Include what you would want if you were fixing it: the version or commit, the
platform, whether the native or the JavaScriptCore engine was in use, and the
smallest sequence that reproduces the problem.

**Do not paste session material.** Keychain contents, a session secret key, a
wallet's private key or a seed phrase are never needed to describe a bug, and a
report is not a safe place to keep them. Redact them before sending.

## What to expect

This is a small project maintained by one person, so there is no staffed rota and
no promised response window. What you can expect: reports are read, a fix is
released as a normal tagged version, and the advisory says what was wrong once
the fix is out.

## Scope

The package speaks the dApp side of TON Connect. Problems in a wallet, in the
bridge servers it talks to, or in the TON Connect protocol itself are outside what
this repository can fix — but tell us anyway if the package handles them in a way
that makes them worse, because that part is ours.
