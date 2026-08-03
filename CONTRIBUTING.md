# Contributing

Thanks for taking a look. This document is short on ceremony and long on the two
or three conventions that actually matter here.

## Building and testing

```bash
swift build
swift test
```

The suite runs both engines against the same conformance suite, so a change to
the protocol layer is expected to keep two independent implementations happy.

One test group is gated behind an environment variable because it talks to a
real bridge over the network:

```bash
TC_LIVE_BRIDGE_SMOKE=1 swift test --filter LiveBridgeSmokeTests
```

## Test naming

Apple's Swift API Design Guidelines, applied to test names: camelCase, no
underscores, acronyms cased uniformly.

```swift
func testParseURLWithEmptyHostThrowsInvalidInput() { }   // yes
func test_parse_url_empty_host() { }                     // no
```

Long names are fine — a test name is read once by a human and many times in a
failure report.

## Be tolerant on the wire, strict in the model

Live wallets disagree with the specification in small ways: a timestamp arrives
as a string instead of a number, a reply carries no `id`, a rejection uses the
wrong error code. The official JavaScript SDK swallows all of it, which is why
those bugs have been invisible for years — and why a strict Swift decoder finds
them the hard way, in front of a user.

So: a new field on the wire is decoded permissively (number **or** string,
optional with a default, unknown values mapped to an `.unknown` case), and an
undecodable frame is ignored rather than allowed to kill a live session. The
typed model handed to the consumer stays exact — including the values the wallet
actually sent, even when we disagree with them.

Build fixtures from real traffic (device logs, `curl` against a bridge), never
from what we expect a wallet to send. A fixture that agrees with a wrong
assumption makes the suite green and the app broken.

## No wallet-specific branches

There is not a single wallet name in the source. Every workaround so far has
turned out to be a general rule — "a Telegram Mini App link carries its
parameters differently", "believe the message when the code disagrees with it" —
and general rules are what belong in the code. If you find yourself writing
`if wallet == "…"`, look for the rule behind it first; if there really is no
rule, raise it in the pull request rather than hiding it in a branch.

## Comments

English, and aimed at the next reader rather than at the author's memory. A
comment that records *why* — a link to the spec, to the wallet's own sources, or
a note that something is empirical — earns its place. A comment that restates the
line below it does not.

## The vendored JavaScript bundle

`Sources/TonConnectJSCoreEngine/Resources/tonconnect-sdk.bundle.js` is generated,
not hand-written: it is an esbuild bundle of the official `@tonconnect/sdk` plus
the small adapter in `Tools/jsbridge/src/index.ts`. Never edit the bundle by
hand — edit the adapter and rebuild:

```bash
./Tools/jsbridge/build.sh
```

The bundle is checked in because SwiftPM has no build-time npm step, and every
version is pinned in `Tools/jsbridge/package-lock.json`, so the rebuild is
reproducible: with the lockfile and the adapter unchanged, the output is
byte-identical. Which also means the reverse is worth checking — if a rebuild
you did not intend produces a diff, something moved that should not have.

The same directory generates the reference vectors the session-crypto tests are
checked against:

```bash
node Tools/jsbridge/generate-vectors.mjs
```

The oracle is the `tweetnacl` that ships with `@tonconnect/sdk` — the very
implementation `@tonconnect/protocol` uses. Do not install a second copy: two
copies can drift, and vectors that agree with our own crypto instead of the
protocol's prove nothing.

## Pull requests

- one concern per pull request;
- `swift test` green, and new behaviour covered by a test that fails without the
  change;
- if the change came from watching a real wallet misbehave, put the observed
  frame in the pull request — that evidence is worth more than the diff.
