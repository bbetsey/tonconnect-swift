import * as TonConnectSDK from '@tonconnect/sdk';
import { SessionCrypto, hexToByteArray } from '@tonconnect/protocol';

const g = globalThis as any;
g.TonConnectSDK = TonConnectSDK;                 // kept for the smoke test that only checks the bundle loaded

// The IStorage adapter: three methods forwarding to native storage VERBATIM, by key.
// The SDK owns the key names and the session assembly — do not re-derive them here.
const nativeStorage: TonConnectSDK.IStorage = {
  getItem: (key: string) => g.__nativeStorageGet(key),
  setItem: (key: string, value: string) => g.__nativeStorageSet(key, value),
  removeItem: (key: string) => g.__nativeStorageRemove(key),
};

let instance: TonConnectSDK.TonConnect | null = null;
let unsubscribe: (() => void) | null = null;

// The single place an engine is created. analytics:off silences the SDK's fetch to
// analytics.ton.org — nothing on a dApp's critical path should depend on it.
g.__tcCreateEngine = function (manifestUrl: string): void {
  instance = new TonConnectSDK.TonConnect({
    manifestUrl,
    storage: nativeStorage,
    analytics: { mode: 'off' },
  } as any);
  // One event pump: subscribe ONCE, forward every event to Swift.
  unsubscribe = instance.onStatusChange(
    (walletOrNull) => g.__tcEmitEvent(JSON.stringify({ kind: 'status', wallet: walletOrNull })),
    (error) => g.__tcEmitEvent(JSON.stringify({ kind: 'error', message: String(error) }))
  );
};

// SYNCHRONOUS on purpose: returns the universal link as a string while the SDK
// starts the network and SSE work fire-and-forget. iOS refuses to open a wallet
// when an await sits between the user's tap and the open call.
g.__tcConnect = function (sourceJSON: string, requestJSON: string | null): string {
  const source = JSON.parse(sourceJSON);                 // {universalLink, bridgeUrl}
  const request = requestJSON ? JSON.parse(requestJSON) : undefined; // {tonProof?}
  return instance!.connect(source, request) as string;
};

// Promise-returning methods (Swift awaits them through awaitPromise).
// The AbortSignal is handed in from Swift.
g.__tcRestore = function (): Promise<void> { return instance!.restoreConnection(); };
g.__tcSendTransaction = function (txJSON: string, signal: any): Promise<string> {
  const tx = JSON.parse(txJSON);
  // The Swift DTO carries the spec's wire form (valid_until), while the SDK's
  // JavaScript API expects camelCase (validUntil) and its validator strips keys it
  // does not recognise — observed against a live Tonkeeper.
  if (tx.valid_until !== undefined) { tx.validUntil = tx.valid_until; delete tx.valid_until; }
  return instance!.sendTransaction(tx, signal ? { signal } : undefined)
    .then((r: unknown) => JSON.stringify(r === undefined ? null : r));
};
g.__tcSignData = function (payloadJSON: string, signal: any): Promise<string> {
  return instance!.signData(JSON.parse(payloadJSON), signal ? { signal } : undefined)
    .then((r: unknown) => JSON.stringify(r === undefined ? null : r));
};
g.__tcDisconnect = function (): Promise<void> { return instance!.disconnect(); };

// Lifecycle: Swift calls these from the UIApplication notifications. unPause is what
// makes the SDK recreate its EventSource with the saved last_event_id.
g.__tcPause = function (): void { instance?.pauseConnection(); };
g.__tcUnpause = function (): void { instance?.unPauseConnection(); };

g.__tcDestroy = function (): void {
  if (unsubscribe) { unsubscribe(); unsubscribe = null; }
  instance = null;
};

// The SDK's actual behaviour: restoring without a stored session resolves quietly,
// while the engine contract demands a typed error. Swift asks through this call.
g.__tcIsConnected = function (): boolean {
  return !!(instance && (instance as any).connected);
};

// ── Wallet simulator, for the end-to-end tests ─────────────────────────────────
// Uses the very crypto the SDK uses (@tonconnect/protocol SessionCrypto): bridge
// messages are NaCl-box encrypted, so the E2E suite cannot be built without it.
// Costs roughly 2 KB in the bundle.
let walletSim: SessionCrypto | null = null;
g.__tcTestWalletCreate = function (): string {
  walletSim = new SessionCrypto();
  return walletSim.sessionId;                       // hex public key of the "wallet"
};
g.__tcTestWalletEncrypt = function (clientIdHex: string, json: string): string {
  const bytes = walletSim!.encrypt(json, hexToByteArray(clientIdHex));
  let bin = '';
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return btoa(bin);
};
g.__tcTestWalletDecrypt = function (clientIdHex: string, messageB64: string): string {
  const bin = atob(messageB64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return walletSim!.decrypt(bytes, hexToByteArray(clientIdHex));
};

export {};
