# Contributing

Thanks for taking a look. This document is short on ceremony and long on the two
or three conventions that actually matter here.

## Branches

`main` holds released code and nothing else. Every change reaches it the same
way: a branch off `develop`, a pull request into `develop`, and later a release
pull request from `develop` into `main`. Nobody pushes to `main` directly, and
nobody pushes to `develop` directly either — both are entered through a pull
request so CI has a chance to speak first.

```
main      ──●───────────────────●──────────  releases only, tagged
             \                 /
develop   ────●───●───●───●───●────────────  integration
                   \ /   \ /
feature        feat/…   fix/…               short-lived, one concern each
```

Name a branch `<type>/<slug>`, with the same types the commit messages use:

| Type | For |
|---|---|
| `feat/` | new behaviour a consumer can see |
| `fix/` | a defect |
| `docs/` | documentation and comments |
| `test/` | tests only |
| `refactor/` | behaviour unchanged, shape improved |
| `perf/` | measurably faster or lighter |
| `build/` | the package manifest, the bundle tooling |
| `ci/` | the workflow itself |
| `chore/` | everything else that is not product code |
| `release/` | preparing a version for `main` |
| `hotfix/` | an urgent fix that goes straight to `main`, then back into `develop` |

```bash
git switch develop && git pull
git switch -c fix/telegram-wake-link
```

CI checks these names on every pull request and refuses the ones that do not
match, so a typo is caught before review rather than after the merge.

Feature branches are **squash-merged**: one branch becomes one commit on
`develop`, and the commit message is the pull request title. Write that title as
the commit you would want to read a year from now — the messy commits inside the
branch are yours to make freely, since they disappear on merge.

## Releases and versioning

The package follows [Semantic Versioning](https://semver.org). While the major
number is `0`, the promise is deliberately weaker: a minor bump may break API,
and that is what `0.x` means to everyone consuming it.

Releasing is a maintainer action — see below — but anyone can ask for one. If a
merged change is worth shipping, say so in the pull request, or open an issue
that lists what is waiting on `develop`.

### For maintainers

A release is a pull request from `develop` into `main`. After it merges, tag the
merge commit on `main`: SwiftPM discovers versions from tags, and a repository
without tags has no versions at all.

```bash
git switch main && git pull
git tag -a 0.2.0 -m "0.2.0 — <what changed>"
git push origin 0.2.0
```

Which number to move:

- **patch** (`0.1.0` → `0.1.1`) — fixes only, nothing added or renamed;
- **minor** (`0.1.0` → `0.2.0`) — new API, or a change to existing API while
  still on `0.x`;
- **major** — held back for `1.0.0`, the point at which the public API is
  something we are prepared to keep.

Note that tags are NOT covered by branch protection: `refs/tags/*` is a separate
namespace, so protecting `main` does not stop anyone with write access from
pushing a tag. If that matters, add a repository ruleset targeting tags with
"restrict creations" — the modern replacement for the deprecated tag protection
rules. Contributors working from a fork have no push access at all and cannot
create tags either way.

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

## Documentation

The public API is documented with doc comments, and two modules carry a
documentation catalog with a landing page: `TonConnectCore` and `TonConnectUI`.

```bash
swift package generate-documentation --target TonConnectCore
swift package --disable-sandbox preview-documentation --target TonConnectCore
```

CI builds both and **fails on any DocC warning**. That is not pedantry: a warning
is how you learn that a doc comment points at a symbol somebody renamed, and a
link rotting silently is worse than a build going red.

When you add a public type, curate it under a `## Topics` heading in the
catalog's landing page. Anything left uncurated still appears, but in an
alphabetical pile rather than next to the things it belongs with.

Note that symbols behind `#if canImport(UIKit)` — `SystemWalletOpener`, for one —
do not exist in documentation built on macOS, which is where CI builds it. Do not
curate them, or the build turns red on a symbol that is simply not there.

To publish the result as a static site:

```bash
swift package --allow-writing-to-directory ./docs generate-documentation \
  --target TonConnectCore --output-path ./docs \
  --transform-for-static-hosting --hosting-base-path tonconnect-swift
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

- one concern per pull request, on a branch named for that concern;
- `swift test` green, and new behaviour covered by a test that fails without the
  change;
- if the change came from watching a real wallet misbehave, put the observed
  frame in the pull request — that evidence is worth more than the diff.
