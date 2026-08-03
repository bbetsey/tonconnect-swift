// Generates the reference vectors the Swift SessionCrypto tests are checked against.
//
// The oracle is tweetnacl from node_modules — it arrives with @tonconnect/sdk and is
// the very implementation @tonconnect/protocol uses, so do NOT install it separately:
// a second copy could drift and the vectors would stop proving anything.
//
// Determinism: keys come from fixed seeds (nacl.box.keyPair.fromSecretKey) and the
// nonce is passed explicitly to the low-level nacl.box — NOT to SessionCrypto.encrypt,
// which would generate a nonce of its own and make every run differ.
//
// Run: node generate-vectors.mjs   (or npm run gen-vectors)

import nacl from "tweetnacl";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const outPath = join(
  here,
  "../../Tests/TonConnectNativeEngineTests/Fixtures/session-crypto-vectors.json"
);

const naclVersion = JSON.parse(
  readFileSync(join(here, "node_modules/tweetnacl/package.json"), "utf8")
).version;

// --- hex helpers (same semantics as the oracle's toHexString/hexToByteArray) ---
const toHex = (bytes) =>
  Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
const fromHex = (hex) =>
  Uint8Array.from(hex.match(/.{2}/g) ?? [], (h) => parseInt(h, 16));

// --- deterministic keys from fixed seeds ---
const seeds = [
  "0101010101010101010101010101010101010101010101010101010101010101",
  "a0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebf",
  "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
];
const keypairs = seeds.map((seedHex) => {
  const kp = nacl.box.keyPair.fromSecretKey(fromHex(seedHex));
  return {
    seed: seedHex,
    publicKey: toHex(kp.publicKey),
    secretKey: toHex(kp.secretKey),
  };
});

const [alice, bob] = keypairs;

// --- encrypt cases: the low-level nacl.box with an explicit nonce ---
const nonceA = "000102030405060708090a0b0c0d0e0f1011121314151617";
const nonceB = "ffeeddccbbaa99887766554433221100ffeeddccbbaa9988";

const plaintexts = [
  { nonce: nonceA, text: "hello" },
  { nonce: nonceB, text: "" }, // the empty message
  { nonce: nonceA, text: "привет 🌍" }, // unicode, deliberately non-ASCII
  { nonce: nonceB, text: '{"method":"sendTransaction","params":["..."],"id":"1"}' },
  { nonce: nonceA, text: "x".repeat(1024) }, // long — exercises padding on big buffers
];

const encryptCases = plaintexts.map(({ nonce, text }) => {
  const msg = new TextEncoder().encode(text);
  const cipher = nacl.box(msg, fromHex(nonce), fromHex(bob.publicKey), fromHex(alice.secretKey));
  const wire = new Uint8Array(24 + cipher.length);
  wire.set(fromHex(nonce), 0);
  wire.set(cipher, 24);
  return {
    senderSecretKey: alice.secretKey,
    receiverPublicKey: bob.publicKey,
    nonce,
    plaintext: text,
    expectedWire: toHex(wire),
  };
});

// --- negative decrypt cases ---
const validMsg = new TextEncoder().encode("tamper me");
const validCipher = nacl.box(validMsg, fromHex(nonceA), fromHex(bob.publicKey), fromHex(alice.secretKey));
const validWire = new Uint8Array(24 + validCipher.length);
validWire.set(fromHex(nonceA), 0);
validWire.set(validCipher, 24);

const corrupted = Uint8Array.from(validWire);
corrupted[corrupted.length - 1] ^= 0xff;

const decryptFailureCases = [
  {
    description: "corrupted last ciphertext byte — Poly1305 tag must fail",
    wireHex: toHex(corrupted),
    senderPublicKey: alice.publicKey,
    receiverSecretKey: bob.secretKey,
    expectThrow: true,
  },
  {
    description: "wrong sender public key",
    wireHex: toHex(validWire),
    senderPublicKey: keypairs[2].publicKey, // not Alice
    receiverSecretKey: bob.secretKey,
    expectThrow: true,
  },
  {
    description: "truncated below nonce+tag (39 bytes < 24+16)",
    wireHex: toHex(validWire.slice(0, 39)),
    senderPublicKey: alice.publicKey,
    receiverSecretKey: bob.secretKey,
    expectThrow: true,
  },
  {
    description: "empty wire",
    wireHex: "",
    senderPublicKey: alice.publicKey,
    receiverSecretKey: bob.secretKey,
    expectThrow: true,
  },
];

// --- assemble and write ---
const vectors = {
  protocolVersion: `@tonconnect/protocol@3.0.0 / tweetnacl-js@${naclVersion}`,
  generated: "by Tools/jsbridge/generate-vectors.mjs — regenerate whenever package-lock.json changes",
  keypairs,
  encryptCases,
  decryptFailureCases,
};

mkdirSync(dirname(outPath), { recursive: true });
writeFileSync(outPath, JSON.stringify(vectors, null, 2) + "\n");
console.log(
  `vectors written: ${encryptCases.length} encrypt, ${decryptFailureCases.length} failure, tweetnacl ${naclVersion}`
);
