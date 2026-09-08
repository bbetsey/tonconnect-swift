# Changelog

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
this package follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
While the major version is zero the public API may still change. Semantic
Versioning permits a zero-major package to break its API in a minor release, and
this one does not take that permission: a release that breaks the public API is
1.0.0. That is what makes the `from:` requirement in the installation snippet
safe to follow — every version it accepts is meant to keep compiling.

## Unreleased

### Added

- The test suite now runs on the iOS simulator in CI, alongside the macOS run.
  On macOS `#if canImport(UIKit)` removes `SystemWalletOpener` and the convenience
  initializer `TonConnect(manifestUrl:)` before the tests see them, so until now
  the package's entry point was never exercised by an automated test on the
  platform it ships for. Two tests are deliberately not run there: the Keychain
  spike (a package test bundle carries no entitlement, so every write fails with
  `errSecMissingEntitlement`) and a garbage-collection experiment whose premise
  the simulator's collector does not share.

### Changed

- The package builds in the Swift 6 language mode, and CI now checks that it
  keeps doing so. Until now a consumer compiling with strict concurrency saw
  44 errors: `NSLock.lock()`/`unlock()` around short critical sections in async
  code (now `withLock`), a mutable static behind a lock the compiler could not
  see, and two JavaScriptCore values captured by cancellation and storage
  closures. `Package.swift` stays at tools version 5.10, so nothing is required
  of consumers who are not there yet.

### Fixed

- The JavaScriptCore engine no longer hangs in `restoreConnection` when the
  collector runs before a storage read completes. The resolvers of the promise
  bridging a Swift storage read into JavaScript were held as
  `JSManagedValue(value:andOwner:)`, which JavaScriptCore keeps only while the
  value is reachable from the JS graph or from an owner registered through
  `addManagedReference` - and nothing referenced a promise's own resolve
  function. A timely collection freed it, the read never settled, and the SDK's
  restore waited forever; the iOS simulator hit this on every run. The resolvers
  are now held strongly for the duration of the read.

- A wallet reply without an `id` no longer leaves the operation waiting forever.
  Some wallets omit the `id` the spec requires; such a frame failed to decode and
  was dropped, so `sendTransaction` or `signData` never returned and the only way
  out was cancelling the task. The frame is now adopted when exactly one request
  is in flight, where there is nothing to confuse it with. With two or more in
  flight it is still dropped, deliberately: resolving the wrong operation is worse
  than resolving none. An `id` that is present but malformed is not repaired.

## 0.2.3 — 2026-08-09

No source changes. The README is what moved, and the README on the repository's
front page is read from the default branch — which is what a release is for here.

### Added

- A picture of the flow at the end of Quick start: picking a wallet, the QR for
  connecting from a second device, waiting for the wallet to confirm, and the
  transaction sent. It sits directly under the two calls that produce it, because
  that is where a reader asks what they get for them.
- A section saying what the package is for, and where it stops. A connection
  carries the user's address, a transaction request moves funds, signing proves
  ownership to a backend — but `sendTransaction` returns when the wallet reports
  that it signed and broadcast the message, so whether the transfer settled is a
  question for a node or an indexer. Any flow where the user receives something
  in exchange for payment needs that check on a server you control, and it is
  cheaper to read that here than to discover it.

### Changed

- The README banner.

## 0.2.2 — 2026-08-06

No source changes. Everything here either explains the package or governs the
repository around it, and most of it only takes effect once it reaches the
default branch — which is what this release is for.

### Added

- A security policy. It opens with what an attacker would be after — the
  session's secret key — and asks for private reports rather than public issues.
- Issue forms for bug reports and feature requests, asking for the version, the
  platform, the engine and the wallet up front, and warning against pasting
  session material into a public thread.
- A Dependabot configuration, mainly for the GitHub Actions the workflow pins.
- Coverage, measured in the job that already builds the package and reported on
  the run page. Deliberately not enforced: the SwiftUI views measure 0% because a
  unit test cannot render them, so a threshold over the whole package would track
  the size of the UI rather than the health of the tests.
- A banner at the top of the README.

### Changed

- The documentation now says what the stored session secret is — a Curve25519 key
  that both decrypts what the wallet sends and authenticates what goes back — and
  what the Keychain defaults were traded for. Not using the device-only
  accessibility is what lets a session survive a restore; the same property is
  what puts the secret into an encrypted backup that can be carried to another
  device. Both halves are stated, along with the way out for anyone who prefers
  the other side of that trade.

## 0.2.1 — 2026-08-05

### Added

- A Swift Package Index manifest, so the hosted documentation is generated for
  iOS rather than for the index's default platform. On macOS the `TonConnectSDK`
  archive is a single empty page — the target is one file behind
  `#if canImport(UIKit)` — and the entry point the README opens with,
  `TonConnect.init(manifestUrl:storage:)`, has nowhere to appear.

No source changes: this release exists so that the documentation hosted for a
tagged version is the documentation of the platform the package targets.

## 0.2.0 — 2026-08-05

### Added

- `TonConnect.sendTransaction(_:)` and `TonConnect.signData(_:)` gained an
  overload that takes a closure building the payload rather than the payload
  itself. A retry calls the closure again, so a `validUntil` minted for the first
  attempt does not reach the wallet already expired on the second — a retry lands
  minutes later often enough for that to matter, and the wallet's answer is a
  bare "declined" with nothing to explain it.
- `FakeEngine.lastSentTransaction` in `TonConnectConformance`, so a test can tell
  a replayed payload from a rebuilt one.
- An example app under `Examples/Demo`, exercising connect, session restore,
  send, the three sign flows and disconnect against a real wallet. CI builds it
  against the package in this repository, which makes it an integration test of
  the public API: a rename that would break a consumer goes red there first.

### Changed

- The value-taking `sendTransaction(_:)` and `signData(_:)` keep their previous
  behaviour and now delegate to the closure form with a constant. Their
  documentation states plainly what was implicit before: a retry resends the same
  payload, expiry included. Reach for the closure overload when the payload is
  time-dependent.
- `KeychainStorage.init(service:)` is deprecated on macOS. Nothing replaces it —
  the platform is not supported, and Swift has no attribute that says so. On
  macOS these calls reach the legacy file-based keychain, where the
  `kSecAttrAccessibleAfterFirstUnlock` the initializer documents has no effect.
  The data protection keychain is reachable only by code that can carry an
  entitlement, which a library cannot request on its own behalf.
- Requirements now read iOS 16+. macOS stays in `Package.swift` because
  `swift build`, `swift test` and DocC need a platform to run on, not because the
  flow works there.

### Fixed

- The session store no longer swallows write failures. Six writes ran as
  `try? await store.…`, so a Keychain that refused to store was indistinguishable
  from success until the session failed to come back at the next launch. Writes
  now go through one place that reports the failure to `os.Logger` under the
  subsystem `tonconnect-swift`.

## 0.1.0 — 2026-08-03

Initial release.
