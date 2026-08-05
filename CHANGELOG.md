# Changelog

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and
this package follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
While the major version is zero the public API may still change. Semantic
Versioning permits a zero-major package to break its API in a minor release, and
this one does not take that permission: a release that breaks the public API is
1.0.0. That is what makes the `from:` requirement in the installation snippet
safe to follow — every version it accepts is meant to keep compiling.

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
