#!/usr/bin/env bash
# Rebuilds Sources/TonConnectJSCoreEngine/Resources/tonconnect-sdk.bundle.js.
#
# The bundle is the official @tonconnect/sdk plus the thin adapter in src/index.ts,
# compiled into one IIFE that JavaScriptCore can evaluate. Versions come from
# package-lock.json, so the output is reproducible: rebuilding without changing
# the lockfile or src/index.ts leaves the bundle byte-identical.
set -euo pipefail
cd "$(dirname "$0")"                 # Tools/jsbridge/

PACKAGE_ROOT=../..
OUT_DIR="$PACKAGE_ROOT/Sources/TonConnectJSCoreEngine/Resources"

npm install
mkdir -p "$OUT_DIR"
npx esbuild@0.24.0 src/index.ts \
  --bundle --format=iife --target=es2017 \
  --outfile="$OUT_DIR/tonconnect-sdk.bundle.js"

echo "wrote $OUT_DIR/tonconnect-sdk.bundle.js"
