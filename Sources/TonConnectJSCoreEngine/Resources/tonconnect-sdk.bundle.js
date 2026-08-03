(() => {
  var __create = Object.create;
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __getProtoOf = Object.getPrototypeOf;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __require = /* @__PURE__ */ ((x) => typeof require !== "undefined" ? require : typeof Proxy !== "undefined" ? new Proxy(x, {
    get: (a, b) => (typeof require !== "undefined" ? require : a)[b]
  }) : x)(function(x) {
    if (typeof require !== "undefined") return require.apply(this, arguments);
    throw Error('Dynamic require of "' + x + '" is not supported');
  });
  var __commonJS = (cb, mod) => function __require2() {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  };
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toESM = (mod, isNodeMode, target) => (target = mod != null ? __create(__getProtoOf(mod)) : {}, __copyProps(
    // If the importer is in node compatibility mode or this is not an ESM
    // file that has been converted to a CommonJS file using a Babel-
    // compatible transform (i.e. "__esModule" has not been set), then set
    // "default" to the CommonJS "module.exports" for node compatibility.
    isNodeMode || !mod || !mod.__esModule ? __defProp(target, "default", { value: mod, enumerable: true }) : target,
    mod
  ));

  // node_modules/tweetnacl-util/nacl-util.js
  var require_nacl_util = __commonJS({
    "node_modules/tweetnacl-util/nacl-util.js"(exports, module) {
      (function(root, f) {
        "use strict";
        if (typeof module !== "undefined" && module.exports) module.exports = f();
        else if (root.nacl) root.nacl.util = f();
        else {
          root.nacl = {};
          root.nacl.util = f();
        }
      })(exports, function() {
        "use strict";
        var util = {};
        function validateBase64(s) {
          if (!/^(?:[A-Za-z0-9+\/]{2}[A-Za-z0-9+\/]{2})*(?:[A-Za-z0-9+\/]{2}==|[A-Za-z0-9+\/]{3}=)?$/.test(s)) {
            throw new TypeError("invalid encoding");
          }
        }
        util.decodeUTF8 = function(s) {
          if (typeof s !== "string") throw new TypeError("expected string");
          var i, d = unescape(encodeURIComponent(s)), b = new Uint8Array(d.length);
          for (i = 0; i < d.length; i++) b[i] = d.charCodeAt(i);
          return b;
        };
        util.encodeUTF8 = function(arr) {
          var i, s = [];
          for (i = 0; i < arr.length; i++) s.push(String.fromCharCode(arr[i]));
          return decodeURIComponent(escape(s.join("")));
        };
        if (typeof atob === "undefined") {
          if (typeof Buffer.from !== "undefined") {
            util.encodeBase64 = function(arr) {
              return Buffer.from(arr).toString("base64");
            };
            util.decodeBase64 = function(s) {
              validateBase64(s);
              return new Uint8Array(Array.prototype.slice.call(Buffer.from(s, "base64"), 0));
            };
          } else {
            util.encodeBase64 = function(arr) {
              return new Buffer(arr).toString("base64");
            };
            util.decodeBase64 = function(s) {
              validateBase64(s);
              return new Uint8Array(Array.prototype.slice.call(new Buffer(s, "base64"), 0));
            };
          }
        } else {
          util.encodeBase64 = function(arr) {
            var i, s = [], len = arr.length;
            for (i = 0; i < len; i++) s.push(String.fromCharCode(arr[i]));
            return btoa(s.join(""));
          };
          util.decodeBase64 = function(s) {
            validateBase64(s);
            var i, d = atob(s), b = new Uint8Array(d.length);
            for (i = 0; i < d.length; i++) b[i] = d.charCodeAt(i);
            return b;
          };
        }
        return util;
      });
    }
  });

  // (disabled):crypto
  var require_crypto = __commonJS({
    "(disabled):crypto"() {
    }
  });

  // node_modules/tweetnacl/nacl-fast.js
  var require_nacl_fast = __commonJS({
    "node_modules/tweetnacl/nacl-fast.js"(exports, module) {
      (function(nacl2) {
        "use strict";
        var gf = function(init) {
          var i, r = new Float64Array(16);
          if (init) for (i = 0; i < init.length; i++) r[i] = init[i];
          return r;
        };
        var randombytes = function() {
          throw new Error("no PRNG");
        };
        var _0 = new Uint8Array(16);
        var _9 = new Uint8Array(32);
        _9[0] = 9;
        var gf0 = gf(), gf1 = gf([1]), _121665 = gf([56129, 1]), D = gf([30883, 4953, 19914, 30187, 55467, 16705, 2637, 112, 59544, 30585, 16505, 36039, 65139, 11119, 27886, 20995]), D2 = gf([61785, 9906, 39828, 60374, 45398, 33411, 5274, 224, 53552, 61171, 33010, 6542, 64743, 22239, 55772, 9222]), X = gf([54554, 36645, 11616, 51542, 42930, 38181, 51040, 26924, 56412, 64982, 57905, 49316, 21502, 52590, 14035, 8553]), Y = gf([26200, 26214, 26214, 26214, 26214, 26214, 26214, 26214, 26214, 26214, 26214, 26214, 26214, 26214, 26214, 26214]), I = gf([41136, 18958, 6951, 50414, 58488, 44335, 6150, 12099, 55207, 15867, 153, 11085, 57099, 20417, 9344, 11139]);
        function ts64(x, i, h, l) {
          x[i] = h >> 24 & 255;
          x[i + 1] = h >> 16 & 255;
          x[i + 2] = h >> 8 & 255;
          x[i + 3] = h & 255;
          x[i + 4] = l >> 24 & 255;
          x[i + 5] = l >> 16 & 255;
          x[i + 6] = l >> 8 & 255;
          x[i + 7] = l & 255;
        }
        function vn(x, xi, y, yi, n) {
          var i, d = 0;
          for (i = 0; i < n; i++) d |= x[xi + i] ^ y[yi + i];
          return (1 & d - 1 >>> 8) - 1;
        }
        function crypto_verify_16(x, xi, y, yi) {
          return vn(x, xi, y, yi, 16);
        }
        function crypto_verify_32(x, xi, y, yi) {
          return vn(x, xi, y, yi, 32);
        }
        function core_salsa20(o, p, k, c) {
          var j0 = c[0] & 255 | (c[1] & 255) << 8 | (c[2] & 255) << 16 | (c[3] & 255) << 24, j1 = k[0] & 255 | (k[1] & 255) << 8 | (k[2] & 255) << 16 | (k[3] & 255) << 24, j2 = k[4] & 255 | (k[5] & 255) << 8 | (k[6] & 255) << 16 | (k[7] & 255) << 24, j3 = k[8] & 255 | (k[9] & 255) << 8 | (k[10] & 255) << 16 | (k[11] & 255) << 24, j4 = k[12] & 255 | (k[13] & 255) << 8 | (k[14] & 255) << 16 | (k[15] & 255) << 24, j5 = c[4] & 255 | (c[5] & 255) << 8 | (c[6] & 255) << 16 | (c[7] & 255) << 24, j6 = p[0] & 255 | (p[1] & 255) << 8 | (p[2] & 255) << 16 | (p[3] & 255) << 24, j7 = p[4] & 255 | (p[5] & 255) << 8 | (p[6] & 255) << 16 | (p[7] & 255) << 24, j8 = p[8] & 255 | (p[9] & 255) << 8 | (p[10] & 255) << 16 | (p[11] & 255) << 24, j9 = p[12] & 255 | (p[13] & 255) << 8 | (p[14] & 255) << 16 | (p[15] & 255) << 24, j10 = c[8] & 255 | (c[9] & 255) << 8 | (c[10] & 255) << 16 | (c[11] & 255) << 24, j11 = k[16] & 255 | (k[17] & 255) << 8 | (k[18] & 255) << 16 | (k[19] & 255) << 24, j12 = k[20] & 255 | (k[21] & 255) << 8 | (k[22] & 255) << 16 | (k[23] & 255) << 24, j13 = k[24] & 255 | (k[25] & 255) << 8 | (k[26] & 255) << 16 | (k[27] & 255) << 24, j14 = k[28] & 255 | (k[29] & 255) << 8 | (k[30] & 255) << 16 | (k[31] & 255) << 24, j15 = c[12] & 255 | (c[13] & 255) << 8 | (c[14] & 255) << 16 | (c[15] & 255) << 24;
          var x0 = j0, x1 = j1, x2 = j2, x3 = j3, x4 = j4, x5 = j5, x6 = j6, x7 = j7, x8 = j8, x9 = j9, x10 = j10, x11 = j11, x12 = j12, x13 = j13, x14 = j14, x15 = j15, u;
          for (var i = 0; i < 20; i += 2) {
            u = x0 + x12 | 0;
            x4 ^= u << 7 | u >>> 32 - 7;
            u = x4 + x0 | 0;
            x8 ^= u << 9 | u >>> 32 - 9;
            u = x8 + x4 | 0;
            x12 ^= u << 13 | u >>> 32 - 13;
            u = x12 + x8 | 0;
            x0 ^= u << 18 | u >>> 32 - 18;
            u = x5 + x1 | 0;
            x9 ^= u << 7 | u >>> 32 - 7;
            u = x9 + x5 | 0;
            x13 ^= u << 9 | u >>> 32 - 9;
            u = x13 + x9 | 0;
            x1 ^= u << 13 | u >>> 32 - 13;
            u = x1 + x13 | 0;
            x5 ^= u << 18 | u >>> 32 - 18;
            u = x10 + x6 | 0;
            x14 ^= u << 7 | u >>> 32 - 7;
            u = x14 + x10 | 0;
            x2 ^= u << 9 | u >>> 32 - 9;
            u = x2 + x14 | 0;
            x6 ^= u << 13 | u >>> 32 - 13;
            u = x6 + x2 | 0;
            x10 ^= u << 18 | u >>> 32 - 18;
            u = x15 + x11 | 0;
            x3 ^= u << 7 | u >>> 32 - 7;
            u = x3 + x15 | 0;
            x7 ^= u << 9 | u >>> 32 - 9;
            u = x7 + x3 | 0;
            x11 ^= u << 13 | u >>> 32 - 13;
            u = x11 + x7 | 0;
            x15 ^= u << 18 | u >>> 32 - 18;
            u = x0 + x3 | 0;
            x1 ^= u << 7 | u >>> 32 - 7;
            u = x1 + x0 | 0;
            x2 ^= u << 9 | u >>> 32 - 9;
            u = x2 + x1 | 0;
            x3 ^= u << 13 | u >>> 32 - 13;
            u = x3 + x2 | 0;
            x0 ^= u << 18 | u >>> 32 - 18;
            u = x5 + x4 | 0;
            x6 ^= u << 7 | u >>> 32 - 7;
            u = x6 + x5 | 0;
            x7 ^= u << 9 | u >>> 32 - 9;
            u = x7 + x6 | 0;
            x4 ^= u << 13 | u >>> 32 - 13;
            u = x4 + x7 | 0;
            x5 ^= u << 18 | u >>> 32 - 18;
            u = x10 + x9 | 0;
            x11 ^= u << 7 | u >>> 32 - 7;
            u = x11 + x10 | 0;
            x8 ^= u << 9 | u >>> 32 - 9;
            u = x8 + x11 | 0;
            x9 ^= u << 13 | u >>> 32 - 13;
            u = x9 + x8 | 0;
            x10 ^= u << 18 | u >>> 32 - 18;
            u = x15 + x14 | 0;
            x12 ^= u << 7 | u >>> 32 - 7;
            u = x12 + x15 | 0;
            x13 ^= u << 9 | u >>> 32 - 9;
            u = x13 + x12 | 0;
            x14 ^= u << 13 | u >>> 32 - 13;
            u = x14 + x13 | 0;
            x15 ^= u << 18 | u >>> 32 - 18;
          }
          x0 = x0 + j0 | 0;
          x1 = x1 + j1 | 0;
          x2 = x2 + j2 | 0;
          x3 = x3 + j3 | 0;
          x4 = x4 + j4 | 0;
          x5 = x5 + j5 | 0;
          x6 = x6 + j6 | 0;
          x7 = x7 + j7 | 0;
          x8 = x8 + j8 | 0;
          x9 = x9 + j9 | 0;
          x10 = x10 + j10 | 0;
          x11 = x11 + j11 | 0;
          x12 = x12 + j12 | 0;
          x13 = x13 + j13 | 0;
          x14 = x14 + j14 | 0;
          x15 = x15 + j15 | 0;
          o[0] = x0 >>> 0 & 255;
          o[1] = x0 >>> 8 & 255;
          o[2] = x0 >>> 16 & 255;
          o[3] = x0 >>> 24 & 255;
          o[4] = x1 >>> 0 & 255;
          o[5] = x1 >>> 8 & 255;
          o[6] = x1 >>> 16 & 255;
          o[7] = x1 >>> 24 & 255;
          o[8] = x2 >>> 0 & 255;
          o[9] = x2 >>> 8 & 255;
          o[10] = x2 >>> 16 & 255;
          o[11] = x2 >>> 24 & 255;
          o[12] = x3 >>> 0 & 255;
          o[13] = x3 >>> 8 & 255;
          o[14] = x3 >>> 16 & 255;
          o[15] = x3 >>> 24 & 255;
          o[16] = x4 >>> 0 & 255;
          o[17] = x4 >>> 8 & 255;
          o[18] = x4 >>> 16 & 255;
          o[19] = x4 >>> 24 & 255;
          o[20] = x5 >>> 0 & 255;
          o[21] = x5 >>> 8 & 255;
          o[22] = x5 >>> 16 & 255;
          o[23] = x5 >>> 24 & 255;
          o[24] = x6 >>> 0 & 255;
          o[25] = x6 >>> 8 & 255;
          o[26] = x6 >>> 16 & 255;
          o[27] = x6 >>> 24 & 255;
          o[28] = x7 >>> 0 & 255;
          o[29] = x7 >>> 8 & 255;
          o[30] = x7 >>> 16 & 255;
          o[31] = x7 >>> 24 & 255;
          o[32] = x8 >>> 0 & 255;
          o[33] = x8 >>> 8 & 255;
          o[34] = x8 >>> 16 & 255;
          o[35] = x8 >>> 24 & 255;
          o[36] = x9 >>> 0 & 255;
          o[37] = x9 >>> 8 & 255;
          o[38] = x9 >>> 16 & 255;
          o[39] = x9 >>> 24 & 255;
          o[40] = x10 >>> 0 & 255;
          o[41] = x10 >>> 8 & 255;
          o[42] = x10 >>> 16 & 255;
          o[43] = x10 >>> 24 & 255;
          o[44] = x11 >>> 0 & 255;
          o[45] = x11 >>> 8 & 255;
          o[46] = x11 >>> 16 & 255;
          o[47] = x11 >>> 24 & 255;
          o[48] = x12 >>> 0 & 255;
          o[49] = x12 >>> 8 & 255;
          o[50] = x12 >>> 16 & 255;
          o[51] = x12 >>> 24 & 255;
          o[52] = x13 >>> 0 & 255;
          o[53] = x13 >>> 8 & 255;
          o[54] = x13 >>> 16 & 255;
          o[55] = x13 >>> 24 & 255;
          o[56] = x14 >>> 0 & 255;
          o[57] = x14 >>> 8 & 255;
          o[58] = x14 >>> 16 & 255;
          o[59] = x14 >>> 24 & 255;
          o[60] = x15 >>> 0 & 255;
          o[61] = x15 >>> 8 & 255;
          o[62] = x15 >>> 16 & 255;
          o[63] = x15 >>> 24 & 255;
        }
        function core_hsalsa20(o, p, k, c) {
          var j0 = c[0] & 255 | (c[1] & 255) << 8 | (c[2] & 255) << 16 | (c[3] & 255) << 24, j1 = k[0] & 255 | (k[1] & 255) << 8 | (k[2] & 255) << 16 | (k[3] & 255) << 24, j2 = k[4] & 255 | (k[5] & 255) << 8 | (k[6] & 255) << 16 | (k[7] & 255) << 24, j3 = k[8] & 255 | (k[9] & 255) << 8 | (k[10] & 255) << 16 | (k[11] & 255) << 24, j4 = k[12] & 255 | (k[13] & 255) << 8 | (k[14] & 255) << 16 | (k[15] & 255) << 24, j5 = c[4] & 255 | (c[5] & 255) << 8 | (c[6] & 255) << 16 | (c[7] & 255) << 24, j6 = p[0] & 255 | (p[1] & 255) << 8 | (p[2] & 255) << 16 | (p[3] & 255) << 24, j7 = p[4] & 255 | (p[5] & 255) << 8 | (p[6] & 255) << 16 | (p[7] & 255) << 24, j8 = p[8] & 255 | (p[9] & 255) << 8 | (p[10] & 255) << 16 | (p[11] & 255) << 24, j9 = p[12] & 255 | (p[13] & 255) << 8 | (p[14] & 255) << 16 | (p[15] & 255) << 24, j10 = c[8] & 255 | (c[9] & 255) << 8 | (c[10] & 255) << 16 | (c[11] & 255) << 24, j11 = k[16] & 255 | (k[17] & 255) << 8 | (k[18] & 255) << 16 | (k[19] & 255) << 24, j12 = k[20] & 255 | (k[21] & 255) << 8 | (k[22] & 255) << 16 | (k[23] & 255) << 24, j13 = k[24] & 255 | (k[25] & 255) << 8 | (k[26] & 255) << 16 | (k[27] & 255) << 24, j14 = k[28] & 255 | (k[29] & 255) << 8 | (k[30] & 255) << 16 | (k[31] & 255) << 24, j15 = c[12] & 255 | (c[13] & 255) << 8 | (c[14] & 255) << 16 | (c[15] & 255) << 24;
          var x0 = j0, x1 = j1, x2 = j2, x3 = j3, x4 = j4, x5 = j5, x6 = j6, x7 = j7, x8 = j8, x9 = j9, x10 = j10, x11 = j11, x12 = j12, x13 = j13, x14 = j14, x15 = j15, u;
          for (var i = 0; i < 20; i += 2) {
            u = x0 + x12 | 0;
            x4 ^= u << 7 | u >>> 32 - 7;
            u = x4 + x0 | 0;
            x8 ^= u << 9 | u >>> 32 - 9;
            u = x8 + x4 | 0;
            x12 ^= u << 13 | u >>> 32 - 13;
            u = x12 + x8 | 0;
            x0 ^= u << 18 | u >>> 32 - 18;
            u = x5 + x1 | 0;
            x9 ^= u << 7 | u >>> 32 - 7;
            u = x9 + x5 | 0;
            x13 ^= u << 9 | u >>> 32 - 9;
            u = x13 + x9 | 0;
            x1 ^= u << 13 | u >>> 32 - 13;
            u = x1 + x13 | 0;
            x5 ^= u << 18 | u >>> 32 - 18;
            u = x10 + x6 | 0;
            x14 ^= u << 7 | u >>> 32 - 7;
            u = x14 + x10 | 0;
            x2 ^= u << 9 | u >>> 32 - 9;
            u = x2 + x14 | 0;
            x6 ^= u << 13 | u >>> 32 - 13;
            u = x6 + x2 | 0;
            x10 ^= u << 18 | u >>> 32 - 18;
            u = x15 + x11 | 0;
            x3 ^= u << 7 | u >>> 32 - 7;
            u = x3 + x15 | 0;
            x7 ^= u << 9 | u >>> 32 - 9;
            u = x7 + x3 | 0;
            x11 ^= u << 13 | u >>> 32 - 13;
            u = x11 + x7 | 0;
            x15 ^= u << 18 | u >>> 32 - 18;
            u = x0 + x3 | 0;
            x1 ^= u << 7 | u >>> 32 - 7;
            u = x1 + x0 | 0;
            x2 ^= u << 9 | u >>> 32 - 9;
            u = x2 + x1 | 0;
            x3 ^= u << 13 | u >>> 32 - 13;
            u = x3 + x2 | 0;
            x0 ^= u << 18 | u >>> 32 - 18;
            u = x5 + x4 | 0;
            x6 ^= u << 7 | u >>> 32 - 7;
            u = x6 + x5 | 0;
            x7 ^= u << 9 | u >>> 32 - 9;
            u = x7 + x6 | 0;
            x4 ^= u << 13 | u >>> 32 - 13;
            u = x4 + x7 | 0;
            x5 ^= u << 18 | u >>> 32 - 18;
            u = x10 + x9 | 0;
            x11 ^= u << 7 | u >>> 32 - 7;
            u = x11 + x10 | 0;
            x8 ^= u << 9 | u >>> 32 - 9;
            u = x8 + x11 | 0;
            x9 ^= u << 13 | u >>> 32 - 13;
            u = x9 + x8 | 0;
            x10 ^= u << 18 | u >>> 32 - 18;
            u = x15 + x14 | 0;
            x12 ^= u << 7 | u >>> 32 - 7;
            u = x12 + x15 | 0;
            x13 ^= u << 9 | u >>> 32 - 9;
            u = x13 + x12 | 0;
            x14 ^= u << 13 | u >>> 32 - 13;
            u = x14 + x13 | 0;
            x15 ^= u << 18 | u >>> 32 - 18;
          }
          o[0] = x0 >>> 0 & 255;
          o[1] = x0 >>> 8 & 255;
          o[2] = x0 >>> 16 & 255;
          o[3] = x0 >>> 24 & 255;
          o[4] = x5 >>> 0 & 255;
          o[5] = x5 >>> 8 & 255;
          o[6] = x5 >>> 16 & 255;
          o[7] = x5 >>> 24 & 255;
          o[8] = x10 >>> 0 & 255;
          o[9] = x10 >>> 8 & 255;
          o[10] = x10 >>> 16 & 255;
          o[11] = x10 >>> 24 & 255;
          o[12] = x15 >>> 0 & 255;
          o[13] = x15 >>> 8 & 255;
          o[14] = x15 >>> 16 & 255;
          o[15] = x15 >>> 24 & 255;
          o[16] = x6 >>> 0 & 255;
          o[17] = x6 >>> 8 & 255;
          o[18] = x6 >>> 16 & 255;
          o[19] = x6 >>> 24 & 255;
          o[20] = x7 >>> 0 & 255;
          o[21] = x7 >>> 8 & 255;
          o[22] = x7 >>> 16 & 255;
          o[23] = x7 >>> 24 & 255;
          o[24] = x8 >>> 0 & 255;
          o[25] = x8 >>> 8 & 255;
          o[26] = x8 >>> 16 & 255;
          o[27] = x8 >>> 24 & 255;
          o[28] = x9 >>> 0 & 255;
          o[29] = x9 >>> 8 & 255;
          o[30] = x9 >>> 16 & 255;
          o[31] = x9 >>> 24 & 255;
        }
        function crypto_core_salsa20(out, inp, k, c) {
          core_salsa20(out, inp, k, c);
        }
        function crypto_core_hsalsa20(out, inp, k, c) {
          core_hsalsa20(out, inp, k, c);
        }
        var sigma = new Uint8Array([101, 120, 112, 97, 110, 100, 32, 51, 50, 45, 98, 121, 116, 101, 32, 107]);
        function crypto_stream_salsa20_xor(c, cpos, m, mpos, b, n, k) {
          var z = new Uint8Array(16), x = new Uint8Array(64);
          var u, i;
          for (i = 0; i < 16; i++) z[i] = 0;
          for (i = 0; i < 8; i++) z[i] = n[i];
          while (b >= 64) {
            crypto_core_salsa20(x, z, k, sigma);
            for (i = 0; i < 64; i++) c[cpos + i] = m[mpos + i] ^ x[i];
            u = 1;
            for (i = 8; i < 16; i++) {
              u = u + (z[i] & 255) | 0;
              z[i] = u & 255;
              u >>>= 8;
            }
            b -= 64;
            cpos += 64;
            mpos += 64;
          }
          if (b > 0) {
            crypto_core_salsa20(x, z, k, sigma);
            for (i = 0; i < b; i++) c[cpos + i] = m[mpos + i] ^ x[i];
          }
          return 0;
        }
        function crypto_stream_salsa20(c, cpos, b, n, k) {
          var z = new Uint8Array(16), x = new Uint8Array(64);
          var u, i;
          for (i = 0; i < 16; i++) z[i] = 0;
          for (i = 0; i < 8; i++) z[i] = n[i];
          while (b >= 64) {
            crypto_core_salsa20(x, z, k, sigma);
            for (i = 0; i < 64; i++) c[cpos + i] = x[i];
            u = 1;
            for (i = 8; i < 16; i++) {
              u = u + (z[i] & 255) | 0;
              z[i] = u & 255;
              u >>>= 8;
            }
            b -= 64;
            cpos += 64;
          }
          if (b > 0) {
            crypto_core_salsa20(x, z, k, sigma);
            for (i = 0; i < b; i++) c[cpos + i] = x[i];
          }
          return 0;
        }
        function crypto_stream(c, cpos, d, n, k) {
          var s = new Uint8Array(32);
          crypto_core_hsalsa20(s, n, k, sigma);
          var sn = new Uint8Array(8);
          for (var i = 0; i < 8; i++) sn[i] = n[i + 16];
          return crypto_stream_salsa20(c, cpos, d, sn, s);
        }
        function crypto_stream_xor(c, cpos, m, mpos, d, n, k) {
          var s = new Uint8Array(32);
          crypto_core_hsalsa20(s, n, k, sigma);
          var sn = new Uint8Array(8);
          for (var i = 0; i < 8; i++) sn[i] = n[i + 16];
          return crypto_stream_salsa20_xor(c, cpos, m, mpos, d, sn, s);
        }
        var poly1305 = function(key) {
          this.buffer = new Uint8Array(16);
          this.r = new Uint16Array(10);
          this.h = new Uint16Array(10);
          this.pad = new Uint16Array(8);
          this.leftover = 0;
          this.fin = 0;
          var t0, t1, t2, t3, t4, t5, t6, t7;
          t0 = key[0] & 255 | (key[1] & 255) << 8;
          this.r[0] = t0 & 8191;
          t1 = key[2] & 255 | (key[3] & 255) << 8;
          this.r[1] = (t0 >>> 13 | t1 << 3) & 8191;
          t2 = key[4] & 255 | (key[5] & 255) << 8;
          this.r[2] = (t1 >>> 10 | t2 << 6) & 7939;
          t3 = key[6] & 255 | (key[7] & 255) << 8;
          this.r[3] = (t2 >>> 7 | t3 << 9) & 8191;
          t4 = key[8] & 255 | (key[9] & 255) << 8;
          this.r[4] = (t3 >>> 4 | t4 << 12) & 255;
          this.r[5] = t4 >>> 1 & 8190;
          t5 = key[10] & 255 | (key[11] & 255) << 8;
          this.r[6] = (t4 >>> 14 | t5 << 2) & 8191;
          t6 = key[12] & 255 | (key[13] & 255) << 8;
          this.r[7] = (t5 >>> 11 | t6 << 5) & 8065;
          t7 = key[14] & 255 | (key[15] & 255) << 8;
          this.r[8] = (t6 >>> 8 | t7 << 8) & 8191;
          this.r[9] = t7 >>> 5 & 127;
          this.pad[0] = key[16] & 255 | (key[17] & 255) << 8;
          this.pad[1] = key[18] & 255 | (key[19] & 255) << 8;
          this.pad[2] = key[20] & 255 | (key[21] & 255) << 8;
          this.pad[3] = key[22] & 255 | (key[23] & 255) << 8;
          this.pad[4] = key[24] & 255 | (key[25] & 255) << 8;
          this.pad[5] = key[26] & 255 | (key[27] & 255) << 8;
          this.pad[6] = key[28] & 255 | (key[29] & 255) << 8;
          this.pad[7] = key[30] & 255 | (key[31] & 255) << 8;
        };
        poly1305.prototype.blocks = function(m, mpos, bytes) {
          var hibit = this.fin ? 0 : 1 << 11;
          var t0, t1, t2, t3, t4, t5, t6, t7, c;
          var d0, d1, d2, d3, d4, d5, d6, d7, d8, d9;
          var h0 = this.h[0], h1 = this.h[1], h2 = this.h[2], h3 = this.h[3], h4 = this.h[4], h5 = this.h[5], h6 = this.h[6], h7 = this.h[7], h8 = this.h[8], h9 = this.h[9];
          var r0 = this.r[0], r1 = this.r[1], r2 = this.r[2], r3 = this.r[3], r4 = this.r[4], r5 = this.r[5], r6 = this.r[6], r7 = this.r[7], r8 = this.r[8], r9 = this.r[9];
          while (bytes >= 16) {
            t0 = m[mpos + 0] & 255 | (m[mpos + 1] & 255) << 8;
            h0 += t0 & 8191;
            t1 = m[mpos + 2] & 255 | (m[mpos + 3] & 255) << 8;
            h1 += (t0 >>> 13 | t1 << 3) & 8191;
            t2 = m[mpos + 4] & 255 | (m[mpos + 5] & 255) << 8;
            h2 += (t1 >>> 10 | t2 << 6) & 8191;
            t3 = m[mpos + 6] & 255 | (m[mpos + 7] & 255) << 8;
            h3 += (t2 >>> 7 | t3 << 9) & 8191;
            t4 = m[mpos + 8] & 255 | (m[mpos + 9] & 255) << 8;
            h4 += (t3 >>> 4 | t4 << 12) & 8191;
            h5 += t4 >>> 1 & 8191;
            t5 = m[mpos + 10] & 255 | (m[mpos + 11] & 255) << 8;
            h6 += (t4 >>> 14 | t5 << 2) & 8191;
            t6 = m[mpos + 12] & 255 | (m[mpos + 13] & 255) << 8;
            h7 += (t5 >>> 11 | t6 << 5) & 8191;
            t7 = m[mpos + 14] & 255 | (m[mpos + 15] & 255) << 8;
            h8 += (t6 >>> 8 | t7 << 8) & 8191;
            h9 += t7 >>> 5 | hibit;
            c = 0;
            d0 = c;
            d0 += h0 * r0;
            d0 += h1 * (5 * r9);
            d0 += h2 * (5 * r8);
            d0 += h3 * (5 * r7);
            d0 += h4 * (5 * r6);
            c = d0 >>> 13;
            d0 &= 8191;
            d0 += h5 * (5 * r5);
            d0 += h6 * (5 * r4);
            d0 += h7 * (5 * r3);
            d0 += h8 * (5 * r2);
            d0 += h9 * (5 * r1);
            c += d0 >>> 13;
            d0 &= 8191;
            d1 = c;
            d1 += h0 * r1;
            d1 += h1 * r0;
            d1 += h2 * (5 * r9);
            d1 += h3 * (5 * r8);
            d1 += h4 * (5 * r7);
            c = d1 >>> 13;
            d1 &= 8191;
            d1 += h5 * (5 * r6);
            d1 += h6 * (5 * r5);
            d1 += h7 * (5 * r4);
            d1 += h8 * (5 * r3);
            d1 += h9 * (5 * r2);
            c += d1 >>> 13;
            d1 &= 8191;
            d2 = c;
            d2 += h0 * r2;
            d2 += h1 * r1;
            d2 += h2 * r0;
            d2 += h3 * (5 * r9);
            d2 += h4 * (5 * r8);
            c = d2 >>> 13;
            d2 &= 8191;
            d2 += h5 * (5 * r7);
            d2 += h6 * (5 * r6);
            d2 += h7 * (5 * r5);
            d2 += h8 * (5 * r4);
            d2 += h9 * (5 * r3);
            c += d2 >>> 13;
            d2 &= 8191;
            d3 = c;
            d3 += h0 * r3;
            d3 += h1 * r2;
            d3 += h2 * r1;
            d3 += h3 * r0;
            d3 += h4 * (5 * r9);
            c = d3 >>> 13;
            d3 &= 8191;
            d3 += h5 * (5 * r8);
            d3 += h6 * (5 * r7);
            d3 += h7 * (5 * r6);
            d3 += h8 * (5 * r5);
            d3 += h9 * (5 * r4);
            c += d3 >>> 13;
            d3 &= 8191;
            d4 = c;
            d4 += h0 * r4;
            d4 += h1 * r3;
            d4 += h2 * r2;
            d4 += h3 * r1;
            d4 += h4 * r0;
            c = d4 >>> 13;
            d4 &= 8191;
            d4 += h5 * (5 * r9);
            d4 += h6 * (5 * r8);
            d4 += h7 * (5 * r7);
            d4 += h8 * (5 * r6);
            d4 += h9 * (5 * r5);
            c += d4 >>> 13;
            d4 &= 8191;
            d5 = c;
            d5 += h0 * r5;
            d5 += h1 * r4;
            d5 += h2 * r3;
            d5 += h3 * r2;
            d5 += h4 * r1;
            c = d5 >>> 13;
            d5 &= 8191;
            d5 += h5 * r0;
            d5 += h6 * (5 * r9);
            d5 += h7 * (5 * r8);
            d5 += h8 * (5 * r7);
            d5 += h9 * (5 * r6);
            c += d5 >>> 13;
            d5 &= 8191;
            d6 = c;
            d6 += h0 * r6;
            d6 += h1 * r5;
            d6 += h2 * r4;
            d6 += h3 * r3;
            d6 += h4 * r2;
            c = d6 >>> 13;
            d6 &= 8191;
            d6 += h5 * r1;
            d6 += h6 * r0;
            d6 += h7 * (5 * r9);
            d6 += h8 * (5 * r8);
            d6 += h9 * (5 * r7);
            c += d6 >>> 13;
            d6 &= 8191;
            d7 = c;
            d7 += h0 * r7;
            d7 += h1 * r6;
            d7 += h2 * r5;
            d7 += h3 * r4;
            d7 += h4 * r3;
            c = d7 >>> 13;
            d7 &= 8191;
            d7 += h5 * r2;
            d7 += h6 * r1;
            d7 += h7 * r0;
            d7 += h8 * (5 * r9);
            d7 += h9 * (5 * r8);
            c += d7 >>> 13;
            d7 &= 8191;
            d8 = c;
            d8 += h0 * r8;
            d8 += h1 * r7;
            d8 += h2 * r6;
            d8 += h3 * r5;
            d8 += h4 * r4;
            c = d8 >>> 13;
            d8 &= 8191;
            d8 += h5 * r3;
            d8 += h6 * r2;
            d8 += h7 * r1;
            d8 += h8 * r0;
            d8 += h9 * (5 * r9);
            c += d8 >>> 13;
            d8 &= 8191;
            d9 = c;
            d9 += h0 * r9;
            d9 += h1 * r8;
            d9 += h2 * r7;
            d9 += h3 * r6;
            d9 += h4 * r5;
            c = d9 >>> 13;
            d9 &= 8191;
            d9 += h5 * r4;
            d9 += h6 * r3;
            d9 += h7 * r2;
            d9 += h8 * r1;
            d9 += h9 * r0;
            c += d9 >>> 13;
            d9 &= 8191;
            c = (c << 2) + c | 0;
            c = c + d0 | 0;
            d0 = c & 8191;
            c = c >>> 13;
            d1 += c;
            h0 = d0;
            h1 = d1;
            h2 = d2;
            h3 = d3;
            h4 = d4;
            h5 = d5;
            h6 = d6;
            h7 = d7;
            h8 = d8;
            h9 = d9;
            mpos += 16;
            bytes -= 16;
          }
          this.h[0] = h0;
          this.h[1] = h1;
          this.h[2] = h2;
          this.h[3] = h3;
          this.h[4] = h4;
          this.h[5] = h5;
          this.h[6] = h6;
          this.h[7] = h7;
          this.h[8] = h8;
          this.h[9] = h9;
        };
        poly1305.prototype.finish = function(mac, macpos) {
          var g2 = new Uint16Array(10);
          var c, mask, f, i;
          if (this.leftover) {
            i = this.leftover;
            this.buffer[i++] = 1;
            for (; i < 16; i++) this.buffer[i] = 0;
            this.fin = 1;
            this.blocks(this.buffer, 0, 16);
          }
          c = this.h[1] >>> 13;
          this.h[1] &= 8191;
          for (i = 2; i < 10; i++) {
            this.h[i] += c;
            c = this.h[i] >>> 13;
            this.h[i] &= 8191;
          }
          this.h[0] += c * 5;
          c = this.h[0] >>> 13;
          this.h[0] &= 8191;
          this.h[1] += c;
          c = this.h[1] >>> 13;
          this.h[1] &= 8191;
          this.h[2] += c;
          g2[0] = this.h[0] + 5;
          c = g2[0] >>> 13;
          g2[0] &= 8191;
          for (i = 1; i < 10; i++) {
            g2[i] = this.h[i] + c;
            c = g2[i] >>> 13;
            g2[i] &= 8191;
          }
          g2[9] -= 1 << 13;
          mask = (c ^ 1) - 1;
          for (i = 0; i < 10; i++) g2[i] &= mask;
          mask = ~mask;
          for (i = 0; i < 10; i++) this.h[i] = this.h[i] & mask | g2[i];
          this.h[0] = (this.h[0] | this.h[1] << 13) & 65535;
          this.h[1] = (this.h[1] >>> 3 | this.h[2] << 10) & 65535;
          this.h[2] = (this.h[2] >>> 6 | this.h[3] << 7) & 65535;
          this.h[3] = (this.h[3] >>> 9 | this.h[4] << 4) & 65535;
          this.h[4] = (this.h[4] >>> 12 | this.h[5] << 1 | this.h[6] << 14) & 65535;
          this.h[5] = (this.h[6] >>> 2 | this.h[7] << 11) & 65535;
          this.h[6] = (this.h[7] >>> 5 | this.h[8] << 8) & 65535;
          this.h[7] = (this.h[8] >>> 8 | this.h[9] << 5) & 65535;
          f = this.h[0] + this.pad[0];
          this.h[0] = f & 65535;
          for (i = 1; i < 8; i++) {
            f = (this.h[i] + this.pad[i] | 0) + (f >>> 16) | 0;
            this.h[i] = f & 65535;
          }
          mac[macpos + 0] = this.h[0] >>> 0 & 255;
          mac[macpos + 1] = this.h[0] >>> 8 & 255;
          mac[macpos + 2] = this.h[1] >>> 0 & 255;
          mac[macpos + 3] = this.h[1] >>> 8 & 255;
          mac[macpos + 4] = this.h[2] >>> 0 & 255;
          mac[macpos + 5] = this.h[2] >>> 8 & 255;
          mac[macpos + 6] = this.h[3] >>> 0 & 255;
          mac[macpos + 7] = this.h[3] >>> 8 & 255;
          mac[macpos + 8] = this.h[4] >>> 0 & 255;
          mac[macpos + 9] = this.h[4] >>> 8 & 255;
          mac[macpos + 10] = this.h[5] >>> 0 & 255;
          mac[macpos + 11] = this.h[5] >>> 8 & 255;
          mac[macpos + 12] = this.h[6] >>> 0 & 255;
          mac[macpos + 13] = this.h[6] >>> 8 & 255;
          mac[macpos + 14] = this.h[7] >>> 0 & 255;
          mac[macpos + 15] = this.h[7] >>> 8 & 255;
        };
        poly1305.prototype.update = function(m, mpos, bytes) {
          var i, want;
          if (this.leftover) {
            want = 16 - this.leftover;
            if (want > bytes)
              want = bytes;
            for (i = 0; i < want; i++)
              this.buffer[this.leftover + i] = m[mpos + i];
            bytes -= want;
            mpos += want;
            this.leftover += want;
            if (this.leftover < 16)
              return;
            this.blocks(this.buffer, 0, 16);
            this.leftover = 0;
          }
          if (bytes >= 16) {
            want = bytes - bytes % 16;
            this.blocks(m, mpos, want);
            mpos += want;
            bytes -= want;
          }
          if (bytes) {
            for (i = 0; i < bytes; i++)
              this.buffer[this.leftover + i] = m[mpos + i];
            this.leftover += bytes;
          }
        };
        function crypto_onetimeauth(out, outpos, m, mpos, n, k) {
          var s = new poly1305(k);
          s.update(m, mpos, n);
          s.finish(out, outpos);
          return 0;
        }
        function crypto_onetimeauth_verify(h, hpos, m, mpos, n, k) {
          var x = new Uint8Array(16);
          crypto_onetimeauth(x, 0, m, mpos, n, k);
          return crypto_verify_16(h, hpos, x, 0);
        }
        function crypto_secretbox(c, m, d, n, k) {
          var i;
          if (d < 32) return -1;
          crypto_stream_xor(c, 0, m, 0, d, n, k);
          crypto_onetimeauth(c, 16, c, 32, d - 32, c);
          for (i = 0; i < 16; i++) c[i] = 0;
          return 0;
        }
        function crypto_secretbox_open(m, c, d, n, k) {
          var i;
          var x = new Uint8Array(32);
          if (d < 32) return -1;
          crypto_stream(x, 0, 32, n, k);
          if (crypto_onetimeauth_verify(c, 16, c, 32, d - 32, x) !== 0) return -1;
          crypto_stream_xor(m, 0, c, 0, d, n, k);
          for (i = 0; i < 32; i++) m[i] = 0;
          return 0;
        }
        function set25519(r, a) {
          var i;
          for (i = 0; i < 16; i++) r[i] = a[i] | 0;
        }
        function car25519(o) {
          var i, v, c = 1;
          for (i = 0; i < 16; i++) {
            v = o[i] + c + 65535;
            c = Math.floor(v / 65536);
            o[i] = v - c * 65536;
          }
          o[0] += c - 1 + 37 * (c - 1);
        }
        function sel25519(p, q, b) {
          var t, c = ~(b - 1);
          for (var i = 0; i < 16; i++) {
            t = c & (p[i] ^ q[i]);
            p[i] ^= t;
            q[i] ^= t;
          }
        }
        function pack25519(o, n) {
          var i, j, b;
          var m = gf(), t = gf();
          for (i = 0; i < 16; i++) t[i] = n[i];
          car25519(t);
          car25519(t);
          car25519(t);
          for (j = 0; j < 2; j++) {
            m[0] = t[0] - 65517;
            for (i = 1; i < 15; i++) {
              m[i] = t[i] - 65535 - (m[i - 1] >> 16 & 1);
              m[i - 1] &= 65535;
            }
            m[15] = t[15] - 32767 - (m[14] >> 16 & 1);
            b = m[15] >> 16 & 1;
            m[14] &= 65535;
            sel25519(t, m, 1 - b);
          }
          for (i = 0; i < 16; i++) {
            o[2 * i] = t[i] & 255;
            o[2 * i + 1] = t[i] >> 8;
          }
        }
        function neq25519(a, b) {
          var c = new Uint8Array(32), d = new Uint8Array(32);
          pack25519(c, a);
          pack25519(d, b);
          return crypto_verify_32(c, 0, d, 0);
        }
        function par25519(a) {
          var d = new Uint8Array(32);
          pack25519(d, a);
          return d[0] & 1;
        }
        function unpack25519(o, n) {
          var i;
          for (i = 0; i < 16; i++) o[i] = n[2 * i] + (n[2 * i + 1] << 8);
          o[15] &= 32767;
        }
        function A(o, a, b) {
          for (var i = 0; i < 16; i++) o[i] = a[i] + b[i];
        }
        function Z(o, a, b) {
          for (var i = 0; i < 16; i++) o[i] = a[i] - b[i];
        }
        function M(o, a, b) {
          var v, c, t0 = 0, t1 = 0, t2 = 0, t3 = 0, t4 = 0, t5 = 0, t6 = 0, t7 = 0, t8 = 0, t9 = 0, t10 = 0, t11 = 0, t12 = 0, t13 = 0, t14 = 0, t15 = 0, t16 = 0, t17 = 0, t18 = 0, t19 = 0, t20 = 0, t21 = 0, t22 = 0, t23 = 0, t24 = 0, t25 = 0, t26 = 0, t27 = 0, t28 = 0, t29 = 0, t30 = 0, b0 = b[0], b1 = b[1], b2 = b[2], b3 = b[3], b4 = b[4], b5 = b[5], b6 = b[6], b7 = b[7], b8 = b[8], b9 = b[9], b10 = b[10], b11 = b[11], b12 = b[12], b13 = b[13], b14 = b[14], b15 = b[15];
          v = a[0];
          t0 += v * b0;
          t1 += v * b1;
          t2 += v * b2;
          t3 += v * b3;
          t4 += v * b4;
          t5 += v * b5;
          t6 += v * b6;
          t7 += v * b7;
          t8 += v * b8;
          t9 += v * b9;
          t10 += v * b10;
          t11 += v * b11;
          t12 += v * b12;
          t13 += v * b13;
          t14 += v * b14;
          t15 += v * b15;
          v = a[1];
          t1 += v * b0;
          t2 += v * b1;
          t3 += v * b2;
          t4 += v * b3;
          t5 += v * b4;
          t6 += v * b5;
          t7 += v * b6;
          t8 += v * b7;
          t9 += v * b8;
          t10 += v * b9;
          t11 += v * b10;
          t12 += v * b11;
          t13 += v * b12;
          t14 += v * b13;
          t15 += v * b14;
          t16 += v * b15;
          v = a[2];
          t2 += v * b0;
          t3 += v * b1;
          t4 += v * b2;
          t5 += v * b3;
          t6 += v * b4;
          t7 += v * b5;
          t8 += v * b6;
          t9 += v * b7;
          t10 += v * b8;
          t11 += v * b9;
          t12 += v * b10;
          t13 += v * b11;
          t14 += v * b12;
          t15 += v * b13;
          t16 += v * b14;
          t17 += v * b15;
          v = a[3];
          t3 += v * b0;
          t4 += v * b1;
          t5 += v * b2;
          t6 += v * b3;
          t7 += v * b4;
          t8 += v * b5;
          t9 += v * b6;
          t10 += v * b7;
          t11 += v * b8;
          t12 += v * b9;
          t13 += v * b10;
          t14 += v * b11;
          t15 += v * b12;
          t16 += v * b13;
          t17 += v * b14;
          t18 += v * b15;
          v = a[4];
          t4 += v * b0;
          t5 += v * b1;
          t6 += v * b2;
          t7 += v * b3;
          t8 += v * b4;
          t9 += v * b5;
          t10 += v * b6;
          t11 += v * b7;
          t12 += v * b8;
          t13 += v * b9;
          t14 += v * b10;
          t15 += v * b11;
          t16 += v * b12;
          t17 += v * b13;
          t18 += v * b14;
          t19 += v * b15;
          v = a[5];
          t5 += v * b0;
          t6 += v * b1;
          t7 += v * b2;
          t8 += v * b3;
          t9 += v * b4;
          t10 += v * b5;
          t11 += v * b6;
          t12 += v * b7;
          t13 += v * b8;
          t14 += v * b9;
          t15 += v * b10;
          t16 += v * b11;
          t17 += v * b12;
          t18 += v * b13;
          t19 += v * b14;
          t20 += v * b15;
          v = a[6];
          t6 += v * b0;
          t7 += v * b1;
          t8 += v * b2;
          t9 += v * b3;
          t10 += v * b4;
          t11 += v * b5;
          t12 += v * b6;
          t13 += v * b7;
          t14 += v * b8;
          t15 += v * b9;
          t16 += v * b10;
          t17 += v * b11;
          t18 += v * b12;
          t19 += v * b13;
          t20 += v * b14;
          t21 += v * b15;
          v = a[7];
          t7 += v * b0;
          t8 += v * b1;
          t9 += v * b2;
          t10 += v * b3;
          t11 += v * b4;
          t12 += v * b5;
          t13 += v * b6;
          t14 += v * b7;
          t15 += v * b8;
          t16 += v * b9;
          t17 += v * b10;
          t18 += v * b11;
          t19 += v * b12;
          t20 += v * b13;
          t21 += v * b14;
          t22 += v * b15;
          v = a[8];
          t8 += v * b0;
          t9 += v * b1;
          t10 += v * b2;
          t11 += v * b3;
          t12 += v * b4;
          t13 += v * b5;
          t14 += v * b6;
          t15 += v * b7;
          t16 += v * b8;
          t17 += v * b9;
          t18 += v * b10;
          t19 += v * b11;
          t20 += v * b12;
          t21 += v * b13;
          t22 += v * b14;
          t23 += v * b15;
          v = a[9];
          t9 += v * b0;
          t10 += v * b1;
          t11 += v * b2;
          t12 += v * b3;
          t13 += v * b4;
          t14 += v * b5;
          t15 += v * b6;
          t16 += v * b7;
          t17 += v * b8;
          t18 += v * b9;
          t19 += v * b10;
          t20 += v * b11;
          t21 += v * b12;
          t22 += v * b13;
          t23 += v * b14;
          t24 += v * b15;
          v = a[10];
          t10 += v * b0;
          t11 += v * b1;
          t12 += v * b2;
          t13 += v * b3;
          t14 += v * b4;
          t15 += v * b5;
          t16 += v * b6;
          t17 += v * b7;
          t18 += v * b8;
          t19 += v * b9;
          t20 += v * b10;
          t21 += v * b11;
          t22 += v * b12;
          t23 += v * b13;
          t24 += v * b14;
          t25 += v * b15;
          v = a[11];
          t11 += v * b0;
          t12 += v * b1;
          t13 += v * b2;
          t14 += v * b3;
          t15 += v * b4;
          t16 += v * b5;
          t17 += v * b6;
          t18 += v * b7;
          t19 += v * b8;
          t20 += v * b9;
          t21 += v * b10;
          t22 += v * b11;
          t23 += v * b12;
          t24 += v * b13;
          t25 += v * b14;
          t26 += v * b15;
          v = a[12];
          t12 += v * b0;
          t13 += v * b1;
          t14 += v * b2;
          t15 += v * b3;
          t16 += v * b4;
          t17 += v * b5;
          t18 += v * b6;
          t19 += v * b7;
          t20 += v * b8;
          t21 += v * b9;
          t22 += v * b10;
          t23 += v * b11;
          t24 += v * b12;
          t25 += v * b13;
          t26 += v * b14;
          t27 += v * b15;
          v = a[13];
          t13 += v * b0;
          t14 += v * b1;
          t15 += v * b2;
          t16 += v * b3;
          t17 += v * b4;
          t18 += v * b5;
          t19 += v * b6;
          t20 += v * b7;
          t21 += v * b8;
          t22 += v * b9;
          t23 += v * b10;
          t24 += v * b11;
          t25 += v * b12;
          t26 += v * b13;
          t27 += v * b14;
          t28 += v * b15;
          v = a[14];
          t14 += v * b0;
          t15 += v * b1;
          t16 += v * b2;
          t17 += v * b3;
          t18 += v * b4;
          t19 += v * b5;
          t20 += v * b6;
          t21 += v * b7;
          t22 += v * b8;
          t23 += v * b9;
          t24 += v * b10;
          t25 += v * b11;
          t26 += v * b12;
          t27 += v * b13;
          t28 += v * b14;
          t29 += v * b15;
          v = a[15];
          t15 += v * b0;
          t16 += v * b1;
          t17 += v * b2;
          t18 += v * b3;
          t19 += v * b4;
          t20 += v * b5;
          t21 += v * b6;
          t22 += v * b7;
          t23 += v * b8;
          t24 += v * b9;
          t25 += v * b10;
          t26 += v * b11;
          t27 += v * b12;
          t28 += v * b13;
          t29 += v * b14;
          t30 += v * b15;
          t0 += 38 * t16;
          t1 += 38 * t17;
          t2 += 38 * t18;
          t3 += 38 * t19;
          t4 += 38 * t20;
          t5 += 38 * t21;
          t6 += 38 * t22;
          t7 += 38 * t23;
          t8 += 38 * t24;
          t9 += 38 * t25;
          t10 += 38 * t26;
          t11 += 38 * t27;
          t12 += 38 * t28;
          t13 += 38 * t29;
          t14 += 38 * t30;
          c = 1;
          v = t0 + c + 65535;
          c = Math.floor(v / 65536);
          t0 = v - c * 65536;
          v = t1 + c + 65535;
          c = Math.floor(v / 65536);
          t1 = v - c * 65536;
          v = t2 + c + 65535;
          c = Math.floor(v / 65536);
          t2 = v - c * 65536;
          v = t3 + c + 65535;
          c = Math.floor(v / 65536);
          t3 = v - c * 65536;
          v = t4 + c + 65535;
          c = Math.floor(v / 65536);
          t4 = v - c * 65536;
          v = t5 + c + 65535;
          c = Math.floor(v / 65536);
          t5 = v - c * 65536;
          v = t6 + c + 65535;
          c = Math.floor(v / 65536);
          t6 = v - c * 65536;
          v = t7 + c + 65535;
          c = Math.floor(v / 65536);
          t7 = v - c * 65536;
          v = t8 + c + 65535;
          c = Math.floor(v / 65536);
          t8 = v - c * 65536;
          v = t9 + c + 65535;
          c = Math.floor(v / 65536);
          t9 = v - c * 65536;
          v = t10 + c + 65535;
          c = Math.floor(v / 65536);
          t10 = v - c * 65536;
          v = t11 + c + 65535;
          c = Math.floor(v / 65536);
          t11 = v - c * 65536;
          v = t12 + c + 65535;
          c = Math.floor(v / 65536);
          t12 = v - c * 65536;
          v = t13 + c + 65535;
          c = Math.floor(v / 65536);
          t13 = v - c * 65536;
          v = t14 + c + 65535;
          c = Math.floor(v / 65536);
          t14 = v - c * 65536;
          v = t15 + c + 65535;
          c = Math.floor(v / 65536);
          t15 = v - c * 65536;
          t0 += c - 1 + 37 * (c - 1);
          c = 1;
          v = t0 + c + 65535;
          c = Math.floor(v / 65536);
          t0 = v - c * 65536;
          v = t1 + c + 65535;
          c = Math.floor(v / 65536);
          t1 = v - c * 65536;
          v = t2 + c + 65535;
          c = Math.floor(v / 65536);
          t2 = v - c * 65536;
          v = t3 + c + 65535;
          c = Math.floor(v / 65536);
          t3 = v - c * 65536;
          v = t4 + c + 65535;
          c = Math.floor(v / 65536);
          t4 = v - c * 65536;
          v = t5 + c + 65535;
          c = Math.floor(v / 65536);
          t5 = v - c * 65536;
          v = t6 + c + 65535;
          c = Math.floor(v / 65536);
          t6 = v - c * 65536;
          v = t7 + c + 65535;
          c = Math.floor(v / 65536);
          t7 = v - c * 65536;
          v = t8 + c + 65535;
          c = Math.floor(v / 65536);
          t8 = v - c * 65536;
          v = t9 + c + 65535;
          c = Math.floor(v / 65536);
          t9 = v - c * 65536;
          v = t10 + c + 65535;
          c = Math.floor(v / 65536);
          t10 = v - c * 65536;
          v = t11 + c + 65535;
          c = Math.floor(v / 65536);
          t11 = v - c * 65536;
          v = t12 + c + 65535;
          c = Math.floor(v / 65536);
          t12 = v - c * 65536;
          v = t13 + c + 65535;
          c = Math.floor(v / 65536);
          t13 = v - c * 65536;
          v = t14 + c + 65535;
          c = Math.floor(v / 65536);
          t14 = v - c * 65536;
          v = t15 + c + 65535;
          c = Math.floor(v / 65536);
          t15 = v - c * 65536;
          t0 += c - 1 + 37 * (c - 1);
          o[0] = t0;
          o[1] = t1;
          o[2] = t2;
          o[3] = t3;
          o[4] = t4;
          o[5] = t5;
          o[6] = t6;
          o[7] = t7;
          o[8] = t8;
          o[9] = t9;
          o[10] = t10;
          o[11] = t11;
          o[12] = t12;
          o[13] = t13;
          o[14] = t14;
          o[15] = t15;
        }
        function S(o, a) {
          M(o, a, a);
        }
        function inv25519(o, i) {
          var c = gf();
          var a;
          for (a = 0; a < 16; a++) c[a] = i[a];
          for (a = 253; a >= 0; a--) {
            S(c, c);
            if (a !== 2 && a !== 4) M(c, c, i);
          }
          for (a = 0; a < 16; a++) o[a] = c[a];
        }
        function pow2523(o, i) {
          var c = gf();
          var a;
          for (a = 0; a < 16; a++) c[a] = i[a];
          for (a = 250; a >= 0; a--) {
            S(c, c);
            if (a !== 1) M(c, c, i);
          }
          for (a = 0; a < 16; a++) o[a] = c[a];
        }
        function crypto_scalarmult(q, n, p) {
          var z = new Uint8Array(32);
          var x = new Float64Array(80), r, i;
          var a = gf(), b = gf(), c = gf(), d = gf(), e = gf(), f = gf();
          for (i = 0; i < 31; i++) z[i] = n[i];
          z[31] = n[31] & 127 | 64;
          z[0] &= 248;
          unpack25519(x, p);
          for (i = 0; i < 16; i++) {
            b[i] = x[i];
            d[i] = a[i] = c[i] = 0;
          }
          a[0] = d[0] = 1;
          for (i = 254; i >= 0; --i) {
            r = z[i >>> 3] >>> (i & 7) & 1;
            sel25519(a, b, r);
            sel25519(c, d, r);
            A(e, a, c);
            Z(a, a, c);
            A(c, b, d);
            Z(b, b, d);
            S(d, e);
            S(f, a);
            M(a, c, a);
            M(c, b, e);
            A(e, a, c);
            Z(a, a, c);
            S(b, a);
            Z(c, d, f);
            M(a, c, _121665);
            A(a, a, d);
            M(c, c, a);
            M(a, d, f);
            M(d, b, x);
            S(b, e);
            sel25519(a, b, r);
            sel25519(c, d, r);
          }
          for (i = 0; i < 16; i++) {
            x[i + 16] = a[i];
            x[i + 32] = c[i];
            x[i + 48] = b[i];
            x[i + 64] = d[i];
          }
          var x32 = x.subarray(32);
          var x16 = x.subarray(16);
          inv25519(x32, x32);
          M(x16, x16, x32);
          pack25519(q, x16);
          return 0;
        }
        function crypto_scalarmult_base(q, n) {
          return crypto_scalarmult(q, n, _9);
        }
        function crypto_box_keypair(y, x) {
          randombytes(x, 32);
          return crypto_scalarmult_base(y, x);
        }
        function crypto_box_beforenm(k, y, x) {
          var s = new Uint8Array(32);
          crypto_scalarmult(s, x, y);
          return crypto_core_hsalsa20(k, _0, s, sigma);
        }
        var crypto_box_afternm = crypto_secretbox;
        var crypto_box_open_afternm = crypto_secretbox_open;
        function crypto_box(c, m, d, n, y, x) {
          var k = new Uint8Array(32);
          crypto_box_beforenm(k, y, x);
          return crypto_box_afternm(c, m, d, n, k);
        }
        function crypto_box_open(m, c, d, n, y, x) {
          var k = new Uint8Array(32);
          crypto_box_beforenm(k, y, x);
          return crypto_box_open_afternm(m, c, d, n, k);
        }
        var K = [
          1116352408,
          3609767458,
          1899447441,
          602891725,
          3049323471,
          3964484399,
          3921009573,
          2173295548,
          961987163,
          4081628472,
          1508970993,
          3053834265,
          2453635748,
          2937671579,
          2870763221,
          3664609560,
          3624381080,
          2734883394,
          310598401,
          1164996542,
          607225278,
          1323610764,
          1426881987,
          3590304994,
          1925078388,
          4068182383,
          2162078206,
          991336113,
          2614888103,
          633803317,
          3248222580,
          3479774868,
          3835390401,
          2666613458,
          4022224774,
          944711139,
          264347078,
          2341262773,
          604807628,
          2007800933,
          770255983,
          1495990901,
          1249150122,
          1856431235,
          1555081692,
          3175218132,
          1996064986,
          2198950837,
          2554220882,
          3999719339,
          2821834349,
          766784016,
          2952996808,
          2566594879,
          3210313671,
          3203337956,
          3336571891,
          1034457026,
          3584528711,
          2466948901,
          113926993,
          3758326383,
          338241895,
          168717936,
          666307205,
          1188179964,
          773529912,
          1546045734,
          1294757372,
          1522805485,
          1396182291,
          2643833823,
          1695183700,
          2343527390,
          1986661051,
          1014477480,
          2177026350,
          1206759142,
          2456956037,
          344077627,
          2730485921,
          1290863460,
          2820302411,
          3158454273,
          3259730800,
          3505952657,
          3345764771,
          106217008,
          3516065817,
          3606008344,
          3600352804,
          1432725776,
          4094571909,
          1467031594,
          275423344,
          851169720,
          430227734,
          3100823752,
          506948616,
          1363258195,
          659060556,
          3750685593,
          883997877,
          3785050280,
          958139571,
          3318307427,
          1322822218,
          3812723403,
          1537002063,
          2003034995,
          1747873779,
          3602036899,
          1955562222,
          1575990012,
          2024104815,
          1125592928,
          2227730452,
          2716904306,
          2361852424,
          442776044,
          2428436474,
          593698344,
          2756734187,
          3733110249,
          3204031479,
          2999351573,
          3329325298,
          3815920427,
          3391569614,
          3928383900,
          3515267271,
          566280711,
          3940187606,
          3454069534,
          4118630271,
          4000239992,
          116418474,
          1914138554,
          174292421,
          2731055270,
          289380356,
          3203993006,
          460393269,
          320620315,
          685471733,
          587496836,
          852142971,
          1086792851,
          1017036298,
          365543100,
          1126000580,
          2618297676,
          1288033470,
          3409855158,
          1501505948,
          4234509866,
          1607167915,
          987167468,
          1816402316,
          1246189591
        ];
        function crypto_hashblocks_hl(hh, hl, m, n) {
          var wh = new Int32Array(16), wl = new Int32Array(16), bh0, bh1, bh2, bh3, bh4, bh5, bh6, bh7, bl0, bl1, bl2, bl3, bl4, bl5, bl6, bl7, th, tl, i, j, h, l, a, b, c, d;
          var ah0 = hh[0], ah1 = hh[1], ah2 = hh[2], ah3 = hh[3], ah4 = hh[4], ah5 = hh[5], ah6 = hh[6], ah7 = hh[7], al0 = hl[0], al1 = hl[1], al2 = hl[2], al3 = hl[3], al4 = hl[4], al5 = hl[5], al6 = hl[6], al7 = hl[7];
          var pos = 0;
          while (n >= 128) {
            for (i = 0; i < 16; i++) {
              j = 8 * i + pos;
              wh[i] = m[j + 0] << 24 | m[j + 1] << 16 | m[j + 2] << 8 | m[j + 3];
              wl[i] = m[j + 4] << 24 | m[j + 5] << 16 | m[j + 6] << 8 | m[j + 7];
            }
            for (i = 0; i < 80; i++) {
              bh0 = ah0;
              bh1 = ah1;
              bh2 = ah2;
              bh3 = ah3;
              bh4 = ah4;
              bh5 = ah5;
              bh6 = ah6;
              bh7 = ah7;
              bl0 = al0;
              bl1 = al1;
              bl2 = al2;
              bl3 = al3;
              bl4 = al4;
              bl5 = al5;
              bl6 = al6;
              bl7 = al7;
              h = ah7;
              l = al7;
              a = l & 65535;
              b = l >>> 16;
              c = h & 65535;
              d = h >>> 16;
              h = (ah4 >>> 14 | al4 << 32 - 14) ^ (ah4 >>> 18 | al4 << 32 - 18) ^ (al4 >>> 41 - 32 | ah4 << 32 - (41 - 32));
              l = (al4 >>> 14 | ah4 << 32 - 14) ^ (al4 >>> 18 | ah4 << 32 - 18) ^ (ah4 >>> 41 - 32 | al4 << 32 - (41 - 32));
              a += l & 65535;
              b += l >>> 16;
              c += h & 65535;
              d += h >>> 16;
              h = ah4 & ah5 ^ ~ah4 & ah6;
              l = al4 & al5 ^ ~al4 & al6;
              a += l & 65535;
              b += l >>> 16;
              c += h & 65535;
              d += h >>> 16;
              h = K[i * 2];
              l = K[i * 2 + 1];
              a += l & 65535;
              b += l >>> 16;
              c += h & 65535;
              d += h >>> 16;
              h = wh[i % 16];
              l = wl[i % 16];
              a += l & 65535;
              b += l >>> 16;
              c += h & 65535;
              d += h >>> 16;
              b += a >>> 16;
              c += b >>> 16;
              d += c >>> 16;
              th = c & 65535 | d << 16;
              tl = a & 65535 | b << 16;
              h = th;
              l = tl;
              a = l & 65535;
              b = l >>> 16;
              c = h & 65535;
              d = h >>> 16;
              h = (ah0 >>> 28 | al0 << 32 - 28) ^ (al0 >>> 34 - 32 | ah0 << 32 - (34 - 32)) ^ (al0 >>> 39 - 32 | ah0 << 32 - (39 - 32));
              l = (al0 >>> 28 | ah0 << 32 - 28) ^ (ah0 >>> 34 - 32 | al0 << 32 - (34 - 32)) ^ (ah0 >>> 39 - 32 | al0 << 32 - (39 - 32));
              a += l & 65535;
              b += l >>> 16;
              c += h & 65535;
              d += h >>> 16;
              h = ah0 & ah1 ^ ah0 & ah2 ^ ah1 & ah2;
              l = al0 & al1 ^ al0 & al2 ^ al1 & al2;
              a += l & 65535;
              b += l >>> 16;
              c += h & 65535;
              d += h >>> 16;
              b += a >>> 16;
              c += b >>> 16;
              d += c >>> 16;
              bh7 = c & 65535 | d << 16;
              bl7 = a & 65535 | b << 16;
              h = bh3;
              l = bl3;
              a = l & 65535;
              b = l >>> 16;
              c = h & 65535;
              d = h >>> 16;
              h = th;
              l = tl;
              a += l & 65535;
              b += l >>> 16;
              c += h & 65535;
              d += h >>> 16;
              b += a >>> 16;
              c += b >>> 16;
              d += c >>> 16;
              bh3 = c & 65535 | d << 16;
              bl3 = a & 65535 | b << 16;
              ah1 = bh0;
              ah2 = bh1;
              ah3 = bh2;
              ah4 = bh3;
              ah5 = bh4;
              ah6 = bh5;
              ah7 = bh6;
              ah0 = bh7;
              al1 = bl0;
              al2 = bl1;
              al3 = bl2;
              al4 = bl3;
              al5 = bl4;
              al6 = bl5;
              al7 = bl6;
              al0 = bl7;
              if (i % 16 === 15) {
                for (j = 0; j < 16; j++) {
                  h = wh[j];
                  l = wl[j];
                  a = l & 65535;
                  b = l >>> 16;
                  c = h & 65535;
                  d = h >>> 16;
                  h = wh[(j + 9) % 16];
                  l = wl[(j + 9) % 16];
                  a += l & 65535;
                  b += l >>> 16;
                  c += h & 65535;
                  d += h >>> 16;
                  th = wh[(j + 1) % 16];
                  tl = wl[(j + 1) % 16];
                  h = (th >>> 1 | tl << 32 - 1) ^ (th >>> 8 | tl << 32 - 8) ^ th >>> 7;
                  l = (tl >>> 1 | th << 32 - 1) ^ (tl >>> 8 | th << 32 - 8) ^ (tl >>> 7 | th << 32 - 7);
                  a += l & 65535;
                  b += l >>> 16;
                  c += h & 65535;
                  d += h >>> 16;
                  th = wh[(j + 14) % 16];
                  tl = wl[(j + 14) % 16];
                  h = (th >>> 19 | tl << 32 - 19) ^ (tl >>> 61 - 32 | th << 32 - (61 - 32)) ^ th >>> 6;
                  l = (tl >>> 19 | th << 32 - 19) ^ (th >>> 61 - 32 | tl << 32 - (61 - 32)) ^ (tl >>> 6 | th << 32 - 6);
                  a += l & 65535;
                  b += l >>> 16;
                  c += h & 65535;
                  d += h >>> 16;
                  b += a >>> 16;
                  c += b >>> 16;
                  d += c >>> 16;
                  wh[j] = c & 65535 | d << 16;
                  wl[j] = a & 65535 | b << 16;
                }
              }
            }
            h = ah0;
            l = al0;
            a = l & 65535;
            b = l >>> 16;
            c = h & 65535;
            d = h >>> 16;
            h = hh[0];
            l = hl[0];
            a += l & 65535;
            b += l >>> 16;
            c += h & 65535;
            d += h >>> 16;
            b += a >>> 16;
            c += b >>> 16;
            d += c >>> 16;
            hh[0] = ah0 = c & 65535 | d << 16;
            hl[0] = al0 = a & 65535 | b << 16;
            h = ah1;
            l = al1;
            a = l & 65535;
            b = l >>> 16;
            c = h & 65535;
            d = h >>> 16;
            h = hh[1];
            l = hl[1];
            a += l & 65535;
            b += l >>> 16;
            c += h & 65535;
            d += h >>> 16;
            b += a >>> 16;
            c += b >>> 16;
            d += c >>> 16;
            hh[1] = ah1 = c & 65535 | d << 16;
            hl[1] = al1 = a & 65535 | b << 16;
            h = ah2;
            l = al2;
            a = l & 65535;
            b = l >>> 16;
            c = h & 65535;
            d = h >>> 16;
            h = hh[2];
            l = hl[2];
            a += l & 65535;
            b += l >>> 16;
            c += h & 65535;
            d += h >>> 16;
            b += a >>> 16;
            c += b >>> 16;
            d += c >>> 16;
            hh[2] = ah2 = c & 65535 | d << 16;
            hl[2] = al2 = a & 65535 | b << 16;
            h = ah3;
            l = al3;
            a = l & 65535;
            b = l >>> 16;
            c = h & 65535;
            d = h >>> 16;
            h = hh[3];
            l = hl[3];
            a += l & 65535;
            b += l >>> 16;
            c += h & 65535;
            d += h >>> 16;
            b += a >>> 16;
            c += b >>> 16;
            d += c >>> 16;
            hh[3] = ah3 = c & 65535 | d << 16;
            hl[3] = al3 = a & 65535 | b << 16;
            h = ah4;
            l = al4;
            a = l & 65535;
            b = l >>> 16;
            c = h & 65535;
            d = h >>> 16;
            h = hh[4];
            l = hl[4];
            a += l & 65535;
            b += l >>> 16;
            c += h & 65535;
            d += h >>> 16;
            b += a >>> 16;
            c += b >>> 16;
            d += c >>> 16;
            hh[4] = ah4 = c & 65535 | d << 16;
            hl[4] = al4 = a & 65535 | b << 16;
            h = ah5;
            l = al5;
            a = l & 65535;
            b = l >>> 16;
            c = h & 65535;
            d = h >>> 16;
            h = hh[5];
            l = hl[5];
            a += l & 65535;
            b += l >>> 16;
            c += h & 65535;
            d += h >>> 16;
            b += a >>> 16;
            c += b >>> 16;
            d += c >>> 16;
            hh[5] = ah5 = c & 65535 | d << 16;
            hl[5] = al5 = a & 65535 | b << 16;
            h = ah6;
            l = al6;
            a = l & 65535;
            b = l >>> 16;
            c = h & 65535;
            d = h >>> 16;
            h = hh[6];
            l = hl[6];
            a += l & 65535;
            b += l >>> 16;
            c += h & 65535;
            d += h >>> 16;
            b += a >>> 16;
            c += b >>> 16;
            d += c >>> 16;
            hh[6] = ah6 = c & 65535 | d << 16;
            hl[6] = al6 = a & 65535 | b << 16;
            h = ah7;
            l = al7;
            a = l & 65535;
            b = l >>> 16;
            c = h & 65535;
            d = h >>> 16;
            h = hh[7];
            l = hl[7];
            a += l & 65535;
            b += l >>> 16;
            c += h & 65535;
            d += h >>> 16;
            b += a >>> 16;
            c += b >>> 16;
            d += c >>> 16;
            hh[7] = ah7 = c & 65535 | d << 16;
            hl[7] = al7 = a & 65535 | b << 16;
            pos += 128;
            n -= 128;
          }
          return n;
        }
        function crypto_hash(out, m, n) {
          var hh = new Int32Array(8), hl = new Int32Array(8), x = new Uint8Array(256), i, b = n;
          hh[0] = 1779033703;
          hh[1] = 3144134277;
          hh[2] = 1013904242;
          hh[3] = 2773480762;
          hh[4] = 1359893119;
          hh[5] = 2600822924;
          hh[6] = 528734635;
          hh[7] = 1541459225;
          hl[0] = 4089235720;
          hl[1] = 2227873595;
          hl[2] = 4271175723;
          hl[3] = 1595750129;
          hl[4] = 2917565137;
          hl[5] = 725511199;
          hl[6] = 4215389547;
          hl[7] = 327033209;
          crypto_hashblocks_hl(hh, hl, m, n);
          n %= 128;
          for (i = 0; i < n; i++) x[i] = m[b - n + i];
          x[n] = 128;
          n = 256 - 128 * (n < 112 ? 1 : 0);
          x[n - 9] = 0;
          ts64(x, n - 8, b / 536870912 | 0, b << 3);
          crypto_hashblocks_hl(hh, hl, x, n);
          for (i = 0; i < 8; i++) ts64(out, 8 * i, hh[i], hl[i]);
          return 0;
        }
        function add(p, q) {
          var a = gf(), b = gf(), c = gf(), d = gf(), e = gf(), f = gf(), g2 = gf(), h = gf(), t = gf();
          Z(a, p[1], p[0]);
          Z(t, q[1], q[0]);
          M(a, a, t);
          A(b, p[0], p[1]);
          A(t, q[0], q[1]);
          M(b, b, t);
          M(c, p[3], q[3]);
          M(c, c, D2);
          M(d, p[2], q[2]);
          A(d, d, d);
          Z(e, b, a);
          Z(f, d, c);
          A(g2, d, c);
          A(h, b, a);
          M(p[0], e, f);
          M(p[1], h, g2);
          M(p[2], g2, f);
          M(p[3], e, h);
        }
        function cswap(p, q, b) {
          var i;
          for (i = 0; i < 4; i++) {
            sel25519(p[i], q[i], b);
          }
        }
        function pack(r, p) {
          var tx = gf(), ty = gf(), zi = gf();
          inv25519(zi, p[2]);
          M(tx, p[0], zi);
          M(ty, p[1], zi);
          pack25519(r, ty);
          r[31] ^= par25519(tx) << 7;
        }
        function scalarmult(p, q, s) {
          var b, i;
          set25519(p[0], gf0);
          set25519(p[1], gf1);
          set25519(p[2], gf1);
          set25519(p[3], gf0);
          for (i = 255; i >= 0; --i) {
            b = s[i / 8 | 0] >> (i & 7) & 1;
            cswap(p, q, b);
            add(q, p);
            add(p, p);
            cswap(p, q, b);
          }
        }
        function scalarbase(p, s) {
          var q = [gf(), gf(), gf(), gf()];
          set25519(q[0], X);
          set25519(q[1], Y);
          set25519(q[2], gf1);
          M(q[3], X, Y);
          scalarmult(p, q, s);
        }
        function crypto_sign_keypair(pk, sk, seeded) {
          var d = new Uint8Array(64);
          var p = [gf(), gf(), gf(), gf()];
          var i;
          if (!seeded) randombytes(sk, 32);
          crypto_hash(d, sk, 32);
          d[0] &= 248;
          d[31] &= 127;
          d[31] |= 64;
          scalarbase(p, d);
          pack(pk, p);
          for (i = 0; i < 32; i++) sk[i + 32] = pk[i];
          return 0;
        }
        var L = new Float64Array([237, 211, 245, 92, 26, 99, 18, 88, 214, 156, 247, 162, 222, 249, 222, 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16]);
        function modL(r, x) {
          var carry, i, j, k;
          for (i = 63; i >= 32; --i) {
            carry = 0;
            for (j = i - 32, k = i - 12; j < k; ++j) {
              x[j] += carry - 16 * x[i] * L[j - (i - 32)];
              carry = Math.floor((x[j] + 128) / 256);
              x[j] -= carry * 256;
            }
            x[j] += carry;
            x[i] = 0;
          }
          carry = 0;
          for (j = 0; j < 32; j++) {
            x[j] += carry - (x[31] >> 4) * L[j];
            carry = x[j] >> 8;
            x[j] &= 255;
          }
          for (j = 0; j < 32; j++) x[j] -= carry * L[j];
          for (i = 0; i < 32; i++) {
            x[i + 1] += x[i] >> 8;
            r[i] = x[i] & 255;
          }
        }
        function reduce(r) {
          var x = new Float64Array(64), i;
          for (i = 0; i < 64; i++) x[i] = r[i];
          for (i = 0; i < 64; i++) r[i] = 0;
          modL(r, x);
        }
        function crypto_sign(sm, m, n, sk) {
          var d = new Uint8Array(64), h = new Uint8Array(64), r = new Uint8Array(64);
          var i, j, x = new Float64Array(64);
          var p = [gf(), gf(), gf(), gf()];
          crypto_hash(d, sk, 32);
          d[0] &= 248;
          d[31] &= 127;
          d[31] |= 64;
          var smlen = n + 64;
          for (i = 0; i < n; i++) sm[64 + i] = m[i];
          for (i = 0; i < 32; i++) sm[32 + i] = d[32 + i];
          crypto_hash(r, sm.subarray(32), n + 32);
          reduce(r);
          scalarbase(p, r);
          pack(sm, p);
          for (i = 32; i < 64; i++) sm[i] = sk[i];
          crypto_hash(h, sm, n + 64);
          reduce(h);
          for (i = 0; i < 64; i++) x[i] = 0;
          for (i = 0; i < 32; i++) x[i] = r[i];
          for (i = 0; i < 32; i++) {
            for (j = 0; j < 32; j++) {
              x[i + j] += h[i] * d[j];
            }
          }
          modL(sm.subarray(32), x);
          return smlen;
        }
        function unpackneg(r, p) {
          var t = gf(), chk = gf(), num = gf(), den = gf(), den2 = gf(), den4 = gf(), den6 = gf();
          set25519(r[2], gf1);
          unpack25519(r[1], p);
          S(num, r[1]);
          M(den, num, D);
          Z(num, num, r[2]);
          A(den, r[2], den);
          S(den2, den);
          S(den4, den2);
          M(den6, den4, den2);
          M(t, den6, num);
          M(t, t, den);
          pow2523(t, t);
          M(t, t, num);
          M(t, t, den);
          M(t, t, den);
          M(r[0], t, den);
          S(chk, r[0]);
          M(chk, chk, den);
          if (neq25519(chk, num)) M(r[0], r[0], I);
          S(chk, r[0]);
          M(chk, chk, den);
          if (neq25519(chk, num)) return -1;
          if (par25519(r[0]) === p[31] >> 7) Z(r[0], gf0, r[0]);
          M(r[3], r[0], r[1]);
          return 0;
        }
        function crypto_sign_open(m, sm, n, pk) {
          var i;
          var t = new Uint8Array(32), h = new Uint8Array(64);
          var p = [gf(), gf(), gf(), gf()], q = [gf(), gf(), gf(), gf()];
          if (n < 64) return -1;
          if (unpackneg(q, pk)) return -1;
          for (i = 0; i < n; i++) m[i] = sm[i];
          for (i = 0; i < 32; i++) m[i + 32] = pk[i];
          crypto_hash(h, m, n);
          reduce(h);
          scalarmult(p, q, h);
          scalarbase(q, sm.subarray(32));
          add(p, q);
          pack(t, p);
          n -= 64;
          if (crypto_verify_32(sm, 0, t, 0)) {
            for (i = 0; i < n; i++) m[i] = 0;
            return -1;
          }
          for (i = 0; i < n; i++) m[i] = sm[i + 64];
          return n;
        }
        var crypto_secretbox_KEYBYTES = 32, crypto_secretbox_NONCEBYTES = 24, crypto_secretbox_ZEROBYTES = 32, crypto_secretbox_BOXZEROBYTES = 16, crypto_scalarmult_BYTES = 32, crypto_scalarmult_SCALARBYTES = 32, crypto_box_PUBLICKEYBYTES = 32, crypto_box_SECRETKEYBYTES = 32, crypto_box_BEFORENMBYTES = 32, crypto_box_NONCEBYTES = crypto_secretbox_NONCEBYTES, crypto_box_ZEROBYTES = crypto_secretbox_ZEROBYTES, crypto_box_BOXZEROBYTES = crypto_secretbox_BOXZEROBYTES, crypto_sign_BYTES = 64, crypto_sign_PUBLICKEYBYTES = 32, crypto_sign_SECRETKEYBYTES = 64, crypto_sign_SEEDBYTES = 32, crypto_hash_BYTES = 64;
        nacl2.lowlevel = {
          crypto_core_hsalsa20,
          crypto_stream_xor,
          crypto_stream,
          crypto_stream_salsa20_xor,
          crypto_stream_salsa20,
          crypto_onetimeauth,
          crypto_onetimeauth_verify,
          crypto_verify_16,
          crypto_verify_32,
          crypto_secretbox,
          crypto_secretbox_open,
          crypto_scalarmult,
          crypto_scalarmult_base,
          crypto_box_beforenm,
          crypto_box_afternm,
          crypto_box,
          crypto_box_open,
          crypto_box_keypair,
          crypto_hash,
          crypto_sign,
          crypto_sign_keypair,
          crypto_sign_open,
          crypto_secretbox_KEYBYTES,
          crypto_secretbox_NONCEBYTES,
          crypto_secretbox_ZEROBYTES,
          crypto_secretbox_BOXZEROBYTES,
          crypto_scalarmult_BYTES,
          crypto_scalarmult_SCALARBYTES,
          crypto_box_PUBLICKEYBYTES,
          crypto_box_SECRETKEYBYTES,
          crypto_box_BEFORENMBYTES,
          crypto_box_NONCEBYTES,
          crypto_box_ZEROBYTES,
          crypto_box_BOXZEROBYTES,
          crypto_sign_BYTES,
          crypto_sign_PUBLICKEYBYTES,
          crypto_sign_SECRETKEYBYTES,
          crypto_sign_SEEDBYTES,
          crypto_hash_BYTES,
          gf,
          D,
          L,
          pack25519,
          unpack25519,
          M,
          A,
          S,
          Z,
          pow2523,
          add,
          set25519,
          modL,
          scalarmult,
          scalarbase
        };
        function checkLengths(k, n) {
          if (k.length !== crypto_secretbox_KEYBYTES) throw new Error("bad key size");
          if (n.length !== crypto_secretbox_NONCEBYTES) throw new Error("bad nonce size");
        }
        function checkBoxLengths(pk, sk) {
          if (pk.length !== crypto_box_PUBLICKEYBYTES) throw new Error("bad public key size");
          if (sk.length !== crypto_box_SECRETKEYBYTES) throw new Error("bad secret key size");
        }
        function checkArrayTypes() {
          for (var i = 0; i < arguments.length; i++) {
            if (!(arguments[i] instanceof Uint8Array))
              throw new TypeError("unexpected type, use Uint8Array");
          }
        }
        function cleanup(arr) {
          for (var i = 0; i < arr.length; i++) arr[i] = 0;
        }
        nacl2.randomBytes = function(n) {
          var b = new Uint8Array(n);
          randombytes(b, n);
          return b;
        };
        nacl2.secretbox = function(msg, nonce, key) {
          checkArrayTypes(msg, nonce, key);
          checkLengths(key, nonce);
          var m = new Uint8Array(crypto_secretbox_ZEROBYTES + msg.length);
          var c = new Uint8Array(m.length);
          for (var i = 0; i < msg.length; i++) m[i + crypto_secretbox_ZEROBYTES] = msg[i];
          crypto_secretbox(c, m, m.length, nonce, key);
          return c.subarray(crypto_secretbox_BOXZEROBYTES);
        };
        nacl2.secretbox.open = function(box, nonce, key) {
          checkArrayTypes(box, nonce, key);
          checkLengths(key, nonce);
          var c = new Uint8Array(crypto_secretbox_BOXZEROBYTES + box.length);
          var m = new Uint8Array(c.length);
          for (var i = 0; i < box.length; i++) c[i + crypto_secretbox_BOXZEROBYTES] = box[i];
          if (c.length < 32) return null;
          if (crypto_secretbox_open(m, c, c.length, nonce, key) !== 0) return null;
          return m.subarray(crypto_secretbox_ZEROBYTES);
        };
        nacl2.secretbox.keyLength = crypto_secretbox_KEYBYTES;
        nacl2.secretbox.nonceLength = crypto_secretbox_NONCEBYTES;
        nacl2.secretbox.overheadLength = crypto_secretbox_BOXZEROBYTES;
        nacl2.scalarMult = function(n, p) {
          checkArrayTypes(n, p);
          if (n.length !== crypto_scalarmult_SCALARBYTES) throw new Error("bad n size");
          if (p.length !== crypto_scalarmult_BYTES) throw new Error("bad p size");
          var q = new Uint8Array(crypto_scalarmult_BYTES);
          crypto_scalarmult(q, n, p);
          return q;
        };
        nacl2.scalarMult.base = function(n) {
          checkArrayTypes(n);
          if (n.length !== crypto_scalarmult_SCALARBYTES) throw new Error("bad n size");
          var q = new Uint8Array(crypto_scalarmult_BYTES);
          crypto_scalarmult_base(q, n);
          return q;
        };
        nacl2.scalarMult.scalarLength = crypto_scalarmult_SCALARBYTES;
        nacl2.scalarMult.groupElementLength = crypto_scalarmult_BYTES;
        nacl2.box = function(msg, nonce, publicKey, secretKey) {
          var k = nacl2.box.before(publicKey, secretKey);
          return nacl2.secretbox(msg, nonce, k);
        };
        nacl2.box.before = function(publicKey, secretKey) {
          checkArrayTypes(publicKey, secretKey);
          checkBoxLengths(publicKey, secretKey);
          var k = new Uint8Array(crypto_box_BEFORENMBYTES);
          crypto_box_beforenm(k, publicKey, secretKey);
          return k;
        };
        nacl2.box.after = nacl2.secretbox;
        nacl2.box.open = function(msg, nonce, publicKey, secretKey) {
          var k = nacl2.box.before(publicKey, secretKey);
          return nacl2.secretbox.open(msg, nonce, k);
        };
        nacl2.box.open.after = nacl2.secretbox.open;
        nacl2.box.keyPair = function() {
          var pk = new Uint8Array(crypto_box_PUBLICKEYBYTES);
          var sk = new Uint8Array(crypto_box_SECRETKEYBYTES);
          crypto_box_keypair(pk, sk);
          return { publicKey: pk, secretKey: sk };
        };
        nacl2.box.keyPair.fromSecretKey = function(secretKey) {
          checkArrayTypes(secretKey);
          if (secretKey.length !== crypto_box_SECRETKEYBYTES)
            throw new Error("bad secret key size");
          var pk = new Uint8Array(crypto_box_PUBLICKEYBYTES);
          crypto_scalarmult_base(pk, secretKey);
          return { publicKey: pk, secretKey: new Uint8Array(secretKey) };
        };
        nacl2.box.publicKeyLength = crypto_box_PUBLICKEYBYTES;
        nacl2.box.secretKeyLength = crypto_box_SECRETKEYBYTES;
        nacl2.box.sharedKeyLength = crypto_box_BEFORENMBYTES;
        nacl2.box.nonceLength = crypto_box_NONCEBYTES;
        nacl2.box.overheadLength = nacl2.secretbox.overheadLength;
        nacl2.sign = function(msg, secretKey) {
          checkArrayTypes(msg, secretKey);
          if (secretKey.length !== crypto_sign_SECRETKEYBYTES)
            throw new Error("bad secret key size");
          var signedMsg = new Uint8Array(crypto_sign_BYTES + msg.length);
          crypto_sign(signedMsg, msg, msg.length, secretKey);
          return signedMsg;
        };
        nacl2.sign.open = function(signedMsg, publicKey) {
          checkArrayTypes(signedMsg, publicKey);
          if (publicKey.length !== crypto_sign_PUBLICKEYBYTES)
            throw new Error("bad public key size");
          var tmp = new Uint8Array(signedMsg.length);
          var mlen = crypto_sign_open(tmp, signedMsg, signedMsg.length, publicKey);
          if (mlen < 0) return null;
          var m = new Uint8Array(mlen);
          for (var i = 0; i < m.length; i++) m[i] = tmp[i];
          return m;
        };
        nacl2.sign.detached = function(msg, secretKey) {
          var signedMsg = nacl2.sign(msg, secretKey);
          var sig = new Uint8Array(crypto_sign_BYTES);
          for (var i = 0; i < sig.length; i++) sig[i] = signedMsg[i];
          return sig;
        };
        nacl2.sign.detached.verify = function(msg, sig, publicKey) {
          checkArrayTypes(msg, sig, publicKey);
          if (sig.length !== crypto_sign_BYTES)
            throw new Error("bad signature size");
          if (publicKey.length !== crypto_sign_PUBLICKEYBYTES)
            throw new Error("bad public key size");
          var sm = new Uint8Array(crypto_sign_BYTES + msg.length);
          var m = new Uint8Array(crypto_sign_BYTES + msg.length);
          var i;
          for (i = 0; i < crypto_sign_BYTES; i++) sm[i] = sig[i];
          for (i = 0; i < msg.length; i++) sm[i + crypto_sign_BYTES] = msg[i];
          return crypto_sign_open(m, sm, sm.length, publicKey) >= 0;
        };
        nacl2.sign.keyPair = function() {
          var pk = new Uint8Array(crypto_sign_PUBLICKEYBYTES);
          var sk = new Uint8Array(crypto_sign_SECRETKEYBYTES);
          crypto_sign_keypair(pk, sk);
          return { publicKey: pk, secretKey: sk };
        };
        nacl2.sign.keyPair.fromSecretKey = function(secretKey) {
          checkArrayTypes(secretKey);
          if (secretKey.length !== crypto_sign_SECRETKEYBYTES)
            throw new Error("bad secret key size");
          var pk = new Uint8Array(crypto_sign_PUBLICKEYBYTES);
          for (var i = 0; i < pk.length; i++) pk[i] = secretKey[32 + i];
          return { publicKey: pk, secretKey: new Uint8Array(secretKey) };
        };
        nacl2.sign.keyPair.fromSeed = function(seed) {
          checkArrayTypes(seed);
          if (seed.length !== crypto_sign_SEEDBYTES)
            throw new Error("bad seed size");
          var pk = new Uint8Array(crypto_sign_PUBLICKEYBYTES);
          var sk = new Uint8Array(crypto_sign_SECRETKEYBYTES);
          for (var i = 0; i < 32; i++) sk[i] = seed[i];
          crypto_sign_keypair(pk, sk, true);
          return { publicKey: pk, secretKey: sk };
        };
        nacl2.sign.publicKeyLength = crypto_sign_PUBLICKEYBYTES;
        nacl2.sign.secretKeyLength = crypto_sign_SECRETKEYBYTES;
        nacl2.sign.seedLength = crypto_sign_SEEDBYTES;
        nacl2.sign.signatureLength = crypto_sign_BYTES;
        nacl2.hash = function(msg) {
          checkArrayTypes(msg);
          var h = new Uint8Array(crypto_hash_BYTES);
          crypto_hash(h, msg, msg.length);
          return h;
        };
        nacl2.hash.hashLength = crypto_hash_BYTES;
        nacl2.verify = function(x, y) {
          checkArrayTypes(x, y);
          if (x.length === 0 || y.length === 0) return false;
          if (x.length !== y.length) return false;
          return vn(x, 0, y, 0, x.length) === 0 ? true : false;
        };
        nacl2.setPRNG = function(fn) {
          randombytes = fn;
        };
        (function() {
          var crypto2 = typeof self !== "undefined" ? self.crypto || self.msCrypto : null;
          if (crypto2 && crypto2.getRandomValues) {
            var QUOTA = 65536;
            nacl2.setPRNG(function(x, n) {
              var i, v = new Uint8Array(n);
              for (i = 0; i < n; i += QUOTA) {
                crypto2.getRandomValues(v.subarray(i, i + Math.min(n - i, QUOTA)));
              }
              for (i = 0; i < n; i++) x[i] = v[i];
              cleanup(v);
            });
          } else if (typeof __require !== "undefined") {
            crypto2 = require_crypto();
            if (crypto2 && crypto2.randomBytes) {
              nacl2.setPRNG(function(x, n) {
                var i, v = crypto2.randomBytes(n);
                for (i = 0; i < n; i++) x[i] = v[i];
                cleanup(v);
              });
            }
          }
        })();
      })(typeof module !== "undefined" && module.exports ? module.exports : self.nacl = self.nacl || {});
    }
  });

  // node_modules/@tonconnect/sdk/lib/esm/index.mjs
  var esm_exports = {};
  __export(esm_exports, {
    BadRequestError: () => BadRequestError,
    Base64: () => Base64,
    BrowserEventDispatcher: () => BrowserEventDispatcher,
    CHAIN: () => CHAIN,
    CONNECT_EVENT_ERROR_CODES: () => CONNECT_EVENT_ERROR_CODES,
    CONNECT_ITEM_ERROR_CODES: () => CONNECT_ITEM_ERROR_CODES,
    Consumable: () => Consumable,
    DISCONNECT_ERROR_CODES: () => DISCONNECT_ERROR_CODES,
    FetchWalletsError: () => FetchWalletsError,
    LocalstorageNotFoundError: () => LocalstorageNotFoundError,
    ParseHexError: () => ParseHexError,
    SEND_TRANSACTION_ERROR_CODES: () => SEND_TRANSACTION_ERROR_CODES,
    SIGN_DATA_ERROR_CODES: () => SIGN_DATA_ERROR_CODES,
    SIGN_MESSAGE_ERROR_CODES: () => SIGN_MESSAGE_ERROR_CODES,
    SessionCrypto: () => SessionCrypto,
    TonConnect: () => TonConnect,
    TonConnectError: () => TonConnectError,
    UUIDv7: () => UUIDv7,
    UnknownAppError: () => UnknownAppError,
    UnknownError: () => UnknownError,
    UserRejectsError: () => UserRejectsError,
    WalletAlreadyConnectedError: () => WalletAlreadyConnectedError,
    WalletMissingRequiredFeaturesError: () => WalletMissingRequiredFeaturesError,
    WalletNotConnectedError: () => WalletNotConnectedError,
    WalletNotInjectedError: () => WalletNotInjectedError,
    WalletNotSupportFeatureError: () => WalletNotSupportFeatureError,
    WalletWrongNetworkError: () => WalletWrongNetworkError,
    WalletsListManager: () => WalletsListManager,
    WrongAddressError: () => WrongAddressError,
    checkRequiredWalletFeatures: () => checkRequiredWalletFeatures,
    concatUint8Arrays: () => concatUint8Arrays,
    createConnectionCompletedEvent: () => createConnectionCompletedEvent,
    createConnectionErrorEvent: () => createConnectionErrorEvent,
    createConnectionRestoringCompletedEvent: () => createConnectionRestoringCompletedEvent,
    createConnectionRestoringErrorEvent: () => createConnectionRestoringErrorEvent,
    createConnectionRestoringStartedEvent: () => createConnectionRestoringStartedEvent,
    createConnectionStartedEvent: () => createConnectionStartedEvent,
    createDataSentForSignatureEvent: () => createDataSentForSignatureEvent,
    createDataSignedEvent: () => createDataSignedEvent,
    createDataSigningFailedEvent: () => createDataSigningFailedEvent,
    createDisconnectionEvent: () => createDisconnectionEvent,
    createRequestVersionEvent: () => createRequestVersionEvent,
    createResponseVersionEvent: () => createResponseVersionEvent,
    createSelectedWalletEvent: () => createSelectedWalletEvent,
    createTransactionSentForSignatureEvent: () => createTransactionSentForSignatureEvent,
    createTransactionSignedEvent: () => createTransactionSignedEvent,
    createTransactionSigningFailedEvent: () => createTransactionSigningFailedEvent,
    createVersionInfo: () => createVersionInfo,
    createWalletModalOpenedEvent: () => createWalletModalOpenedEvent,
    decodeEmbeddedRequestParam: () => decodeEmbeddedRequestParam,
    decodeTelegramUrlParameters: () => decodeTelegramUrlParameters,
    decodeWireEmbeddedRequest: () => decodeWireEmbeddedRequest,
    default: () => TonConnect,
    enableQaMode: () => enableQaMode,
    encodeTelegramUrlParameters: () => encodeTelegramUrlParameters,
    hasItems: () => hasItems,
    hasMessages: () => hasMessages,
    hexToByteArray: () => hexToByteArray,
    initializeWalletConnect: () => initializeWalletConnect,
    isConnectUrl: () => isConnectUrl,
    isNode: () => isNode,
    isQaModeEnabled: () => isQaModeEnabled,
    isTelegramUrl: () => isTelegramUrl,
    isWalletConnectInitialized: () => isWalletConnectInitialized,
    isWalletInfoCurrentlyEmbedded: () => isWalletInfoCurrentlyEmbedded,
    isWalletInfoCurrentlyInjected: () => isWalletInfoCurrentlyInjected,
    isWalletInfoInjectable: () => isWalletInfoInjectable,
    isWalletInfoInjected: () => isWalletInfoInjected,
    isWalletInfoRemote: () => isWalletInfoRemote,
    splitToUint8Arrays: () => splitToUint8Arrays,
    toHexString: () => toHexString,
    toUserFriendlyAddress: () => toUserFriendlyAddress
  });

  // node_modules/@tonconnect/protocol/lib/esm/index.mjs
  var import_tweetnacl_util = __toESM(require_nacl_util(), 1);
  var import_tweetnacl = __toESM(require_nacl_fast(), 1);
  var CONNECT_EVENT_ERROR_CODES;
  (function(CONNECT_EVENT_ERROR_CODES2) {
    CONNECT_EVENT_ERROR_CODES2[CONNECT_EVENT_ERROR_CODES2["UNKNOWN_ERROR"] = 0] = "UNKNOWN_ERROR";
    CONNECT_EVENT_ERROR_CODES2[CONNECT_EVENT_ERROR_CODES2["BAD_REQUEST_ERROR"] = 1] = "BAD_REQUEST_ERROR";
    CONNECT_EVENT_ERROR_CODES2[CONNECT_EVENT_ERROR_CODES2["MANIFEST_NOT_FOUND_ERROR"] = 2] = "MANIFEST_NOT_FOUND_ERROR";
    CONNECT_EVENT_ERROR_CODES2[CONNECT_EVENT_ERROR_CODES2["MANIFEST_CONTENT_ERROR"] = 3] = "MANIFEST_CONTENT_ERROR";
    CONNECT_EVENT_ERROR_CODES2[CONNECT_EVENT_ERROR_CODES2["UNKNOWN_APP_ERROR"] = 100] = "UNKNOWN_APP_ERROR";
    CONNECT_EVENT_ERROR_CODES2[CONNECT_EVENT_ERROR_CODES2["USER_REJECTS_ERROR"] = 300] = "USER_REJECTS_ERROR";
    CONNECT_EVENT_ERROR_CODES2[CONNECT_EVENT_ERROR_CODES2["METHOD_NOT_SUPPORTED"] = 400] = "METHOD_NOT_SUPPORTED";
  })(CONNECT_EVENT_ERROR_CODES || (CONNECT_EVENT_ERROR_CODES = {}));
  var CONNECT_ITEM_ERROR_CODES;
  (function(CONNECT_ITEM_ERROR_CODES2) {
    CONNECT_ITEM_ERROR_CODES2[CONNECT_ITEM_ERROR_CODES2["UNKNOWN_ERROR"] = 0] = "UNKNOWN_ERROR";
    CONNECT_ITEM_ERROR_CODES2[CONNECT_ITEM_ERROR_CODES2["METHOD_NOT_SUPPORTED"] = 400] = "METHOD_NOT_SUPPORTED";
  })(CONNECT_ITEM_ERROR_CODES || (CONNECT_ITEM_ERROR_CODES = {}));
  var SEND_TRANSACTION_ERROR_CODES;
  (function(SEND_TRANSACTION_ERROR_CODES2) {
    SEND_TRANSACTION_ERROR_CODES2[SEND_TRANSACTION_ERROR_CODES2["UNKNOWN_ERROR"] = 0] = "UNKNOWN_ERROR";
    SEND_TRANSACTION_ERROR_CODES2[SEND_TRANSACTION_ERROR_CODES2["BAD_REQUEST_ERROR"] = 1] = "BAD_REQUEST_ERROR";
    SEND_TRANSACTION_ERROR_CODES2[SEND_TRANSACTION_ERROR_CODES2["UNKNOWN_APP_ERROR"] = 100] = "UNKNOWN_APP_ERROR";
    SEND_TRANSACTION_ERROR_CODES2[SEND_TRANSACTION_ERROR_CODES2["USER_REJECTS_ERROR"] = 300] = "USER_REJECTS_ERROR";
    SEND_TRANSACTION_ERROR_CODES2[SEND_TRANSACTION_ERROR_CODES2["METHOD_NOT_SUPPORTED"] = 400] = "METHOD_NOT_SUPPORTED";
  })(SEND_TRANSACTION_ERROR_CODES || (SEND_TRANSACTION_ERROR_CODES = {}));
  var SIGN_DATA_ERROR_CODES;
  (function(SIGN_DATA_ERROR_CODES2) {
    SIGN_DATA_ERROR_CODES2[SIGN_DATA_ERROR_CODES2["UNKNOWN_ERROR"] = 0] = "UNKNOWN_ERROR";
    SIGN_DATA_ERROR_CODES2[SIGN_DATA_ERROR_CODES2["BAD_REQUEST_ERROR"] = 1] = "BAD_REQUEST_ERROR";
    SIGN_DATA_ERROR_CODES2[SIGN_DATA_ERROR_CODES2["UNKNOWN_APP_ERROR"] = 100] = "UNKNOWN_APP_ERROR";
    SIGN_DATA_ERROR_CODES2[SIGN_DATA_ERROR_CODES2["USER_REJECTS_ERROR"] = 300] = "USER_REJECTS_ERROR";
    SIGN_DATA_ERROR_CODES2[SIGN_DATA_ERROR_CODES2["METHOD_NOT_SUPPORTED"] = 400] = "METHOD_NOT_SUPPORTED";
  })(SIGN_DATA_ERROR_CODES || (SIGN_DATA_ERROR_CODES = {}));
  var DISCONNECT_ERROR_CODES;
  (function(DISCONNECT_ERROR_CODES2) {
    DISCONNECT_ERROR_CODES2[DISCONNECT_ERROR_CODES2["UNKNOWN_ERROR"] = 0] = "UNKNOWN_ERROR";
    DISCONNECT_ERROR_CODES2[DISCONNECT_ERROR_CODES2["BAD_REQUEST_ERROR"] = 1] = "BAD_REQUEST_ERROR";
    DISCONNECT_ERROR_CODES2[DISCONNECT_ERROR_CODES2["UNKNOWN_APP_ERROR"] = 100] = "UNKNOWN_APP_ERROR";
    DISCONNECT_ERROR_CODES2[DISCONNECT_ERROR_CODES2["METHOD_NOT_SUPPORTED"] = 400] = "METHOD_NOT_SUPPORTED";
  })(DISCONNECT_ERROR_CODES || (DISCONNECT_ERROR_CODES = {}));
  var SIGN_MESSAGE_ERROR_CODES;
  (function(SIGN_MESSAGE_ERROR_CODES2) {
    SIGN_MESSAGE_ERROR_CODES2[SIGN_MESSAGE_ERROR_CODES2["UNKNOWN_ERROR"] = 0] = "UNKNOWN_ERROR";
    SIGN_MESSAGE_ERROR_CODES2[SIGN_MESSAGE_ERROR_CODES2["BAD_REQUEST_ERROR"] = 1] = "BAD_REQUEST_ERROR";
    SIGN_MESSAGE_ERROR_CODES2[SIGN_MESSAGE_ERROR_CODES2["UNKNOWN_APP_ERROR"] = 100] = "UNKNOWN_APP_ERROR";
    SIGN_MESSAGE_ERROR_CODES2[SIGN_MESSAGE_ERROR_CODES2["USER_REJECTS_ERROR"] = 300] = "USER_REJECTS_ERROR";
    SIGN_MESSAGE_ERROR_CODES2[SIGN_MESSAGE_ERROR_CODES2["METHOD_NOT_SUPPORTED"] = 400] = "METHOD_NOT_SUPPORTED";
  })(SIGN_MESSAGE_ERROR_CODES || (SIGN_MESSAGE_ERROR_CODES = {}));
  var CHAIN;
  (function(CHAIN2) {
    CHAIN2["MAINNET"] = "-239";
    CHAIN2["TESTNET"] = "-3";
  })(CHAIN || (CHAIN = {}));
  function encodeUint8Array(value, urlSafe) {
    const encoded = import_tweetnacl_util.default.encodeBase64(value);
    if (!urlSafe) {
      return encoded;
    }
    return encodeURIComponent(encoded);
  }
  function decodeToUint8Array(value, urlSafe) {
    if (urlSafe) {
      value = decodeURIComponent(value);
    }
    return import_tweetnacl_util.default.decodeBase64(value);
  }
  function encode(value, urlSafe = false) {
    let uint8Array;
    if (value instanceof Uint8Array) {
      uint8Array = value;
    } else {
      if (typeof value !== "string") {
        value = JSON.stringify(value);
      }
      uint8Array = import_tweetnacl_util.default.decodeUTF8(value);
    }
    return encodeUint8Array(uint8Array, urlSafe);
  }
  function decode(value, urlSafe = false) {
    const decodedUint8Array = decodeToUint8Array(value, urlSafe);
    return {
      toString() {
        return import_tweetnacl_util.default.encodeUTF8(decodedUint8Array);
      },
      toObject() {
        try {
          return JSON.parse(import_tweetnacl_util.default.encodeUTF8(decodedUint8Array));
        } catch (e) {
          return null;
        }
      },
      toUint8Array() {
        return decodedUint8Array;
      }
    };
  }
  var Base64 = {
    encode,
    decode
  };
  function fromBase64Url(base64url) {
    const padded = base64url.length + (4 - base64url.length % 4) % 4;
    const base64 = base64url.replace(/-/g, "+").replace(/_/g, "/").padEnd(padded, "=");
    return Base64.decode(base64).toString();
  }
  function expandMessage(w) {
    const msg = { address: w.a, amount: w.am };
    if (w.p !== void 0) {
      msg.payload = w.p;
    }
    if (w.si !== void 0) {
      msg.stateInit = w.si;
    }
    if (w.ec !== void 0) {
      msg.extra_currency = w.ec;
    }
    return msg;
  }
  function expandItem(w) {
    switch (w.t) {
      case "ton": {
        const item = { type: "ton", address: w.a, amount: w.am };
        if (w.p !== void 0) {
          item.payload = w.p;
        }
        if (w.si !== void 0) {
          item.stateInit = w.si;
        }
        if (w.ec !== void 0) {
          item.extra_currency = w.ec;
        }
        return item;
      }
      case "jetton": {
        const item = {
          type: "jetton",
          master: w.ma,
          destination: w.d,
          amount: w.am
        };
        if (w.aa !== void 0) {
          item.attachAmount = w.aa;
        }
        if (w.rd !== void 0) {
          item.responseDestination = w.rd;
        }
        if (w.cp !== void 0) {
          item.customPayload = w.cp;
        }
        if (w.fa !== void 0) {
          item.forwardAmount = w.fa;
        }
        if (w.fp !== void 0) {
          item.forwardPayload = w.fp;
        }
        if (w.qi !== void 0) {
          item.queryId = w.qi;
        }
        return item;
      }
      case "nft": {
        const item = {
          type: "nft",
          nftAddress: w.na,
          newOwner: w.no
        };
        if (w.aa !== void 0) {
          item.attachAmount = w.aa;
        }
        if (w.rd !== void 0) {
          item.responseDestination = w.rd;
        }
        if (w.cp !== void 0) {
          item.customPayload = w.cp;
        }
        if (w.fa !== void 0) {
          item.forwardAmount = w.fa;
        }
        if (w.fp !== void 0) {
          item.forwardPayload = w.fp;
        }
        if (w.qi !== void 0) {
          item.queryId = w.qi;
        }
        return item;
      }
    }
  }
  function expandTransactionBody(wire) {
    const payload = {};
    if (wire.vu !== void 0) {
      payload.valid_until = wire.vu;
    }
    if (wire.n !== void 0) {
      payload.network = wire.n;
    }
    if (wire.f !== void 0) {
      payload.from = wire.f;
    }
    if (wire.ms) {
      payload.messages = wire.ms.map(expandMessage);
    }
    if (wire.i) {
      payload.items = wire.i.map(expandItem);
    }
    return payload;
  }
  function expandSignDataBody(wire) {
    const payload = {};
    if (wire.n !== void 0) {
      payload.network = wire.n;
    }
    if (wire.f !== void 0) {
      payload.from = wire.f;
    }
    switch (wire.t) {
      case "text":
        payload.type = "text";
        payload.text = wire.tx;
        break;
      case "binary":
        payload.type = "binary";
        payload.bytes = wire.b;
        break;
      case "cell":
        payload.type = "cell";
        payload.schema = wire.s;
        payload.cell = wire.c;
        break;
    }
    return payload;
  }
  function decodeWireEmbeddedRequest(wire) {
    switch (wire.m) {
      case "st":
        return {
          method: "sendTransaction",
          params: [JSON.stringify(expandTransactionBody(wire))]
        };
      case "sm":
        return {
          method: "signMessage",
          params: [JSON.stringify(expandTransactionBody(wire))]
        };
      case "sd":
        return {
          method: "signData",
          params: [JSON.stringify(expandSignDataBody(wire))]
        };
    }
  }
  function decodeEmbeddedRequestParam(reqParam) {
    const json = fromBase64Url(reqParam);
    const wire = JSON.parse(json);
    return decodeWireEmbeddedRequest(wire);
  }
  function concatUint8Arrays(buffer1, buffer2) {
    const mergedArray = new Uint8Array(buffer1.length + buffer2.length);
    mergedArray.set(buffer1);
    mergedArray.set(buffer2, buffer1.length);
    return mergedArray;
  }
  function splitToUint8Arrays(array, index) {
    if (index >= array.length) {
      throw new Error("Index is out of buffer");
    }
    const subArray1 = array.slice(0, index);
    const subArray2 = array.slice(index);
    return [subArray1, subArray2];
  }
  function toHexString(byteArray) {
    let hexString = "";
    byteArray.forEach((byte) => {
      hexString += ("0" + (byte & 255).toString(16)).slice(-2);
    });
    return hexString;
  }
  function hexToByteArray(hexString) {
    if (hexString.length % 2 !== 0) {
      throw new Error(`Cannot convert ${hexString} to bytesArray`);
    }
    const result = new Uint8Array(hexString.length / 2);
    for (let i = 0; i < hexString.length; i += 2) {
      result[i / 2] = parseInt(hexString.slice(i, i + 2), 16);
    }
    return result;
  }
  function isNode() {
    return typeof process !== "undefined" && process.versions != null && process.versions.node != null;
  }
  var SessionCrypto = class {
    /**
     * Reuse an existing {@link KeyPair} (resuming a session) or generate a
     * fresh one (`crypto_box.keyPair()`) when omitted.
     */
    constructor(keyPair) {
      this.nonceLength = 24;
      this.keyPair = keyPair ? this.createKeypairFromString(keyPair) : this.createKeypair();
      this.sessionId = toHexString(this.keyPair.publicKey);
    }
    createKeypair() {
      return import_tweetnacl.default.box.keyPair();
    }
    createKeypairFromString(keyPair) {
      return {
        publicKey: hexToByteArray(keyPair.publicKey),
        secretKey: hexToByteArray(keyPair.secretKey)
      };
    }
    createNonce() {
      return import_tweetnacl.default.randomBytes(this.nonceLength);
    }
    /**
     * Encrypt `message` for `receiverPublicKey` using a fresh 24-byte random
     * nonce. Returns `nonce || ciphertext` as raw bytes; base64-encode this
     * value before placing it in the bridge `POST /message` body.
     */
    encrypt(message, receiverPublicKey) {
      const encodedMessage = new TextEncoder().encode(message);
      const nonce = this.createNonce();
      const encrypted = import_tweetnacl.default.box(encodedMessage, nonce, receiverPublicKey, this.keyPair.secretKey);
      return concatUint8Arrays(nonce, encrypted);
    }
    /**
     * Decrypt the `nonce || ciphertext` blob received from the bridge.
     * Throws if `nacl.box.open` rejects the message — wrong key, truncated
     * input or tampered ciphertext.
     */
    decrypt(message, senderPublicKey) {
      const [nonce, internalMessage] = splitToUint8Arrays(message, this.nonceLength);
      const decrypted = import_tweetnacl.default.box.open(internalMessage, nonce, senderPublicKey, this.keyPair.secretKey);
      if (!decrypted) {
        throw new Error(`Decryption error: 
 message: ${message.toString()} 
 sender pubkey: ${senderPublicKey.toString()} 
 keypair pubkey: ${this.keyPair.publicKey.toString()} 
 keypair secretkey: ${this.keyPair.secretKey.toString()}`);
      }
      return new TextDecoder().decode(decrypted);
    }
    /**
     * Export the underlying keypair as a {@link KeyPair} of hex strings.
     * Persist this in dApp / wallet storage to resume the session later.
     */
    stringifyKeypair() {
      return {
        publicKey: toHexString(this.keyPair.publicKey),
        secretKey: toHexString(this.keyPair.secretKey)
      };
    }
  };

  // node_modules/@tonconnect/isomorphic-eventsource/browser.js
  {
  }

  // node_modules/@tonconnect/isomorphic-fetch/browser.js
  {
  }

  // node_modules/@tonconnect/sdk/lib/esm/index.mjs
  function __rest(s, e) {
    var t = {};
    for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p) && e.indexOf(p) < 0)
      t[p] = s[p];
    if (s != null && typeof Object.getOwnPropertySymbols === "function")
      for (var i = 0, p = Object.getOwnPropertySymbols(s); i < p.length; i++) {
        if (e.indexOf(p[i]) < 0 && Object.prototype.propertyIsEnumerable.call(s, p[i]))
          t[p[i]] = s[p[i]];
      }
    return t;
  }
  function __awaiter(thisArg, _arguments, P, generator) {
    function adopt(value) {
      return value instanceof P ? value : new P(function(resolve) {
        resolve(value);
      });
    }
    return new (P || (P = Promise))(function(resolve, reject) {
      function fulfilled(value) {
        try {
          step(generator.next(value));
        } catch (e) {
          reject(e);
        }
      }
      function rejected(value) {
        try {
          step(generator["throw"](value));
        } catch (e) {
          reject(e);
        }
      }
      function step(result) {
        result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected);
      }
      step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
  }
  var TonConnectError = class _TonConnectError extends Error {
    get info() {
      return "";
    }
    constructor(message, options) {
      super(message, options);
      this.message = `${_TonConnectError.prefix} ${this.constructor.name}${this.info ? ": " + this.info : ""}${message ? "\n" + message : ""}`;
      Object.setPrototypeOf(this, _TonConnectError.prototype);
    }
  };
  TonConnectError.prefix = "[TON_CONNECT_SDK_ERROR]";
  var DappMetadataError = class _DappMetadataError extends TonConnectError {
    get info() {
      return "Passed DappMetadata is in incorrect format.";
    }
    constructor(...args) {
      super(...args);
      Object.setPrototypeOf(this, _DappMetadataError.prototype);
    }
  };
  var ManifestContentErrorError = class _ManifestContentErrorError extends TonConnectError {
    get info() {
      return "Passed `tonconnect-manifest.json` contains errors. Check format of your manifest. See more https://github.com/ton-connect/docs/blob/main/requests-responses.md#app-manifest";
    }
    constructor(...args) {
      super(...args);
      Object.setPrototypeOf(this, _ManifestContentErrorError.prototype);
    }
  };
  var ManifestNotFoundError = class _ManifestNotFoundError extends TonConnectError {
    get info() {
      return "Manifest not found. Make sure you added `tonconnect-manifest.json` to the root of your app or passed correct manifestUrl. See more https://github.com/ton-connect/docs/blob/main/requests-responses.md#app-manifest";
    }
    constructor(...args) {
      super(...args);
      Object.setPrototypeOf(this, _ManifestNotFoundError.prototype);
    }
  };
  var WalletAlreadyConnectedError = class _WalletAlreadyConnectedError extends TonConnectError {
    get info() {
      return "Wallet connection called but wallet already connected. To avoid the error, disconnect the wallet before doing a new connection.";
    }
    constructor(...args) {
      super(...args);
      Object.setPrototypeOf(this, _WalletAlreadyConnectedError.prototype);
    }
  };
  var WalletNotConnectedError = class _WalletNotConnectedError extends TonConnectError {
    get info() {
      return "Send transaction or other protocol methods called while wallet is not connected.";
    }
    constructor(...args) {
      super(...args);
      Object.setPrototypeOf(this, _WalletNotConnectedError.prototype);
    }
  };
  var WalletNotInjectedError = class _WalletNotInjectedError extends TonConnectError {
    get info() {
      return "There is an attempt to connect to the injected wallet while it is not exists in the webpage.";
    }
    constructor(...args) {
      super(...args);
      Object.setPrototypeOf(this, _WalletNotInjectedError.prototype);
    }
  };
  var WalletNotSupportFeatureError = class _WalletNotSupportFeatureError extends TonConnectError {
    get info() {
      return "Wallet doesn't support requested feature method.";
    }
    constructor(message, options) {
      super(message, options);
      Object.setPrototypeOf(this, _WalletNotSupportFeatureError.prototype);
    }
  };
  var WalletMissingRequiredFeaturesError = class _WalletMissingRequiredFeaturesError extends TonConnectError {
    get info() {
      return "Missing required features. You need to update your wallet.";
    }
    constructor(message, options) {
      super(message, options);
      Object.setPrototypeOf(this, _WalletMissingRequiredFeaturesError.prototype);
    }
  };
  var WalletWrongNetworkError = class _WalletWrongNetworkError extends TonConnectError {
    constructor(message, options) {
      super(message, options);
      this.name = "WalletWrongNetworkError";
      Object.setPrototypeOf(this, _WalletWrongNetworkError.prototype);
    }
  };
  function hasItems(req) {
    return "items" in req && Array.isArray(req.items);
  }
  function hasMessages(req) {
    return "messages" in req && Array.isArray(req.messages);
  }
  function isWalletConnectionSourceJS(value) {
    return "jsBridgeKey" in value;
  }
  function isWalletConnectionSourceWalletConnect(value) {
    return "type" in value && value.type === "wallet-connect";
  }
  var UserRejectsError = class _UserRejectsError extends TonConnectError {
    get info() {
      return "User rejects the action in the wallet.";
    }
    constructor(...args) {
      super(...args);
      Object.setPrototypeOf(this, _UserRejectsError.prototype);
    }
  };
  var BadRequestError = class _BadRequestError extends TonConnectError {
    get info() {
      return "Request to the wallet contains errors.";
    }
    constructor(...args) {
      super(...args);
      Object.setPrototypeOf(this, _BadRequestError.prototype);
    }
  };
  var UnknownAppError = class _UnknownAppError extends TonConnectError {
    get info() {
      return "App tries to send rpc request to the injected wallet while not connected.";
    }
    constructor(...args) {
      super(...args);
      Object.setPrototypeOf(this, _UnknownAppError.prototype);
    }
  };
  var LocalstorageNotFoundError = class _LocalstorageNotFoundError extends TonConnectError {
    get info() {
      return "Storage was not specified in the `DappMetadata` and default `localStorage` was not detected in the environment.";
    }
    constructor(...args) {
      super(...args);
      Object.setPrototypeOf(this, _LocalstorageNotFoundError.prototype);
    }
  };
  var FetchWalletsError = class _FetchWalletsError extends TonConnectError {
    get info() {
      return "An error occurred while fetching the wallets list.";
    }
    constructor(...args) {
      super(...args);
      Object.setPrototypeOf(this, _FetchWalletsError.prototype);
    }
  };
  var WrongAddressError = class _WrongAddressError extends TonConnectError {
    get info() {
      return "Passed address is in incorrect format.";
    }
    constructor(...args) {
      super(...args);
      Object.setPrototypeOf(this, _WrongAddressError.prototype);
    }
  };
  var ParseHexError = class _ParseHexError extends TonConnectError {
    get info() {
      return "Passed hex is in incorrect format.";
    }
    constructor(...args) {
      super(...args);
      Object.setPrototypeOf(this, _ParseHexError.prototype);
    }
  };
  var UnknownError = class _UnknownError extends TonConnectError {
    constructor(...args) {
      super(...args);
      Object.setPrototypeOf(this, _UnknownError.prototype);
    }
  };
  var connectEventErrorsCodes = {
    [CONNECT_EVENT_ERROR_CODES.UNKNOWN_ERROR]: UnknownError,
    [CONNECT_EVENT_ERROR_CODES.USER_REJECTS_ERROR]: UserRejectsError,
    [CONNECT_EVENT_ERROR_CODES.BAD_REQUEST_ERROR]: BadRequestError,
    [CONNECT_EVENT_ERROR_CODES.UNKNOWN_APP_ERROR]: UnknownAppError,
    [CONNECT_EVENT_ERROR_CODES.MANIFEST_NOT_FOUND_ERROR]: ManifestNotFoundError,
    [CONNECT_EVENT_ERROR_CODES.MANIFEST_CONTENT_ERROR]: ManifestContentErrorError
  };
  var ConnectErrorsParser = class {
    parseError(error) {
      let ErrorConstructor = UnknownError;
      if (error.code in connectEventErrorsCodes) {
        ErrorConstructor = connectEventErrorsCodes[error.code] || UnknownError;
      }
      return new ErrorConstructor(error.message);
    }
  };
  var connectErrorsParser = new ConnectErrorsParser();
  var RpcParser = class {
    isError(response) {
      return "error" in response;
    }
  };
  var sendTransactionErrors = {
    [SEND_TRANSACTION_ERROR_CODES.UNKNOWN_ERROR]: UnknownError,
    [SEND_TRANSACTION_ERROR_CODES.USER_REJECTS_ERROR]: UserRejectsError,
    [SEND_TRANSACTION_ERROR_CODES.BAD_REQUEST_ERROR]: BadRequestError,
    [SEND_TRANSACTION_ERROR_CODES.UNKNOWN_APP_ERROR]: UnknownAppError
  };
  var SendTransactionParser = class extends RpcParser {
    convertToRpcRequest(request) {
      return {
        method: "sendTransaction",
        params: [JSON.stringify(request)]
      };
    }
    parseAndThrowError(response) {
      let ErrorConstructor = UnknownError;
      if (response.error.code in sendTransactionErrors) {
        ErrorConstructor = sendTransactionErrors[response.error.code] || UnknownError;
      }
      throw new ErrorConstructor(response.error.message);
    }
    convertFromRpcResponse(rpcResponse) {
      return {
        boc: rpcResponse.result
      };
    }
  };
  var sendTransactionParser = new SendTransactionParser();
  var signDataErrors = {
    [SIGN_DATA_ERROR_CODES.UNKNOWN_ERROR]: UnknownError,
    [SIGN_DATA_ERROR_CODES.USER_REJECTS_ERROR]: UserRejectsError,
    [SIGN_DATA_ERROR_CODES.BAD_REQUEST_ERROR]: BadRequestError,
    [SIGN_DATA_ERROR_CODES.UNKNOWN_APP_ERROR]: UnknownAppError
  };
  var SignDataParser = class extends RpcParser {
    convertToRpcRequest(payload) {
      return {
        method: "signData",
        params: [JSON.stringify(payload)]
      };
    }
    parseAndThrowError(response) {
      let ErrorConstructor = UnknownError;
      if (response.error.code in signDataErrors) {
        ErrorConstructor = signDataErrors[response.error.code] || UnknownError;
      }
      throw new ErrorConstructor(response.error.message);
    }
    convertFromRpcResponse(rpcResponse) {
      return rpcResponse.result;
    }
  };
  var signDataParser = new SignDataParser();
  var signMessageErrors = {
    [SIGN_MESSAGE_ERROR_CODES.UNKNOWN_ERROR]: UnknownError,
    [SIGN_MESSAGE_ERROR_CODES.USER_REJECTS_ERROR]: UserRejectsError,
    [SIGN_MESSAGE_ERROR_CODES.BAD_REQUEST_ERROR]: BadRequestError,
    [SIGN_MESSAGE_ERROR_CODES.UNKNOWN_APP_ERROR]: UnknownAppError
  };
  var SignMessageParser = class extends RpcParser {
    convertToRpcRequest(request) {
      return {
        method: "signMessage",
        params: [JSON.stringify(request)]
      };
    }
    parseAndThrowError(response) {
      let ErrorConstructor = UnknownError;
      if (response.error.code in signMessageErrors) {
        ErrorConstructor = signMessageErrors[response.error.code] || UnknownError;
      }
      throw new ErrorConstructor(response.error.message);
    }
    convertFromRpcResponse(rpcResponse) {
      return {
        internalBoc: rpcResponse.result.internalBoc
      };
    }
  };
  var signMessageParser = new SignMessageParser();
  var HttpBridgeGatewayStorage = class {
    constructor(storage, bridgeUrl) {
      this.storage = storage;
      this.storeKey = "ton-connect-storage_http-bridge-gateway::" + bridgeUrl;
    }
    storeLastEventId(lastEventId) {
      return __awaiter(this, void 0, void 0, function* () {
        return this.storage.setItem(this.storeKey, lastEventId);
      });
    }
    removeLastEventId() {
      return __awaiter(this, void 0, void 0, function* () {
        return this.storage.removeItem(this.storeKey);
      });
    }
    getLastEventId() {
      return __awaiter(this, void 0, void 0, function* () {
        const stored = yield this.storage.getItem(this.storeKey);
        if (!stored) {
          return null;
        }
        return stored;
      });
    }
  };
  function removeUrlLastSlash(url) {
    if (url.slice(-1) === "/") {
      return url.slice(0, -1);
    }
    return url;
  }
  function addPathToUrl(url, path) {
    return removeUrlLastSlash(url) + "/" + path;
  }
  function isTelegramUrl(link) {
    if (!link) {
      return false;
    }
    const url = new URL(link);
    return url.protocol === "tg:" || url.hostname === "t.me";
  }
  function isConnectUrl(link) {
    if (!link) {
      return false;
    }
    return link.includes("ton_addr") || link.includes("ton--5Faddr");
  }
  function encodeTelegramUrlParameters(parameters) {
    return parameters.replaceAll(".", "%2E").replaceAll("-", "%2D").replaceAll("_", "%5F").replaceAll("&", "-").replaceAll("=", "__").replaceAll("%", "--");
  }
  function decodeTelegramUrlParameters(parameters) {
    return parameters.replaceAll("--", "%").replaceAll("__", "=").replaceAll("-", "&").replaceAll("%5F", "_").replaceAll("%2D", "-").replaceAll("%2E", ".");
  }
  function delay(timeout2, options) {
    return __awaiter(this, void 0, void 0, function* () {
      return new Promise((resolve, reject) => {
        var _a, _b;
        if ((_a = void 0) === null || _a === void 0 ? void 0 : _a.aborted) {
          reject(new TonConnectError("Delay aborted"));
          return;
        }
        const timeoutId = setTimeout(() => resolve(), timeout2);
        (_b = void 0) === null || _b === void 0 ? void 0 : _b.addEventListener("abort", () => {
          clearTimeout(timeoutId);
          reject(new TonConnectError("Delay aborted"));
        });
      });
    });
  }
  function createAbortController(signal) {
    const abortController = new AbortController();
    if (signal === null || signal === void 0 ? void 0 : signal.aborted) {
      abortController.abort();
    } else {
      signal === null || signal === void 0 ? void 0 : signal.addEventListener("abort", () => abortController.abort(), { once: true });
    }
    return abortController;
  }
  function callForSuccess(fn, options) {
    return __awaiter(this, void 0, void 0, function* () {
      var _a, _b;
      const attempts = (_a = options === null || options === void 0 ? void 0 : options.attempts) !== null && _a !== void 0 ? _a : 10;
      const delayMs = (_b = options === null || options === void 0 ? void 0 : options.delayMs) !== null && _b !== void 0 ? _b : 200;
      const abortController = createAbortController(options === null || options === void 0 ? void 0 : options.signal);
      if (typeof fn !== "function") {
        throw new TonConnectError(`Expected a function, got ${typeof fn}`);
      }
      let i = 0;
      let lastError;
      while (i < attempts) {
        if (abortController.signal.aborted) {
          throw new TonConnectError(`Aborted after attempts ${i}`);
        }
        try {
          return yield fn({ signal: abortController.signal });
        } catch (err) {
          lastError = err;
          i++;
          if (i < attempts) {
            yield delay(delayMs);
          }
        }
      }
      throw lastError;
    });
  }
  function logDebug(...args) {
    {
      try {
        console.debug("[TON_CONNECT_SDK]", ...args);
      } catch (_a) {
      }
    }
  }
  function logError(...args) {
    {
      try {
        console.error("[TON_CONNECT_SDK]", ...args);
      } catch (_a) {
      }
    }
  }
  function logWarning(...args) {
    {
      try {
        console.warn("[TON_CONNECT_SDK]", ...args);
      } catch (_a) {
      }
    }
  }
  function createResource(createFn, disposeFn) {
    let currentResource = null;
    let currentArgs = null;
    let currentPromise = null;
    let currentSignal = null;
    let abortController = null;
    const create = (signal, ...args) => __awaiter(this, void 0, void 0, function* () {
      currentSignal = signal !== null && signal !== void 0 ? signal : null;
      abortController === null || abortController === void 0 ? void 0 : abortController.abort();
      abortController = createAbortController(signal);
      if (abortController.signal.aborted) {
        throw new TonConnectError("Resource creation was aborted");
      }
      currentArgs = args !== null && args !== void 0 ? args : null;
      const promise = createFn(abortController.signal, ...args);
      currentPromise = promise;
      const resource = yield promise;
      if (currentPromise !== promise && resource !== currentResource) {
        yield disposeFn(resource);
        throw new TonConnectError("Resource creation was aborted by a new resource creation");
      }
      currentResource = resource;
      return currentResource;
    });
    const current = () => {
      return currentResource !== null && currentResource !== void 0 ? currentResource : null;
    };
    const dispose = () => __awaiter(this, void 0, void 0, function* () {
      try {
        const resource = currentResource;
        currentResource = null;
        const promise = currentPromise;
        currentPromise = null;
        try {
          abortController === null || abortController === void 0 ? void 0 : abortController.abort();
        } catch (e) {
        }
        yield Promise.allSettled([
          resource ? disposeFn(resource) : Promise.resolve(),
          promise ? disposeFn(yield promise) : Promise.resolve()
        ]);
      } catch (e) {
      }
    });
    const recreate = (delayMs) => __awaiter(this, void 0, void 0, function* () {
      const resource = currentResource;
      const promise = currentPromise;
      const args = currentArgs;
      const signal = currentSignal;
      yield delay(delayMs);
      if (resource === currentResource && promise === currentPromise && args === currentArgs && signal === currentSignal) {
        return yield create(currentSignal, ...args !== null && args !== void 0 ? args : []);
      }
      throw new TonConnectError("Resource recreation was aborted by a new resource creation");
    });
    return {
      create,
      current,
      dispose,
      recreate
    };
  }
  function timeout(fn, options) {
    const timeout2 = options === null || options === void 0 ? void 0 : options.timeout;
    const signal = options === null || options === void 0 ? void 0 : options.signal;
    const abortController = createAbortController(signal);
    return new Promise((resolve, reject) => __awaiter(this, void 0, void 0, function* () {
      if (abortController.signal.aborted) {
        reject(new TonConnectError("Operation aborted"));
        return;
      }
      let timeoutId;
      if (typeof timeout2 !== "undefined") {
        timeoutId = setTimeout(() => {
          abortController.abort();
          reject(new TonConnectError(`Timeout after ${timeout2}ms`));
        }, timeout2);
      }
      abortController.signal.addEventListener("abort", () => {
        clearTimeout(timeoutId);
        reject(new TonConnectError("Operation aborted"));
      }, { once: true });
      const deferOptions = { timeout: timeout2, abort: abortController.signal };
      yield fn((...args) => {
        clearTimeout(timeoutId);
        resolve(...args);
      }, () => {
        clearTimeout(timeoutId);
        reject();
      }, deferOptions);
    }));
  }
  var BridgeGateway = class {
    get isReady() {
      const eventSource = this.eventSource.current();
      return (eventSource === null || eventSource === void 0 ? void 0 : eventSource.readyState) === EventSource.OPEN;
    }
    get isClosed() {
      const eventSource = this.eventSource.current();
      return (eventSource === null || eventSource === void 0 ? void 0 : eventSource.readyState) !== EventSource.OPEN;
    }
    get isConnecting() {
      const eventSource = this.eventSource.current();
      return (eventSource === null || eventSource === void 0 ? void 0 : eventSource.readyState) === EventSource.CONNECTING;
    }
    constructor(storage, bridgeUrl, sessionId, listener, errorsListener, analyticsManager) {
      this.bridgeUrl = bridgeUrl;
      this.sessionId = sessionId;
      this.listener = listener;
      this.errorsListener = errorsListener;
      this.ssePath = "events";
      this.postPath = "message";
      this.heartbeatMessage = "heartbeat";
      this.defaultTtl = 300;
      this.defaultReconnectDelay = 2e3;
      this.defaultResendDelay = 5e3;
      this.eventSource = createResource((signal, openingDeadlineMS, traceId) => __awaiter(this, void 0, void 0, function* () {
        const eventSourceConfig = {
          bridgeUrl: this.bridgeUrl,
          ssePath: this.ssePath,
          sessionId: this.sessionId,
          bridgeGatewayStorage: this.bridgeGatewayStorage,
          errorHandler: this.errorsHandler.bind(this),
          messageHandler: this.messagesHandler.bind(this),
          signal,
          openingDeadlineMS,
          traceId
        };
        return yield createEventSource(eventSourceConfig);
      }), (resource) => __awaiter(this, void 0, void 0, function* () {
        resource.close();
      }));
      this.bridgeGatewayStorage = new HttpBridgeGatewayStorage(storage, bridgeUrl);
      this.analytics = analyticsManager === null || analyticsManager === void 0 ? void 0 : analyticsManager.scoped({
        bridge_url: bridgeUrl,
        client_id: sessionId
      });
    }
    registerSession(options) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b, _c;
        try {
          (_a = this.analytics) === null || _a === void 0 ? void 0 : _a.emitBridgeClientConnectStarted({
            trace_id: options === null || options === void 0 ? void 0 : options.traceId
          });
          const connectionStarted = Date.now();
          yield this.eventSource.create(options === null || options === void 0 ? void 0 : options.signal, options === null || options === void 0 ? void 0 : options.openingDeadlineMS, options === null || options === void 0 ? void 0 : options.traceId);
          const bridgeConnectDuration = Date.now() - connectionStarted;
          (_b = this.analytics) === null || _b === void 0 ? void 0 : _b.emitBridgeClientConnectEstablished({
            bridge_connect_duration: bridgeConnectDuration,
            trace_id: options === null || options === void 0 ? void 0 : options.traceId
          });
        } catch (error) {
          (_c = this.analytics) === null || _c === void 0 ? void 0 : _c.emitBridgeClientConnectError({
            trace_id: options === null || options === void 0 ? void 0 : options.traceId,
            error_message: String(error)
          });
          throw error;
        }
      });
    }
    send(message, receiver, topic, ttlOrOptions) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a;
        const options = {};
        if (typeof ttlOrOptions === "number") {
          options.ttl = ttlOrOptions;
        } else {
          options.ttl = ttlOrOptions === null || ttlOrOptions === void 0 ? void 0 : ttlOrOptions.ttl;
          options.signal = ttlOrOptions === null || ttlOrOptions === void 0 ? void 0 : ttlOrOptions.signal;
          options.attempts = ttlOrOptions === null || ttlOrOptions === void 0 ? void 0 : ttlOrOptions.attempts;
          options.traceId = ttlOrOptions === null || ttlOrOptions === void 0 ? void 0 : ttlOrOptions.traceId;
        }
        const url = new URL(addPathToUrl(this.bridgeUrl, this.postPath));
        url.searchParams.append("client_id", this.sessionId);
        url.searchParams.append("to", receiver);
        url.searchParams.append("ttl", ((options === null || options === void 0 ? void 0 : options.ttl) || this.defaultTtl).toString());
        url.searchParams.append("topic", topic);
        if (options === null || options === void 0 ? void 0 : options.traceId) {
          url.searchParams.append("trace_id", options.traceId);
        }
        const body = Base64.encode(message);
        yield callForSuccess((options2) => __awaiter(this, void 0, void 0, function* () {
          const response = yield this.post(url, body, options2.signal);
          if (!response.ok) {
            throw new TonConnectError(`Bridge send failed, status ${response.status}`);
          }
        }), {
          attempts: (_a = options === null || options === void 0 ? void 0 : options.attempts) !== null && _a !== void 0 ? _a : Number.MAX_SAFE_INTEGER,
          delayMs: this.defaultResendDelay,
          signal: options === null || options === void 0 ? void 0 : options.signal
        });
      });
    }
    pause() {
      this.eventSource.dispose().catch((e) => logError(`Bridge pause failed, ${e}`));
    }
    unPause() {
      return __awaiter(this, void 0, void 0, function* () {
        const RECREATE_WITHOUT_DELAY = 0;
        yield this.eventSource.recreate(RECREATE_WITHOUT_DELAY);
      });
    }
    close() {
      return __awaiter(this, void 0, void 0, function* () {
        yield this.eventSource.dispose().catch((e) => logError(`Bridge close failed, ${e}`));
      });
    }
    setListener(listener) {
      this.listener = listener;
    }
    setErrorsListener(errorsListener) {
      this.errorsListener = errorsListener;
    }
    post(url, body, signal) {
      return __awaiter(this, void 0, void 0, function* () {
        const response = yield fetch(url, {
          method: "post",
          body,
          signal
        });
        if (!response.ok) {
          throw new TonConnectError(`Bridge send failed, status ${response.status}`);
        }
        return response;
      });
    }
    errorsHandler(eventSource, e) {
      return __awaiter(this, void 0, void 0, function* () {
        if (this.isConnecting) {
          eventSource.close();
          throw new TonConnectError("Bridge error, failed to connect");
        }
        if (this.isReady) {
          try {
            this.errorsListener(e);
          } catch (e2) {
          }
          return;
        }
        if (this.isClosed) {
          eventSource.close();
          logDebug(`Bridge reconnecting, ${this.defaultReconnectDelay}ms delay`);
          return yield this.eventSource.recreate(this.defaultReconnectDelay);
        }
        throw new TonConnectError("Bridge error, unknown state");
      });
    }
    messagesHandler(e) {
      return __awaiter(this, void 0, void 0, function* () {
        if (e.data === this.heartbeatMessage) {
          return;
        }
        yield this.bridgeGatewayStorage.storeLastEventId(e.lastEventId);
        if (this.isClosed) {
          return;
        }
        let bridgeIncomingMessage;
        try {
          const bridgeIncomingMessageRaw = JSON.parse(e.data);
          bridgeIncomingMessage = {
            message: bridgeIncomingMessageRaw.message,
            from: bridgeIncomingMessageRaw.from,
            traceId: bridgeIncomingMessageRaw.trace_id
          };
        } catch (_) {
          throw new TonConnectError(`Bridge message parse failed, message ${e.data}`);
        }
        this.listener(bridgeIncomingMessage);
      });
    }
  };
  function createEventSource(config) {
    return __awaiter(this, void 0, void 0, function* () {
      return yield timeout((resolve, reject, deferOptions) => __awaiter(this, void 0, void 0, function* () {
        var _a;
        const abortController = createAbortController(deferOptions.signal);
        const signal = abortController.signal;
        if (signal.aborted) {
          reject(new TonConnectError("Bridge connection aborted"));
          return;
        }
        const url = new URL(addPathToUrl(config.bridgeUrl, config.ssePath));
        url.searchParams.append("client_id", config.sessionId);
        const lastEventId = yield config.bridgeGatewayStorage.getLastEventId();
        if (lastEventId) {
          url.searchParams.append("last_event_id", lastEventId);
        }
        if (config.traceId) {
          url.searchParams.append("trace_id", config.traceId);
        }
        if (signal.aborted) {
          reject(new TonConnectError("Bridge connection aborted"));
          return;
        }
        const eventSource = new EventSource(url.toString());
        eventSource.onerror = (reason) => __awaiter(this, void 0, void 0, function* () {
          if (signal.aborted) {
            eventSource.close();
            reject(new TonConnectError("Bridge connection aborted"));
            return;
          }
          try {
            const newInstance = yield config.errorHandler(eventSource, reason);
            if (newInstance !== eventSource) {
              eventSource.close();
            }
            if (newInstance && newInstance !== eventSource) {
              resolve(newInstance);
            }
          } catch (e) {
            eventSource.close();
            reject(e);
          }
        });
        eventSource.onopen = () => {
          if (signal.aborted) {
            eventSource.close();
            reject(new TonConnectError("Bridge connection aborted"));
            return;
          }
          resolve(eventSource);
        };
        eventSource.onmessage = (event) => {
          if (signal.aborted) {
            eventSource.close();
            reject(new TonConnectError("Bridge connection aborted"));
            return;
          }
          config.messageHandler(event);
        };
        (_a = config.signal) === null || _a === void 0 ? void 0 : _a.addEventListener("abort", () => {
          eventSource.close();
          reject(new TonConnectError("Bridge connection aborted"));
        });
      }), { timeout: config.openingDeadlineMS, signal: config.signal });
    });
  }
  var CONNECTION_HTTP_EXPIRATION_TIME = 5 * 60 * 1e3;
  function isPendingConnectionHttp(connection) {
    return !("connectEvent" in connection);
  }
  function isPendingConnectionHttpRaw(connection) {
    return !("connectEvent" in connection);
  }
  function isExpiredPendingConnectionHttpRaw(connection) {
    var _a;
    return Date.now() - ((_a = connection.createdAt) !== null && _a !== void 0 ? _a : 0) > CONNECTION_HTTP_EXPIRATION_TIME;
  }
  var getRandomValues;
  var rnds8 = new Uint8Array(16);
  function rng() {
    if (!getRandomValues) {
      if (typeof crypto === "undefined" || !crypto.getRandomValues) {
        throw new Error("crypto.getRandomValues() not supported. See https://github.com/uuidjs/uuid#getrandomvalues-not-supported");
      }
      getRandomValues = crypto.getRandomValues.bind(crypto);
    }
    return getRandomValues(rnds8);
  }
  var byteToHex = [];
  for (let i = 0; i < 256; ++i) {
    byteToHex.push((i + 256).toString(16).slice(1));
  }
  function unsafeStringify(arr, offset = 0) {
    return (byteToHex[arr[offset + 0]] + byteToHex[arr[offset + 1]] + byteToHex[arr[offset + 2]] + byteToHex[arr[offset + 3]] + "-" + byteToHex[arr[offset + 4]] + byteToHex[arr[offset + 5]] + "-" + byteToHex[arr[offset + 6]] + byteToHex[arr[offset + 7]] + "-" + byteToHex[arr[offset + 8]] + byteToHex[arr[offset + 9]] + "-" + byteToHex[arr[offset + 10]] + byteToHex[arr[offset + 11]] + byteToHex[arr[offset + 12]] + byteToHex[arr[offset + 13]] + byteToHex[arr[offset + 14]] + byteToHex[arr[offset + 15]]).toLowerCase();
  }
  var _state = {};
  function UUIDv7(options, buf, offset) {
    var _a, _b, _c;
    let bytes;
    if (options) {
      bytes = v7Bytes((_c = (_a = options.random) !== null && _a !== void 0 ? _a : (_b = options.rng) === null || _b === void 0 ? void 0 : _b.call(options)) !== null && _c !== void 0 ? _c : rng(), options.msecs, options.seq, buf, offset);
    } else {
      const now = Date.now();
      const rnds = rng();
      updateV7State(_state, now, rnds);
      bytes = v7Bytes(rnds, _state.msecs, _state.seq, buf, offset);
    }
    return buf !== null && buf !== void 0 ? buf : unsafeStringify(bytes);
  }
  function updateV7State(state2, now, rnds) {
    var _a, _b;
    (_a = state2.msecs) !== null && _a !== void 0 ? _a : state2.msecs = -Infinity;
    (_b = state2.seq) !== null && _b !== void 0 ? _b : state2.seq = 0;
    if (now > state2.msecs) {
      state2.seq = rnds[6] << 23 | rnds[7] << 16 | rnds[8] << 8 | rnds[9];
      state2.msecs = now;
    } else {
      state2.seq = state2.seq + 1 | 0;
      if (state2.seq === 0) {
        state2.msecs++;
      }
    }
    return state2;
  }
  function v7Bytes(rnds, msecs, seq, buf, offset = 0) {
    if (rnds.length < 16) {
      throw new Error("Random bytes length must be >= 16");
    }
    if (!buf) {
      buf = new Uint8Array(16);
      offset = 0;
    } else {
      if (offset < 0 || offset + 16 > buf.length) {
        throw new RangeError(`UUID byte range ${offset}:${offset + 15} is out of buffer bounds`);
      }
    }
    msecs !== null && msecs !== void 0 ? msecs : msecs = Date.now();
    seq !== null && seq !== void 0 ? seq : seq = rnds[6] * 127 << 24 | rnds[7] << 16 | rnds[8] << 8 | rnds[9];
    buf[offset++] = msecs / 1099511627776 & 255;
    buf[offset++] = msecs / 4294967296 & 255;
    buf[offset++] = msecs / 16777216 & 255;
    buf[offset++] = msecs / 65536 & 255;
    buf[offset++] = msecs / 256 & 255;
    buf[offset++] = msecs & 255;
    buf[offset++] = 112 | seq >>> 28 & 15;
    buf[offset++] = seq >>> 20 & 255;
    buf[offset++] = 128 | seq >>> 14 & 63;
    buf[offset++] = seq >>> 6 & 255;
    buf[offset++] = seq << 2 & 255 | rnds[10] & 3;
    buf[offset++] = rnds[11];
    buf[offset++] = rnds[12];
    buf[offset++] = rnds[13];
    buf[offset++] = rnds[14];
    buf[offset++] = rnds[15];
    return buf;
  }
  function waitForSome(promises, count) {
    return __awaiter(this, void 0, void 0, function* () {
      if (count <= 0)
        return [];
      if (count > promises.length) {
        throw new RangeError("count cannot be greater than the number of promises");
      }
      const results = new Array(promises.length);
      let settledCount = 0;
      return new Promise((resolve) => {
        promises.forEach((p, index) => {
          Promise.resolve(p).then((value) => ({ status: "fulfilled", value })).catch((reason) => ({ status: "rejected", reason })).then((result) => {
            results[index] = result;
            settledCount++;
            if (settledCount === count) {
              resolve(results);
            }
          });
        });
      });
    });
  }
  var PROTOCOL_VERSION = 2;
  function normalizeBase64(data) {
    if (typeof data !== "string")
      return void 0;
    const paddedLength = data.length + (4 - data.length % 4) % 4;
    return data.replace(/-/g, "+").replace(/_/g, "/").padEnd(paddedLength, "=");
  }
  function toBase64Url(base64) {
    return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  }
  function generateUniversalLink(universalLink, message, options) {
    if (isTelegramUrl(universalLink)) {
      return generateTGUniversalLink(universalLink, message, options);
    }
    return generateRegularUniversalLink(universalLink, message, options);
  }
  function generateRegularUniversalLink(universalLink, message, options) {
    const url = new URL(universalLink);
    url.searchParams.append("v", PROTOCOL_VERSION.toString());
    url.searchParams.append("id", options.sessionId);
    url.searchParams.append("trace_id", options.traceId);
    url.searchParams.append("r", JSON.stringify(message));
    if (options.embeddedRequest) {
      url.searchParams.append("e", toBase64Url(Base64.encode(JSON.stringify(options.embeddedRequest), false)));
    }
    return url.toString();
  }
  function generateTGUniversalLink(universalLink, message, options) {
    const urlToWrap = generateRegularUniversalLink("about:blank", message, options);
    const linkParams = urlToWrap.split("?")[1];
    const startapp = "tonconnect-" + encodeTelegramUrlParameters(linkParams);
    const updatedUniversalLink = convertToDirectLink(universalLink);
    const url = new URL(updatedUniversalLink);
    url.searchParams.append("startapp", startapp);
    return url.toString();
  }
  function convertToDirectLink(universalLink) {
    const url = new URL(universalLink);
    if (url.searchParams.has("attach")) {
      url.searchParams.delete("attach");
      url.pathname += "/start";
    }
    return url.toString();
  }
  var BridgeProvider = class _BridgeProvider {
    static fromStorage(storage, analyticsManager) {
      return __awaiter(this, void 0, void 0, function* () {
        const connection = yield storage.getHttpConnection();
        if (isPendingConnectionHttp(connection)) {
          return new _BridgeProvider(storage, connection.connectionSource, analyticsManager);
        }
        return new _BridgeProvider(storage, { bridgeUrl: connection.session.bridgeUrl }, analyticsManager);
      });
    }
    constructor(connectionStorage, walletConnectionSource, analyticsManager) {
      var _a;
      this.connectionStorage = connectionStorage;
      this.walletConnectionSource = walletConnectionSource;
      this.analyticsManager = analyticsManager;
      this.type = "http";
      this.standardUniversalLink = "tc://";
      this.pendingRequests = /* @__PURE__ */ new Map();
      this.session = null;
      this.gateway = null;
      this.pendingGateways = [];
      this.listeners = [];
      this.defaultOpeningDeadlineMS = 12e3;
      this.defaultRetryTimeoutMS = 2e3;
      this.maxUrlLength = 1024;
      this.optionalOpenGateways = 3;
      this.analytics = (_a = this.analyticsManager) === null || _a === void 0 ? void 0 : _a.scoped();
    }
    connect(message, options) {
      var _a, _b, _c, _d;
      const traceId = (_a = options === null || options === void 0 ? void 0 : options.traceId) !== null && _a !== void 0 ? _a : UUIDv7();
      const abortController = createAbortController(options === null || options === void 0 ? void 0 : options.signal);
      (_b = this.abortController) === null || _b === void 0 ? void 0 : _b.abort();
      this.abortController = abortController;
      this.closeGateways();
      const sessionCrypto = new SessionCrypto();
      this.session = {
        sessionCrypto,
        bridgeUrl: "bridgeUrl" in this.walletConnectionSource ? this.walletConnectionSource.bridgeUrl : ""
      };
      this.connectionStorage.storeConnection({
        type: "http",
        connectionSource: this.walletConnectionSource,
        sessionCrypto
      }).then(() => __awaiter(this, void 0, void 0, function* () {
        if (abortController.signal.aborted) {
          return;
        }
        yield callForSuccess((_options) => {
          var _a2;
          return this.openGateways(sessionCrypto, {
            openingDeadlineMS: (_a2 = options === null || options === void 0 ? void 0 : options.openingDeadlineMS) !== null && _a2 !== void 0 ? _a2 : this.defaultOpeningDeadlineMS,
            signal: _options === null || _options === void 0 ? void 0 : _options.signal,
            traceId
          });
        }, {
          attempts: Number.MAX_SAFE_INTEGER,
          delayMs: this.defaultRetryTimeoutMS,
          signal: abortController.signal
        });
      }));
      const universalLink = "universalLink" in this.walletConnectionSource && this.walletConnectionSource.universalLink ? this.walletConnectionSource.universalLink : this.standardUniversalLink;
      const embeddedRequest = (_c = options === null || options === void 0 ? void 0 : options.embeddedRequest) === null || _c === void 0 ? void 0 : _c.peek();
      const link = generateUniversalLink(universalLink, message, {
        traceId,
        sessionId: this.session.sessionCrypto.sessionId,
        embeddedRequest
      });
      if (link.length <= this.maxUrlLength) {
        (_d = options === null || options === void 0 ? void 0 : options.embeddedRequest) === null || _d === void 0 ? void 0 : _d.consume();
        return link;
      }
      return generateUniversalLink(universalLink, message, {
        traceId,
        sessionId: this.session.sessionCrypto.sessionId
      });
    }
    restoreConnection(options) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b, _c;
        const traceId = (_a = options === null || options === void 0 ? void 0 : options.traceId) !== null && _a !== void 0 ? _a : UUIDv7();
        const abortController = createAbortController(options === null || options === void 0 ? void 0 : options.signal);
        (_b = this.abortController) === null || _b === void 0 ? void 0 : _b.abort();
        this.abortController = abortController;
        if (abortController.signal.aborted) {
          return;
        }
        this.closeGateways();
        const storedConnection = yield this.connectionStorage.getHttpConnection();
        if (!storedConnection) {
          return;
        }
        if (abortController.signal.aborted) {
          return;
        }
        const openingDeadlineMS = (_c = options === null || options === void 0 ? void 0 : options.openingDeadlineMS) !== null && _c !== void 0 ? _c : this.defaultOpeningDeadlineMS;
        if (isPendingConnectionHttp(storedConnection)) {
          this.session = {
            sessionCrypto: storedConnection.sessionCrypto,
            bridgeUrl: "bridgeUrl" in this.walletConnectionSource ? this.walletConnectionSource.bridgeUrl : ""
          };
          return yield this.openGateways(storedConnection.sessionCrypto, {
            openingDeadlineMS,
            signal: abortController === null || abortController === void 0 ? void 0 : abortController.signal,
            traceId: options === null || options === void 0 ? void 0 : options.traceId
          });
        }
        if (Array.isArray(this.walletConnectionSource)) {
          throw new TonConnectError("Internal error. Connection source is array while WalletConnectionSourceHTTP was expected.");
        }
        this.session = storedConnection.session;
        if (this.gateway) {
          logDebug("Gateway is already opened, closing previous gateway");
          yield this.gateway.close();
        }
        this.gateway = new BridgeGateway(this.connectionStorage.storage, this.walletConnectionSource.bridgeUrl, storedConnection.session.sessionCrypto.sessionId, this.gatewayListener.bind(this), this.gatewayErrorsListener.bind(this), this.analyticsManager);
        if (abortController.signal.aborted) {
          return;
        }
        this.listeners.forEach((listener) => listener(Object.assign(Object.assign({}, storedConnection.connectEvent), { traceId })));
        try {
          yield callForSuccess((options2) => this.gateway.registerSession({
            openingDeadlineMS,
            signal: options2.signal,
            traceId
          }), {
            attempts: Number.MAX_SAFE_INTEGER,
            delayMs: this.defaultRetryTimeoutMS,
            signal: abortController.signal
          });
        } catch (e) {
          yield this.disconnect({ signal: abortController.signal, traceId });
          return;
        }
      });
    }
    sendRequest(request, optionsOrOnRequestSent) {
      var _a;
      const options = {};
      if (typeof optionsOrOnRequestSent === "function") {
        options.onRequestSent = optionsOrOnRequestSent;
      } else {
        options.onRequestSent = optionsOrOnRequestSent === null || optionsOrOnRequestSent === void 0 ? void 0 : optionsOrOnRequestSent.onRequestSent;
        options.signal = optionsOrOnRequestSent === null || optionsOrOnRequestSent === void 0 ? void 0 : optionsOrOnRequestSent.signal;
        options.attempts = optionsOrOnRequestSent === null || optionsOrOnRequestSent === void 0 ? void 0 : optionsOrOnRequestSent.attempts;
        options.traceId = optionsOrOnRequestSent === null || optionsOrOnRequestSent === void 0 ? void 0 : optionsOrOnRequestSent.traceId;
      }
      (_a = options.traceId) !== null && _a !== void 0 ? _a : options.traceId = UUIDv7();
      return new Promise((resolve, reject) => __awaiter(this, void 0, void 0, function* () {
        var _a2, _b;
        if (!this.gateway || !this.session || !("walletPublicKey" in this.session)) {
          throw new TonConnectError("Trying to send bridge request without session");
        }
        const id = (yield this.connectionStorage.getNextRpcRequestId()).toString();
        yield this.connectionStorage.increaseNextRpcRequestId();
        logDebug("Send http-bridge request:", Object.assign(Object.assign({}, request), { id }));
        const encodedRequest = this.session.sessionCrypto.encrypt(JSON.stringify(Object.assign(Object.assign({}, request), { id })), hexToByteArray(this.session.walletPublicKey));
        try {
          (_a2 = this.analytics) === null || _a2 === void 0 ? void 0 : _a2.emitBridgeClientMessageSent({
            bridge_url: this.gateway.bridgeUrl,
            client_id: this.session.sessionCrypto.sessionId,
            wallet_id: this.session.walletPublicKey,
            message_id: id,
            request_type: request.method,
            trace_id: options.traceId
          });
          yield this.gateway.send(encodedRequest, this.session.walletPublicKey, request.method, {
            attempts: options === null || options === void 0 ? void 0 : options.attempts,
            signal: options === null || options === void 0 ? void 0 : options.signal,
            traceId: options.traceId
          });
          (_b = options === null || options === void 0 ? void 0 : options.onRequestSent) === null || _b === void 0 ? void 0 : _b.call(options);
          this.pendingRequests.set(id.toString(), resolve);
        } catch (e) {
          reject(e);
        }
      }));
    }
    closeConnection() {
      this.closeGateways();
      this.listeners = [];
      this.session = null;
      this.gateway = null;
    }
    disconnect(options) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a;
        const traceId = (_a = options === null || options === void 0 ? void 0 : options.traceId) !== null && _a !== void 0 ? _a : UUIDv7();
        return new Promise((resolve) => __awaiter(this, void 0, void 0, function* () {
          let called = false;
          let timeoutId = null;
          const onRequestSent = () => {
            if (!called) {
              called = true;
              this.removeBridgeAndSession().then(resolve);
            }
          };
          try {
            this.closeGateways();
            const abortController = createAbortController(options === null || options === void 0 ? void 0 : options.signal);
            timeoutId = setTimeout(() => {
              abortController.abort();
            }, this.defaultOpeningDeadlineMS);
            yield this.sendRequest({ method: "disconnect", params: [] }, {
              onRequestSent,
              signal: abortController.signal,
              attempts: 1,
              traceId
            });
          } catch (e) {
            logDebug("Disconnect error:", e);
            if (!called) {
              this.removeBridgeAndSession().then(resolve);
            }
          } finally {
            if (timeoutId) {
              clearTimeout(timeoutId);
            }
            onRequestSent();
          }
        }));
      });
    }
    listen(callback) {
      this.listeners.push(callback);
      return () => this.listeners = this.listeners.filter((listener) => listener !== callback);
    }
    pause() {
      var _a;
      (_a = this.gateway) === null || _a === void 0 ? void 0 : _a.pause();
      this.pendingGateways.forEach((bridge) => bridge.pause());
    }
    unPause() {
      return __awaiter(this, void 0, void 0, function* () {
        const promises = this.pendingGateways.map((bridge) => bridge.unPause());
        if (this.gateway) {
          promises.push(this.gateway.unPause());
        }
        yield Promise.all(promises);
      });
    }
    pendingGatewaysListener(gateway, bridgeUrl, bridgeIncomingMessage) {
      return __awaiter(this, void 0, void 0, function* () {
        if (!this.pendingGateways.includes(gateway)) {
          yield gateway.close();
          return;
        }
        this.closeGateways({ except: gateway });
        if (this.gateway) {
          logDebug("Gateway is already opened, closing previous gateway");
          yield this.gateway.close();
        }
        this.session.bridgeUrl = bridgeUrl;
        this.gateway = gateway;
        this.gateway.setErrorsListener(this.gatewayErrorsListener.bind(this));
        this.gateway.setListener(this.gatewayListener.bind(this));
        return this.gatewayListener(bridgeIncomingMessage);
      });
    }
    gatewayListener(bridgeIncomingMessage) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b, _c;
        const traceId = (_a = bridgeIncomingMessage.traceId) !== null && _a !== void 0 ? _a : UUIDv7();
        let walletMessage;
        try {
          walletMessage = JSON.parse(this.session.sessionCrypto.decrypt(Base64.decode(bridgeIncomingMessage.message).toUint8Array(), hexToByteArray(bridgeIncomingMessage.from)));
        } catch (err) {
          (_b = this.analytics) === null || _b === void 0 ? void 0 : _b.emitBridgeClientMessageDecodeError({
            bridge_url: this.session.bridgeUrl,
            client_id: this.session.sessionCrypto.sessionId,
            wallet_id: bridgeIncomingMessage.from,
            error_message: String(err),
            trace_id: bridgeIncomingMessage === null || bridgeIncomingMessage === void 0 ? void 0 : bridgeIncomingMessage.traceId
          });
          throw err;
        }
        logDebug("Wallet message received:", walletMessage);
        const requestType = "event" in walletMessage ? walletMessage.event : "";
        (_c = this.analytics) === null || _c === void 0 ? void 0 : _c.emitBridgeClientMessageReceived({
          bridge_url: this.session.bridgeUrl,
          client_id: this.session.sessionCrypto.sessionId,
          wallet_id: bridgeIncomingMessage.from,
          message_id: String(walletMessage.id),
          request_type: requestType,
          trace_id: bridgeIncomingMessage === null || bridgeIncomingMessage === void 0 ? void 0 : bridgeIncomingMessage.traceId
        });
        if (!("event" in walletMessage)) {
          const id = walletMessage.id.toString();
          const resolve = this.pendingRequests.get(id);
          if (!resolve) {
            logDebug(`Response id ${id} doesn't match any request's id`);
            return;
          }
          resolve(Object.assign(Object.assign({}, walletMessage), { traceId }));
          this.pendingRequests.delete(id);
          return;
        }
        if (walletMessage.id !== void 0) {
          const lastId = yield this.connectionStorage.getLastWalletEventId();
          if (lastId !== void 0 && walletMessage.id <= lastId) {
            logError(`Received event id (=${walletMessage.id}) must be greater than stored last wallet event id (=${lastId}) `);
            return;
          }
          if (walletMessage.event !== "connect") {
            yield this.connectionStorage.storeLastWalletEventId(walletMessage.id);
          }
        }
        const listeners = this.listeners;
        if (walletMessage.event === "connect") {
          yield this.updateSession(walletMessage, bridgeIncomingMessage.from);
        }
        if (walletMessage.event === "disconnect") {
          logDebug(`Removing bridge and session: received disconnect event`);
          yield this.removeBridgeAndSession();
        }
        listeners.forEach((listener) => listener(Object.assign(Object.assign({}, walletMessage), { traceId })));
      });
    }
    gatewayErrorsListener(e) {
      return __awaiter(this, void 0, void 0, function* () {
        throw new TonConnectError(`Bridge error ${JSON.stringify(e)}`);
      });
    }
    updateSession(connectEvent, walletPublicKey) {
      return __awaiter(this, void 0, void 0, function* () {
        this.session = Object.assign(Object.assign({}, this.session), { walletPublicKey });
        const tonAddrItem = connectEvent.payload.items.find((item) => item.name === "ton_addr");
        const connectEventToSave = Object.assign(Object.assign({}, connectEvent), { payload: Object.assign(Object.assign({}, connectEvent.payload), { items: [tonAddrItem] }) });
        yield this.connectionStorage.storeConnection({
          type: "http",
          session: this.session,
          lastWalletEventId: connectEvent.id,
          connectEvent: connectEventToSave,
          nextRpcRequestId: 0
        });
      });
    }
    removeBridgeAndSession() {
      return __awaiter(this, void 0, void 0, function* () {
        this.closeConnection();
        yield this.connectionStorage.removeConnection();
      });
    }
    openGateways(sessionCrypto, options) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a;
        const traceId = (_a = options === null || options === void 0 ? void 0 : options.traceId) !== null && _a !== void 0 ? _a : UUIDv7();
        if (Array.isArray(this.walletConnectionSource)) {
          this.pendingGateways.map((bridge) => bridge.close().catch());
          this.pendingGateways = this.walletConnectionSource.map((source) => {
            const gateway = new BridgeGateway(this.connectionStorage.storage, source.bridgeUrl, sessionCrypto.sessionId, () => {
            }, () => {
            }, this.analyticsManager);
            gateway.setListener((message) => this.pendingGatewaysListener(gateway, source.bridgeUrl, message));
            return gateway;
          });
          const gatewaysToWaitFor = Math.max(this.pendingGateways.length - this.optionalOpenGateways, 1);
          yield waitForSome(this.pendingGateways.map((bridge) => callForSuccess((_options) => {
            var _a2;
            if (!this.pendingGateways.some((item) => item === bridge)) {
              return bridge.close();
            }
            return bridge.registerSession({
              openingDeadlineMS: (_a2 = options === null || options === void 0 ? void 0 : options.openingDeadlineMS) !== null && _a2 !== void 0 ? _a2 : this.defaultOpeningDeadlineMS,
              signal: _options.signal,
              traceId
            });
          }, {
            attempts: Number.MAX_SAFE_INTEGER,
            delayMs: this.defaultRetryTimeoutMS,
            signal: options === null || options === void 0 ? void 0 : options.signal
          })), gatewaysToWaitFor);
          return;
        } else {
          if (this.gateway) {
            logDebug(`Gateway is already opened, closing previous gateway`);
            yield this.gateway.close();
          }
          this.gateway = new BridgeGateway(this.connectionStorage.storage, this.walletConnectionSource.bridgeUrl, sessionCrypto.sessionId, this.gatewayListener.bind(this), this.gatewayErrorsListener.bind(this), this.analyticsManager);
          return yield this.gateway.registerSession({
            openingDeadlineMS: options === null || options === void 0 ? void 0 : options.openingDeadlineMS,
            signal: options === null || options === void 0 ? void 0 : options.signal,
            traceId
          });
        }
      });
    }
    closeGateways(options) {
      var _a;
      (_a = this.gateway) === null || _a === void 0 ? void 0 : _a.close();
      this.pendingGateways.filter((item) => item !== (options === null || options === void 0 ? void 0 : options.except)).forEach((bridge) => bridge.close());
      this.pendingGateways = [];
    }
  };
  function hasProperty(value, propertyKey) {
    return hasProperties(value, [propertyKey]);
  }
  function hasProperties(value, propertyKeys) {
    if (!value || typeof value !== "object") {
      return false;
    }
    return propertyKeys.every((propertyKey) => propertyKey in value);
  }
  function isJSBridgeWithMetadata(value) {
    try {
      if (!hasProperty(value, "tonconnect") || !hasProperty(value.tonconnect, "walletInfo")) {
        return false;
      }
      return hasProperties(value.tonconnect.walletInfo, [
        "name",
        "app_name",
        "image",
        "about_url",
        "platforms"
      ]);
    } catch (_a) {
      return false;
    }
  }
  var InMemoryStorage = class _InMemoryStorage {
    static getInstance() {
      if (!_InMemoryStorage.instance) {
        _InMemoryStorage.instance = new _InMemoryStorage();
      }
      return _InMemoryStorage.instance;
    }
    constructor() {
      this.storage = {};
    }
    get length() {
      return Object.keys(this.storage).length;
    }
    clear() {
      this.storage = {};
    }
    getItem(key) {
      var _a;
      return (_a = this.storage[key]) !== null && _a !== void 0 ? _a : null;
    }
    key(index) {
      var _a;
      const keys = Object.keys(this.storage);
      if (index < 0 || index >= keys.length) {
        return null;
      }
      return (_a = keys[index]) !== null && _a !== void 0 ? _a : null;
    }
    removeItem(key) {
      delete this.storage[key];
    }
    setItem(key, value) {
      this.storage[key] = value;
    }
  };
  function getWindow() {
    if (typeof window === "undefined") {
      return void 0;
    }
    return window;
  }
  function getDocument() {
    if (typeof document === "undefined") {
      return void 0;
    }
    return document;
  }
  function getWebPageManifest() {
    var _a;
    const origin = (_a = getWindow()) === null || _a === void 0 ? void 0 : _a.location.origin;
    if (origin) {
      return origin + "/tonconnect-manifest.json";
    }
    return "";
  }
  function getOriginWithPath() {
    var _a, _b, _c, _d;
    const origin = (_b = (_a = getWindow()) === null || _a === void 0 ? void 0 : _a.location) === null || _b === void 0 ? void 0 : _b.origin;
    const path = (_d = (_c = getWindow()) === null || _c === void 0 ? void 0 : _c.location) === null || _d === void 0 ? void 0 : _d.pathname;
    if (origin && path) {
      return origin + path;
    }
    return "";
  }
  function tryGetLocalStorage() {
    if (isLocalStorageAvailable()) {
      return localStorage;
    }
    if (isNodeJs()) {
      throw new TonConnectError("`localStorage` is unavailable, but it is required for TonConnect. For more details, see https://github.com/ton-connect/sdk/tree/main/packages/sdk#init-connector");
    }
    return InMemoryStorage.getInstance();
  }
  function isLocalStorageAvailable() {
    try {
      return typeof localStorage !== "undefined";
    } catch (_a) {
      return false;
    }
  }
  function isNodeJs() {
    return typeof process !== "undefined" && process.versions != null && process.versions.node != null;
  }
  function getDomain() {
    try {
      if (typeof window !== "undefined" && window.location) {
        return window.location.hostname;
      } else {
        return null;
      }
    } catch (_a) {
      return null;
    }
  }
  function getWindowEntries() {
    const window2 = getWindow();
    if (!window2) {
      return [];
    }
    try {
      return Object.entries(window2);
    } catch (_a) {
      return [];
    }
  }
  var InjectedProvider = class _InjectedProvider {
    static fromStorage(storage, analyticsManager) {
      return __awaiter(this, void 0, void 0, function* () {
        const connection = yield storage.getInjectedConnection();
        return new _InjectedProvider(storage, connection.jsBridgeKey, analyticsManager);
      });
    }
    static isWalletInjected(injectedWalletKey) {
      return _InjectedProvider.isWindowContainsWallet(this.window, injectedWalletKey);
    }
    static isInsideWalletBrowser(injectedWalletKey) {
      if (_InjectedProvider.isWindowContainsWallet(this.window, injectedWalletKey)) {
        return this.window[injectedWalletKey].tonconnect.isWalletBrowser;
      }
      return false;
    }
    static getCurrentlyInjectedWallets() {
      if (!this.window) {
        return [];
      }
      const windowEntries = getWindowEntries();
      const wallets = windowEntries.filter(([_key, value]) => isJSBridgeWithMetadata(value));
      return wallets.map(([jsBridgeKey, wallet]) => ({
        name: wallet.tonconnect.walletInfo.name,
        appName: wallet.tonconnect.walletInfo.app_name,
        aboutUrl: wallet.tonconnect.walletInfo.about_url,
        imageUrl: wallet.tonconnect.walletInfo.image,
        tondns: wallet.tonconnect.walletInfo.tondns,
        jsBridgeKey,
        injected: true,
        embedded: wallet.tonconnect.isWalletBrowser,
        platforms: wallet.tonconnect.walletInfo.platforms,
        features: wallet.tonconnect.walletInfo.features
      }));
    }
    static isWindowContainsWallet(window2, injectedWalletKey) {
      return !!window2 && injectedWalletKey in window2 && typeof window2[injectedWalletKey] === "object" && "tonconnect" in window2[injectedWalletKey];
    }
    constructor(connectionStorage, injectedWalletKey, analyticsManager) {
      this.connectionStorage = connectionStorage;
      this.injectedWalletKey = injectedWalletKey;
      this.type = "injected";
      this.unsubscribeCallback = null;
      this.listenSubscriptions = false;
      this.listeners = [];
      const window2 = _InjectedProvider.window;
      if (!_InjectedProvider.isWindowContainsWallet(window2, injectedWalletKey)) {
        throw new WalletNotInjectedError();
      }
      this.injectedWallet = window2[injectedWalletKey].tonconnect;
      if (analyticsManager) {
        this.analytics = analyticsManager.scoped({
          bridge_key: injectedWalletKey,
          wallet_app_name: this.injectedWallet.deviceInfo.appName,
          wallet_app_version: this.injectedWallet.deviceInfo.appVersion
        });
      }
    }
    connect(message, options) {
      this._connect(PROTOCOL_VERSION, message, options);
    }
    restoreConnection(options) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b, _c, _d;
        const traceId = (_a = options === null || options === void 0 ? void 0 : options.traceId) !== null && _a !== void 0 ? _a : UUIDv7();
        try {
          logDebug(`Injected Provider restoring connection...`);
          (_b = this.analytics) === null || _b === void 0 ? void 0 : _b.emitJsBridgeCall({
            js_bridge_method: "restoreConnection",
            trace_id: traceId
          });
          const connectEvent = yield this.injectedWallet.restoreConnection();
          (_c = this.analytics) === null || _c === void 0 ? void 0 : _c.emitJsBridgeResponse({
            js_bridge_method: "restoreConnection",
            trace_id: traceId
          });
          logDebug("Injected Provider restoring connection response", connectEvent);
          if (connectEvent.event === "connect") {
            this.makeSubscriptions({ traceId });
            this.listeners.forEach((listener) => listener(Object.assign(Object.assign({}, connectEvent), { traceId })));
          } else {
            yield this.connectionStorage.removeConnection();
          }
        } catch (e) {
          (_d = this.analytics) === null || _d === void 0 ? void 0 : _d.emitJsBridgeError({
            js_bridge_method: "restoreConnection",
            error_message: String(e),
            trace_id: traceId
          });
          yield this.connectionStorage.removeConnection();
          console.error(e);
        }
      });
    }
    closeConnection() {
      if (this.listenSubscriptions) {
        this.injectedWallet.disconnect();
      }
      this.closeAllListeners();
    }
    disconnect(options) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a;
        const traceId = (_a = options === null || options === void 0 ? void 0 : options.traceId) !== null && _a !== void 0 ? _a : UUIDv7();
        return new Promise((resolve) => {
          const onRequestSent = () => {
            this.closeAllListeners();
            this.connectionStorage.removeConnection().then(resolve);
          };
          try {
            this.injectedWallet.disconnect();
            onRequestSent();
          } catch (e) {
            logDebug(e);
            this.sendRequest({
              method: "disconnect",
              params: []
            }, { onRequestSent, traceId });
          }
        });
      });
    }
    closeAllListeners() {
      var _a;
      this.listenSubscriptions = false;
      this.listeners = [];
      (_a = this.unsubscribeCallback) === null || _a === void 0 ? void 0 : _a.call(this);
    }
    listen(eventsCallback) {
      this.listeners.push(eventsCallback);
      return () => this.listeners = this.listeners.filter((listener) => listener !== eventsCallback);
    }
    sendRequest(request, optionsOrOnRequestSent) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b, _c;
        const options = {};
        if (typeof optionsOrOnRequestSent === "function") {
          options.onRequestSent = optionsOrOnRequestSent;
          options.traceId = UUIDv7();
        } else {
          options.onRequestSent = optionsOrOnRequestSent === null || optionsOrOnRequestSent === void 0 ? void 0 : optionsOrOnRequestSent.onRequestSent;
          options.signal = optionsOrOnRequestSent === null || optionsOrOnRequestSent === void 0 ? void 0 : optionsOrOnRequestSent.signal;
          options.attempts = optionsOrOnRequestSent === null || optionsOrOnRequestSent === void 0 ? void 0 : optionsOrOnRequestSent.attempts;
          options.traceId = (_a = optionsOrOnRequestSent === null || optionsOrOnRequestSent === void 0 ? void 0 : optionsOrOnRequestSent.traceId) !== null && _a !== void 0 ? _a : UUIDv7();
        }
        const id = (yield this.connectionStorage.getNextRpcRequestId()).toString();
        yield this.connectionStorage.increaseNextRpcRequestId();
        logDebug("Send injected-bridge request:", Object.assign(Object.assign({}, request), { id }));
        (_b = this.analytics) === null || _b === void 0 ? void 0 : _b.emitJsBridgeCall({
          js_bridge_method: "send"
        });
        const result = this.injectedWallet.send(Object.assign(Object.assign({}, request), { id }));
        result.then((response) => {
          var _a2;
          (_a2 = this.analytics) === null || _a2 === void 0 ? void 0 : _a2.emitJsBridgeResponse({
            js_bridge_method: "send"
          });
          logDebug("Wallet message received:", response);
        }).catch((error) => {
          var _a2;
          (_a2 = this.analytics) === null || _a2 === void 0 ? void 0 : _a2.emitJsBridgeError({
            js_bridge_method: "send",
            error_message: String(error)
          });
        });
        (_c = options === null || options === void 0 ? void 0 : options.onRequestSent) === null || _c === void 0 ? void 0 : _c.call(options);
        return result;
      });
    }
    _connect(protocolVersion, message, options) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b, _c, _d;
        const traceId = (_a = options === null || options === void 0 ? void 0 : options.traceId) !== null && _a !== void 0 ? _a : UUIDv7();
        try {
          logDebug(`Injected Provider connect request: protocolVersion: ${protocolVersion}, message:`, message);
          (_b = this.analytics) === null || _b === void 0 ? void 0 : _b.emitJsBridgeCall({
            js_bridge_method: "connect",
            trace_id: traceId
          });
          const connectEvent = yield this.injectedWallet.connect(protocolVersion, message);
          (_c = this.analytics) === null || _c === void 0 ? void 0 : _c.emitJsBridgeResponse({
            js_bridge_method: "connect"
          });
          logDebug("Injected Provider connect response:", connectEvent);
          if (connectEvent.event === "connect") {
            yield this.updateSession();
            this.makeSubscriptions({ traceId });
          }
          this.listeners.forEach((listener) => listener(Object.assign(Object.assign({}, connectEvent), { traceId })));
        } catch (e) {
          (_d = this.analytics) === null || _d === void 0 ? void 0 : _d.emitJsBridgeError({
            js_bridge_method: "connect",
            error_message: String(e),
            trace_id: traceId
          });
          logDebug("Injected Provider connect error:", e);
          const connectEventError = {
            event: "connect_error",
            payload: {
              code: 0,
              message: e === null || e === void 0 ? void 0 : e.toString()
            }
          };
          this.listeners.forEach((listener) => listener(Object.assign(Object.assign({}, connectEventError), { traceId })));
        }
      });
    }
    makeSubscriptions(options) {
      var _a, _b, _c;
      this.listenSubscriptions = true;
      (_a = this.analytics) === null || _a === void 0 ? void 0 : _a.emitJsBridgeCall({
        js_bridge_method: "listen",
        trace_id: options.traceId
      });
      try {
        this.unsubscribeCallback = this.injectedWallet.listen((e) => {
          var _a2;
          const traceId = (_a2 = e.traceId) !== null && _a2 !== void 0 ? _a2 : UUIDv7();
          logDebug("Wallet message received:", e);
          if (this.listenSubscriptions) {
            this.listeners.forEach((listener) => listener(Object.assign(Object.assign({}, e), { traceId })));
          }
          if (e.event === "disconnect") {
            this.disconnect({ traceId });
          }
        });
        (_b = this.analytics) === null || _b === void 0 ? void 0 : _b.emitJsBridgeResponse({
          js_bridge_method: "listen",
          trace_id: options.traceId
        });
      } catch (err) {
        (_c = this.analytics) === null || _c === void 0 ? void 0 : _c.emitJsBridgeError({
          js_bridge_method: "listen",
          error_message: String(err),
          trace_id: options.traceId
        });
        throw err;
      }
    }
    updateSession() {
      return this.connectionStorage.storeConnection({
        type: "injected",
        jsBridgeKey: this.injectedWalletKey,
        nextRpcRequestId: 0
      });
    }
  };
  InjectedProvider.window = getWindow();
  var BridgeConnectionStorage = class {
    constructor(storage, walletsListManager) {
      this.storage = storage;
      this.walletsListManager = walletsListManager;
      this.storeKey = "ton-connect-storage_bridge-connection";
    }
    storeConnection(connection) {
      return __awaiter(this, void 0, void 0, function* () {
        if (connection.type === "injected" || connection.type === "wallet-connect") {
          return this.storage.setItem(this.storeKey, JSON.stringify(connection));
        }
        if (!isPendingConnectionHttp(connection)) {
          const rawSession = {
            sessionKeyPair: connection.session.sessionCrypto.stringifyKeypair(),
            walletPublicKey: connection.session.walletPublicKey,
            bridgeUrl: connection.session.bridgeUrl
          };
          const rawConnection2 = {
            type: "http",
            connectEvent: connection.connectEvent,
            session: rawSession,
            lastWalletEventId: connection.lastWalletEventId,
            nextRpcRequestId: connection.nextRpcRequestId
          };
          return this.storage.setItem(this.storeKey, JSON.stringify(rawConnection2));
        }
        const rawConnection = {
          type: "http",
          connectionSource: connection.connectionSource,
          sessionCrypto: connection.sessionCrypto.stringifyKeypair(),
          createdAt: Date.now()
        };
        return this.storage.setItem(this.storeKey, JSON.stringify(rawConnection));
      });
    }
    removeConnection() {
      return __awaiter(this, void 0, void 0, function* () {
        return this.storage.removeItem(this.storeKey);
      });
    }
    getConnection() {
      return __awaiter(this, void 0, void 0, function* () {
        try {
          const stored = yield this.storage.getItem(this.storeKey);
          if (!stored) {
            return null;
          }
          const connection = JSON.parse(stored);
          if (connection.type === "injected" || connection.type === "wallet-connect") {
            return connection;
          }
          if (!isPendingConnectionHttpRaw(connection)) {
            const sessionCrypto = new SessionCrypto(connection.session.sessionKeyPair);
            return yield this.actualizeBridgeConnection({
              type: "http",
              connectEvent: connection.connectEvent,
              lastWalletEventId: connection.lastWalletEventId,
              nextRpcRequestId: connection.nextRpcRequestId,
              session: {
                sessionCrypto,
                bridgeUrl: connection.session.bridgeUrl,
                walletPublicKey: connection.session.walletPublicKey
              }
            });
          }
          if (isExpiredPendingConnectionHttpRaw(connection)) {
            yield this.removeConnection();
            return null;
          }
          return {
            type: "http",
            sessionCrypto: new SessionCrypto(connection.sessionCrypto),
            connectionSource: connection.connectionSource
          };
        } catch (err) {
          logDebug("Error retrieving connection", err);
          return null;
        }
      });
    }
    getHttpConnection() {
      return __awaiter(this, void 0, void 0, function* () {
        const connection = yield this.getConnection();
        if (!connection) {
          throw new TonConnectError("Trying to read HTTP connection source while nothing is stored");
        }
        if (connection.type !== "http") {
          throw new TonConnectError(`Trying to read HTTP connection source while ${connection.type} connection is stored`);
        }
        return connection;
      });
    }
    getHttpPendingConnection() {
      return __awaiter(this, void 0, void 0, function* () {
        const connection = yield this.getConnection();
        if (!connection) {
          throw new TonConnectError("Trying to read HTTP connection source while nothing is stored");
        }
        if (connection.type !== "http") {
          throw new TonConnectError(`Trying to read HTTP connection source while ${connection.type} connection is stored`);
        }
        if (!isPendingConnectionHttp(connection)) {
          throw new TonConnectError("Trying to read HTTP-pending connection while http connection is stored");
        }
        return connection;
      });
    }
    getInjectedConnection() {
      return __awaiter(this, void 0, void 0, function* () {
        const connection = yield this.getConnection();
        if (!connection) {
          throw new TonConnectError("Trying to read Injected bridge connection source while nothing is stored");
        }
        if ((connection === null || connection === void 0 ? void 0 : connection.type) !== "injected") {
          throw new TonConnectError(`Trying to read Injected bridge connection source while ${connection.type} connection is stored`);
        }
        return connection;
      });
    }
    getWalletConnectConnection() {
      return __awaiter(this, void 0, void 0, function* () {
        const connection = yield this.getConnection();
        if (!connection) {
          throw new TonConnectError("Trying to read wallet connect bridge connection source while nothing is stored");
        }
        if ((connection === null || connection === void 0 ? void 0 : connection.type) !== "wallet-connect") {
          throw new TonConnectError(`Trying to read wallet connect bridge connection source while ${connection.type} connection is stored`);
        }
        return connection;
      });
    }
    storedConnectionType() {
      return __awaiter(this, void 0, void 0, function* () {
        const stored = yield this.storage.getItem(this.storeKey);
        if (!stored) {
          return null;
        }
        const connection = JSON.parse(stored);
        return connection.type;
      });
    }
    storeLastWalletEventId(id) {
      return __awaiter(this, void 0, void 0, function* () {
        const connection = yield this.getConnection();
        if (connection && connection.type === "http" && !isPendingConnectionHttp(connection)) {
          connection.lastWalletEventId = id;
          return this.storeConnection(connection);
        }
      });
    }
    getLastWalletEventId() {
      return __awaiter(this, void 0, void 0, function* () {
        const connection = yield this.getConnection();
        if (connection && "lastWalletEventId" in connection) {
          return connection.lastWalletEventId;
        }
        return void 0;
      });
    }
    increaseNextRpcRequestId() {
      return __awaiter(this, void 0, void 0, function* () {
        const connection = yield this.getConnection();
        if (connection && "nextRpcRequestId" in connection) {
          const lastId = connection.nextRpcRequestId || 0;
          connection.nextRpcRequestId = lastId + 1;
          return this.storeConnection(connection);
        }
      });
    }
    getNextRpcRequestId() {
      return __awaiter(this, void 0, void 0, function* () {
        const connection = yield this.getConnection();
        if (connection && "nextRpcRequestId" in connection) {
          return connection.nextRpcRequestId || 0;
        }
        return 0;
      });
    }
    actualizeBridgeConnection(connection) {
      return __awaiter(this, void 0, void 0, function* () {
        try {
          const appName = connection.connectEvent.payload.device.appName;
          const wallet = yield this.walletsListManager.getRemoteWallet(appName);
          if (wallet.bridgeUrl === connection.session.bridgeUrl) {
            return connection;
          }
          const actualizedConnection = Object.assign(Object.assign({}, connection), { session: Object.assign(Object.assign({}, connection.session), { bridgeUrl: wallet.bridgeUrl }) });
          yield this.storeConnection(actualizedConnection);
          return actualizedConnection;
        } catch (error) {
          logDebug("Failed to actualize bridge connection", error);
          return connection;
        }
      });
    }
  };
  var DefaultStorage = class {
    constructor() {
      this.localStorage = tryGetLocalStorage();
    }
    getItem(key) {
      return __awaiter(this, void 0, void 0, function* () {
        return this.localStorage.getItem(key);
      });
    }
    removeItem(key) {
      return __awaiter(this, void 0, void 0, function* () {
        this.localStorage.removeItem(key);
      });
    }
    setItem(key, value) {
      return __awaiter(this, void 0, void 0, function* () {
        this.localStorage.setItem(key, value);
      });
    }
  };
  function isWalletInfoCurrentlyInjected(value) {
    return isWalletInfoInjectable(value) && value.injected;
  }
  function isWalletInfoCurrentlyEmbedded(value) {
    return isWalletInfoCurrentlyInjected(value) && value.embedded;
  }
  function isWalletInfoInjectable(value) {
    return "jsBridgeKey" in value;
  }
  function isWalletInfoRemote(value) {
    return "bridgeUrl" in value;
  }
  function isWalletInfoInjected(value) {
    return "jsBridgeKey" in value;
  }
  var FALLBACK_WALLETS_LIST = [
    {
      app_name: "telegram-wallet",
      name: "Wallet",
      image: "https://wallet.tg/images/logo-288.png",
      about_url: "https://wallet.tg/",
      universal_url: "https://t.me/wallet?attach=wallet",
      bridge: [
        {
          type: "sse",
          url: "https://walletbot.me/tonconnect-bridge/bridge"
        }
      ],
      platforms: ["ios", "android", "macos", "windows", "linux"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 255,
          extraCurrencySupported: true
        },
        {
          name: "SignData",
          types: ["text", "binary", "cell"]
        }
      ]
    },
    {
      app_name: "tonkeeper",
      name: "Tonkeeper",
      image: "https://tonkeeper.com/assets/tonconnect-icon.png",
      tondns: "tonkeeper.ton",
      about_url: "https://tonkeeper.com",
      universal_url: "https://app.tonkeeper.com/ton-connect",
      deepLink: "tonkeeper-tc://",
      bridge: [
        {
          type: "sse",
          url: "https://bridge.tonapi.io/bridge"
        },
        {
          type: "js",
          key: "tonkeeper"
        }
      ],
      platforms: ["ios", "android", "chrome", "firefox", "macos"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 255,
          extraCurrencySupported: true
        },
        {
          name: "SignData",
          types: ["text", "binary", "cell"]
        }
      ]
    },
    {
      app_name: "mytonwallet",
      name: "MyTonWallet",
      image: "https://static.mytonwallet.io/icon-256.png",
      about_url: "https://mytonwallet.io",
      universal_url: "https://connect.mytonwallet.org",
      deepLink: "mytonwallet-tc://",
      bridge: [
        {
          type: "js",
          key: "mytonwallet"
        },
        {
          type: "sse",
          url: "https://tonconnectbridge.mytonwallet.org/bridge/"
        }
      ],
      platforms: ["chrome", "windows", "macos", "linux", "ios", "android", "firefox"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 255,
          extraCurrencySupported: false
        },
        {
          name: "SignData",
          types: ["text", "binary", "cell"]
        }
      ]
    },
    {
      app_name: "tonhub",
      name: "Tonhub",
      image: "https://tonhub.com/tonconnect_logo.png",
      about_url: "https://tonhub.com",
      universal_url: "https://tonhub.com/ton-connect",
      bridge: [
        {
          type: "js",
          key: "tonhub"
        },
        {
          type: "sse",
          url: "https://connect.tonhubapi.com/tonconnect"
        }
      ],
      platforms: ["ios", "android"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 255,
          extraCurrencySupported: true
        },
        {
          name: "SignData",
          types: ["text", "binary", "cell"]
        }
      ]
    },
    {
      app_name: "bitgetTonWallet",
      name: "Bitget Wallet",
      image: "https://raw.githubusercontent.com/bitgetwallet/download/refs/heads/main/logo/png/bitget_wallet_logo_288_mini.png",
      about_url: "https://web3.bitget.com",
      deepLink: "bitkeep://",
      bridge: [
        {
          type: "js",
          key: "bitgetTonWallet"
        },
        {
          type: "sse",
          url: "https://ton-connect-bridge.bgwapi.io/bridge"
        }
      ],
      platforms: ["ios", "android", "chrome"],
      universal_url: "https://bkcode.vip/ton-connect",
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "okxMiniWallet",
      name: "OKX Mini Wallet",
      image: "https://static.okx.com/cdn/assets/imgs/2411/8BE1A4A434D8F58A.png",
      about_url: "https://www.okx.com/web3",
      universal_url: "https://t.me/OKX_WALLET_BOT?attach=wallet",
      bridge: [
        {
          type: "sse",
          url: "https://www.okx.com/tonbridge/discover/rpc/bridge"
        }
      ],
      platforms: ["ios", "android", "macos", "windows", "linux"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "binanceWeb3TonWallet",
      name: "Binance Wallet",
      image: "https://public.bnbstatic.com/static/binance-w3w/ton-provider/binancew3w.png",
      about_url: "https://www.binance.com/en/web3wallet",
      deepLink: "bnc://app.binance.com/cedefi/ton-connect",
      bridge: [
        {
          type: "js",
          key: "binancew3w"
        },
        {
          type: "sse",
          url: "https://wallet.binance.com/tonbridge/bridge"
        }
      ],
      platforms: ["ios", "android", "macos", "windows", "linux"],
      universal_url: "https://app.binance.com/cedefi/ton-connect",
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "fintopio-tg",
      name: "Fintopio",
      image: "https://raw.githubusercontent.com/fintopio/ton-pub/refs/heads/main/logos/tonconnect-icon.png",
      about_url: "https://fintopio.com",
      universal_url: "https://t.me/fintopio?attach=wallet",
      bridge: [
        {
          type: "sse",
          url: "https://wallet-bridge.fintopio.com/bridge"
        }
      ],
      platforms: ["ios", "android", "macos", "windows", "linux"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "okxTonWallet",
      name: "OKX Wallet",
      image: "https://static.okx.com/cdn/assets/imgs/247/58E63FEA47A2B7D7.png",
      about_url: "https://www.okx.com/web3",
      universal_url: "https://www.okx.com/download?appendQuery=true&deeplink=okx://web3/wallet/tonconnect",
      bridge: [
        {
          type: "js",
          key: "okxTonWallet"
        },
        {
          type: "sse",
          url: "https://www.okx.com/tonbridge/discover/rpc/bridge"
        }
      ],
      platforms: ["chrome", "safari", "firefox", "ios", "android"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "hot",
      name: "HOT",
      image: "https://raw.githubusercontent.com/hot-dao/media/main/logo.png",
      about_url: "https://hot-labs.org/",
      universal_url: "https://t.me/herewalletbot?attach=wallet",
      bridge: [
        {
          type: "sse",
          url: "https://sse-bridge.hot-labs.org"
        },
        {
          type: "js",
          key: "hotWallet"
        }
      ],
      platforms: ["ios", "android", "macos", "windows", "linux"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "bybitTonWallet",
      name: "Bybit Wallet",
      image: "https://raw.githubusercontent.com/bybit-web3/bybit-web3.github.io/main/docs/images/bybit-logo.png",
      about_url: "https://www.bybit.com/web3",
      universal_url: "https://app.bybit.com/ton-connect",
      deepLink: "bybitapp://",
      bridge: [
        {
          type: "js",
          key: "bybitTonWallet"
        },
        {
          type: "sse",
          url: "https://api-node.bybit.com/spot/api/web3/bridge/ton/bridge"
        }
      ],
      platforms: ["ios", "android", "chrome"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "dewallet",
      name: "DeWallet",
      image: "https://raw.githubusercontent.com/delab-team/manifests-images/main/WalletAvatar.png",
      about_url: "https://delabwallet.com",
      universal_url: "https://t.me/dewallet?attach=wallet",
      bridge: [
        {
          type: "sse",
          url: "https://bridge.dewallet.pro/bridge"
        }
      ],
      platforms: ["ios", "android", "macos", "windows", "linux"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "safepalwallet",
      name: "SafePal",
      image: "https://s.pvcliping.com/web/public_image/SafePal_x288.png",
      tondns: "",
      about_url: "https://www.safepal.com",
      universal_url: "https://link.safepal.io/ton-connect",
      deepLink: "safepal-tc://",
      bridge: [
        {
          type: "sse",
          url: "https://ton-bridge.safepal.com/tonbridge/v1/bridge"
        },
        {
          type: "js",
          key: "safepalwallet"
        }
      ],
      platforms: ["ios", "android", "chrome", "firefox"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 1,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "GateWallet",
      name: "GateWallet",
      image: "https://img.gatedataimg.com/prd-ordinal-imgs/036f07bb8730716e/gateio-0925.png",
      about_url: "https://www.gate.io/",
      bridge: [
        {
          type: "js",
          key: "gatetonwallet"
        },
        {
          type: "sse",
          url: "https://dapp.gateio.services/tonbridge_api/bridge/v1"
        }
      ],
      platforms: ["ios", "android"],
      universal_url: "https://gate.onelink.me/Hls0/web3?gate_web3_wallet_universal_type=ton_connect",
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "openmask",
      name: "OpenMask",
      image: "https://raw.githubusercontent.com/OpenProduct/openmask-extension/main/public/openmask-logo-288.png",
      about_url: "https://www.openmask.app/",
      bridge: [
        {
          type: "js",
          key: "openmask"
        }
      ],
      platforms: ["chrome"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "BitgetWeb3",
      name: "BitgetWeb3",
      image: "https://img.bitgetimg.com/image/third/1731638059795.png",
      about_url: "\u200Bhttps://www.bitget.com",
      universal_url: "https://t.me/BitgetOfficialBot?attach=wallet",
      bridge: [
        {
          type: "sse",
          url: "https://ton-connect-bridge.bgwapi.io/bridge"
        }
      ],
      platforms: ["ios", "android", "windows", "macos", "linux"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "xtonwallet",
      name: "XTONWallet",
      image: "https://xtonwallet.com/assets/img/icon-256-back.png",
      about_url: "https://xtonwallet.com",
      bridge: [
        {
          type: "js",
          key: "xtonwallet"
        }
      ],
      platforms: ["chrome", "firefox"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 1,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "tonwallet",
      name: "TON Wallet",
      image: "https://wallet.ton.org/assets/ui/qr-logo.png",
      about_url: "https://chrome.google.com/webstore/detail/ton-wallet/nphplpgoakhhjchkkhmiggakijnkhfnd",
      bridge: [
        {
          type: "js",
          key: "tonwallet"
        }
      ],
      platforms: ["chrome"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "bitgetWalletLite",
      name: "Bitget Wallet Lite",
      image: "https://raw.githubusercontent.com/bitgetwallet/download/refs/heads/main/logo/png/bitget_wallet_lite_logo_288.png",
      about_url: "https://web3.bitget.com",
      universal_url: "https://t.me/BitgetWallet_TGBot?attach=wallet",
      bridge: [
        {
          type: "sse",
          url: "https://ton-connect-bridge.bgwapi.io/bridge"
        }
      ],
      platforms: ["ios", "android", "macos", "windows", "linux"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 255,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "tomoWallet",
      name: "Tomo Wallet",
      image: "https://pub.tomo.inc/logo.png",
      about_url: "https://www.tomo.inc/",
      universal_url: "https://t.me/tomowalletbot?attach=wallet",
      bridge: [
        {
          type: "sse",
          url: "https://go-bridge.tomo.inc/bridge"
        }
      ],
      platforms: ["ios", "android", "macos", "windows", "linux"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "miraiapp-tg",
      name: "Mirai Mini App",
      image: "https://cdn.mirailabs.co/miraihub/miraiapp-tg-icon-288.png",
      about_url: "https://mirai.app",
      universal_url: "https://t.me/MiraiAppBot?attach=wallet",
      bridge: [
        {
          type: "sse",
          url: "https://bridge.mirai.app"
        }
      ],
      platforms: ["ios", "android", "macos", "windows", "linux"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 255,
          extraCurrencySupported: false
        },
        {
          name: "SignData",
          types: ["text", "binary", "cell"]
        }
      ]
    },
    {
      app_name: "Architec.ton",
      name: "Architec.ton",
      image: "https://raw.githubusercontent.com/Architec-Ton/wallet-tma/refs/heads/dev/public/images/arcwallet_logo.png",
      about_url: "https://architecton.tech",
      universal_url: "https://t.me/architec_ton_bot?attach=wallet",
      bridge: [
        {
          type: "sse",
          url: "https://tc.architecton.su/bridge"
        }
      ],
      platforms: ["ios", "android", "macos", "windows", "linux"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 255,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "tokenpocket",
      name: "TokenPocket",
      image: "https://hk.tpstatic.net/logo/tokenpocket.png",
      about_url: "https://www.tokenpocket.pro",
      universal_url: "https://tp-lab.tptool.pro/ton-connect/",
      bridge: [
        {
          type: "js",
          key: "tokenpocket"
        },
        {
          type: "sse",
          url: "https://ton-connect.mytokenpocket.vip/bridge"
        }
      ],
      platforms: ["ios", "android"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "uxuyWallet",
      name: "UXUY Wallet",
      image: "https://chain-cdn.uxuy.com/logo/square_288.png",
      about_url: "https://docs.uxuy.com",
      universal_url: "https://t.me/UXUYbot?attach=wallet",
      bridge: [
        {
          type: "sse",
          url: "https://bridge.uxuy.me/bridge"
        }
      ],
      platforms: ["ios", "android", "macos", "windows", "linux"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "tonkeeper-pro",
      name: "Tonkeeper Pro",
      image: "https://tonkeeper.com/assets/tonconnect-icon-pro.png",
      tondns: "tonkeeper.ton",
      about_url: "https://tonkeeper.com/pro",
      universal_url: "https://app.tonkeeper.com/pro/ton-connect",
      deepLink: "tonkeeper-pro-tc://",
      bridge: [
        {
          type: "sse",
          url: "https://bridge.tonapi.io/bridge"
        }
      ],
      platforms: ["ios", "macos", "windows", "linux"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 255,
          extraCurrencySupported: true
        },
        {
          name: "SignData",
          types: ["text", "binary", "cell"]
        }
      ]
    },
    {
      app_name: "nicegramWallet",
      name: "Nicegram Wallet",
      image: "https://static.nicegram.app/icon.png",
      about_url: "https://nicegram.app",
      universal_url: "https://nicegram.app/tc",
      deepLink: "nicegram-tc://",
      bridge: [
        {
          type: "sse",
          url: "https://tc.nicegram.app/bridge"
        },
        {
          type: "js",
          key: "nicegramWallet"
        }
      ],
      platforms: ["ios", "android"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 255,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "echoooTonWallet",
      name: "EchoooWallet",
      image: "https://cdn.echooo.xyz/front-end/source/images/logo/echooo-ton.png",
      about_url: "https://www.echooo.xyz",
      universal_url: "https://www.echooo.xyz/ton-connect",
      deepLink: "echooo://",
      bridge: [
        {
          type: "js",
          key: "echoooTonWallet"
        },
        {
          type: "sse",
          url: "https://ton-connect-bridge.echooo.link/bridge"
        }
      ],
      platforms: ["ios", "android"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 255,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "blitzwallet",
      name: "BLITZ wallet",
      image: "https://blitzwallet.cfd/wallet/public/logo.png",
      about_url: "https://blitzwallet.cfd",
      universal_url: "https://t.me/blitz_wallet_bot?attach=wallet",
      bridge: [
        {
          type: "sse",
          url: "https://blitzwallet.cfd/bridge/"
        }
      ],
      platforms: ["ios", "android", "macos", "windows", "linux"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "koloWeb3Wallet",
      name: "Kolo",
      image: "https://raw.githubusercontent.com/onidev1/tc-assets/refs/heads/main/kolo_logo_288.png",
      about_url: "https://kolo.xyz",
      universal_url: "https://t.me/kolo?attach=wallet",
      bridge: [
        {
          type: "sse",
          url: "https://web3-bridge.kolo.in/bridge"
        }
      ],
      platforms: ["ios", "android", "macos", "windows", "linux"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 255,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "imToken",
      name: "imToken",
      image: "https://aws-v2-cdn.token.im/orbit/token-v2/icons/logo-ton-connect.png",
      about_url: "https://token.im",
      universal_url: "https://connect.token.im/link/ton-connect",
      deepLink: "imtokenv2://link/ton-connect",
      bridge: [
        {
          type: "sse",
          url: "https://connect.token.im/tonbridge"
        },
        {
          type: "js",
          key: "imToken"
        }
      ],
      platforms: ["ios", "android"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 255,
          extraCurrencySupported: false
        }
      ]
    },
    {
      app_name: "cactuslink",
      name: "Cactus Link",
      image: "https://downloads.mycactus.com/288_cactus_link.png",
      about_url: "https://www.mycactus.com/defi-connector",
      bridge: [
        {
          type: "js",
          key: "cactuslink_ton"
        }
      ],
      platforms: ["chrome"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        },
        {
          name: "SignData",
          types: ["text", "binary"]
        }
      ]
    },
    {
      app_name: "onekey",
      name: "OneKey",
      image: "https://uni.onekey-asset.com/static/logo/onekey-x288.png",
      about_url: "https://onekey.so",
      bridge: [
        {
          type: "js",
          key: "onekeyTonWallet"
        }
      ],
      platforms: ["chrome"],
      features: [
        {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        }
      ]
    }
  ];
  var qaModeEnabled = false;
  var bannerObserver = null;
  function enableQaMode() {
    qaModeEnabled = true;
    console.warn("\u{1F6A8} QA Mode enabled - validation is disabled. This is unsafe for production!");
    showQaModeBanner();
    startBannerObserver();
    addQaModeStyles();
  }
  function isQaModeEnabled() {
    return qaModeEnabled;
  }
  function showQaModeBanner() {
    if (typeof window === "undefined")
      return;
    const existingBanner = document.getElementById("ton-connect-qa-banner");
    if (existingBanner)
      return;
    const banner = document.createElement("div");
    banner.id = "ton-connect-qa-banner";
    banner.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        background: linear-gradient(90deg, #ff6b6b, #ff8e8e);
        color: white;
        padding: 12px 20px;
        text-align: center;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        font-weight: 600;
        font-size: 14px;
        z-index: 999999;
        box-shadow: 0 2px 8px rgba(0,0,0,0.2);
        animation: slideDown 0.3s ease-out;
        user-select: none;
        pointer-events: none;
    `;
    banner.innerHTML = `
        \u{1F6A8} QA Mode Active - Validation Disabled (Unsafe for Production)
    `;
    const style = document.createElement("style");
    style.textContent = `
        @keyframes slideDown {
            from { transform: translateY(-100%); }
            to { transform: translateY(0); }
        }
    `;
    document.head.appendChild(style);
    document.body.appendChild(banner);
    addQaModeStyles();
  }
  function addQaModeStyles() {
    if (typeof window === "undefined")
      return;
    const existingStyle = document.getElementById("ton-connect-qa-mode-styles");
    if (existingStyle)
      return;
    const style = document.createElement("style");
    style.id = "ton-connect-qa-mode-styles";
    style.textContent = `
        body.qa-mode-active {
            padding-top: 48px !important;
        }
        
        body.qa-mode-active header {
            margin-top: 48px !important;
        }
        
        body.qa-mode-active .qa-mode-control {
            top: 128px !important;
        }
    `;
    document.head.appendChild(style);
    document.body.classList.add("qa-mode-active");
  }
  function startBannerObserver() {
    if (typeof window === "undefined" || bannerObserver)
      return;
    bannerObserver = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === "childList") {
          mutation.removedNodes.forEach((node) => {
            if (node.nodeType === Node.ELEMENT_NODE) {
              const element = node;
              if (element.id === "ton-connect-qa-banner" && qaModeEnabled) {
                console.warn("QA Mode banner was removed, restoring...");
                setTimeout(() => showQaModeBanner(), 100);
              } else if (element.id === "ton-connect-qa-mode-styles" && qaModeEnabled) {
                console.warn("QA Mode styles were removed, restoring...");
                setTimeout(() => addQaModeStyles(), 100);
              }
            }
          });
        }
      });
    });
    bannerObserver.observe(document.body, {
      childList: true,
      subtree: false
    });
    bannerObserver.observe(document.head, {
      childList: true,
      subtree: false
    });
  }
  var WalletsListManager = class {
    constructor(options) {
      var _a;
      this.walletsListDTOCache = null;
      this.walletsListDTOCacheCreationTimestamp = null;
      if (isQaModeEnabled()) {
        this.walletsListSource = "https://raw.githubusercontent.com/ton-connect/wallets-list-staging/refs/heads/main/wallets-v2.json";
      } else {
        this.walletsListSource = (_a = options === null || options === void 0 ? void 0 : options.walletsListSource) !== null && _a !== void 0 ? _a : "https://config.ton.org/wallets-v2.json";
      }
      this.cacheTTLMs = options === null || options === void 0 ? void 0 : options.cacheTTLMs;
      this.onDownloadDurationMeasured = options === null || options === void 0 ? void 0 : options.onDownloadDurationMeasured;
    }
    getWallets() {
      return __awaiter(this, void 0, void 0, function* () {
        const [walletsListDTO, currentlyInjectedWallets] = yield Promise.all([
          this.fetchWalletsListDTO(),
          this.getCurrentlyInjectedWallets()
        ]);
        return this.mergeWalletsLists(this.walletConfigDTOListToWalletConfigList(walletsListDTO), currentlyInjectedWallets);
      });
    }
    getEmbeddedWallet() {
      return __awaiter(this, void 0, void 0, function* () {
        const walletsList = yield this.getWallets();
        const embeddedWallets = walletsList.filter(isWalletInfoCurrentlyEmbedded);
        return embeddedWallets.length === 1 ? embeddedWallets[0] : null;
      });
    }
    fetchWalletsListDTO() {
      return __awaiter(this, void 0, void 0, function* () {
        if (this.cacheTTLMs && this.walletsListDTOCacheCreationTimestamp && Date.now() > this.walletsListDTOCacheCreationTimestamp + this.cacheTTLMs) {
          this.walletsListDTOCache = null;
        }
        if (!this.walletsListDTOCache) {
          this.walletsListDTOCache = this.fetchWalletsListFromSource();
          this.walletsListDTOCache.then(() => {
            this.walletsListDTOCacheCreationTimestamp = Date.now();
          }).catch(() => {
            this.walletsListDTOCache = null;
            this.walletsListDTOCacheCreationTimestamp = null;
          });
        }
        return this.walletsListDTOCache;
      });
    }
    getRemoteWallet(appName) {
      return __awaiter(this, void 0, void 0, function* () {
        const walletsList = yield this.getWallets();
        const wallet = walletsList.find((wallet2) => wallet2.appName === appName);
        if (!wallet) {
          throw new TonConnectError(`Wallet info not found for appName: "${appName}"`);
        }
        if (!isWalletInfoRemote(wallet)) {
          throw new TonConnectError(`Wallet "${appName}" is not remote`);
        }
        return wallet;
      });
    }
    fetchWalletsListFromSource() {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b;
        let walletsList = [];
        const startTime = performance.now();
        try {
          const walletsResponse = yield fetch(this.walletsListSource);
          walletsList = yield walletsResponse.json();
          if (!Array.isArray(walletsList)) {
            throw new FetchWalletsError("Wrong wallets list format, wallets list must be an array.");
          }
          const wrongFormatWallets = walletsList.filter((wallet) => !this.isCorrectWalletConfigDTO(wallet));
          if (wrongFormatWallets.length) {
            logError(`Wallet(s) ${wrongFormatWallets.map((wallet) => (wallet === null || wallet === void 0 ? void 0 : wallet.name) || "unknown").join(", ")} config format is wrong. They were removed from the wallets list.`);
            walletsList = walletsList.filter((wallet) => this.isCorrectWalletConfigDTO(wallet));
          }
          const endTime = performance.now();
          const duration = Math.round(endTime - startTime);
          (_a = this.onDownloadDurationMeasured) === null || _a === void 0 ? void 0 : _a.call(this, duration);
        } catch (e) {
          logError(e);
          walletsList = FALLBACK_WALLETS_LIST;
          (_b = this.onDownloadDurationMeasured) === null || _b === void 0 ? void 0 : _b.call(this, void 0);
        }
        return walletsList;
      });
    }
    getCurrentlyInjectedWallets() {
      if (!isQaModeEnabled()) {
        return [];
      }
      try {
        return InjectedProvider.getCurrentlyInjectedWallets();
      } catch (e) {
        logError(e);
        return [];
      }
    }
    walletConfigDTOListToWalletConfigList(walletConfigDTO) {
      return walletConfigDTO.map((walletConfigDTO2) => {
        const walletConfig = {
          name: walletConfigDTO2.name,
          appName: walletConfigDTO2.app_name,
          imageUrl: walletConfigDTO2.image,
          aboutUrl: walletConfigDTO2.about_url,
          tondns: walletConfigDTO2.tondns,
          platforms: walletConfigDTO2.platforms,
          features: walletConfigDTO2.features
        };
        walletConfigDTO2.bridge.forEach((bridge) => {
          if (bridge.type === "sse") {
            walletConfig.bridgeUrl = bridge.url;
            walletConfig.universalLink = walletConfigDTO2.universal_url;
            walletConfig.deepLink = walletConfigDTO2.deepLink;
          }
          if (bridge.type === "js") {
            const jsBridgeKey = bridge.key;
            walletConfig.jsBridgeKey = jsBridgeKey;
            walletConfig.injected = InjectedProvider.isWalletInjected(jsBridgeKey);
            walletConfig.embedded = InjectedProvider.isInsideWalletBrowser(jsBridgeKey);
          }
        });
        return walletConfig;
      });
    }
    mergeWalletsLists(list1, list2) {
      const names = new Set(list1.concat(list2).map((item) => item.name));
      return [...names.values()].map((name) => {
        const list1Item = list1.find((item) => item.name === name);
        const list2Item = list2.find((item) => item.name === name);
        return Object.assign(Object.assign({}, list1Item && Object.assign({}, list1Item)), list2Item && Object.assign({}, list2Item));
      });
    }
    // eslint-disable-next-line complexity
    isCorrectWalletConfigDTO(value) {
      if (!value || !(typeof value === "object")) {
        return false;
      }
      const containsName = "name" in value;
      const containsAppName = "app_name" in value;
      const containsImage = "image" in value;
      const containsAbout = "about_url" in value;
      const containsPlatforms = "platforms" in value;
      if (!containsName || !containsImage || !containsAbout || !containsPlatforms || !containsAppName) {
        return false;
      }
      if (!value.platforms || !Array.isArray(value.platforms) || !value.platforms.length) {
        return false;
      }
      if (!("bridge" in value) || !Array.isArray(value.bridge) || !value.bridge.length) {
        return false;
      }
      const bridge = value.bridge;
      if (bridge.some((item) => !item || typeof item !== "object" || !("type" in item))) {
        return false;
      }
      const sseBridge = bridge.find((item) => item.type === "sse");
      if (sseBridge) {
        if (!(typeof sseBridge === "object" && "url" in sseBridge) || !sseBridge.url || !value.universal_url) {
          return false;
        }
      }
      const jsBridge = bridge.find((item) => item.type === "js");
      if (jsBridge) {
        if (typeof jsBridge !== "object" || !("key" in jsBridge) || !jsBridge.key) {
          return false;
        }
      }
      return true;
    }
  };
  function checkSendTransactionSupport(features, options) {
    var _a;
    const supportsDeprecatedSendTransactionFeature = features.includes("SendTransaction");
    const sendTransactionFeature = findFeature(features, "SendTransaction");
    const requiredFeature = {
      minMessages: options.requiredMessagesNumber,
      extraCurrencyRequired: options.requireExtraCurrencies,
      itemTypes: options.requiredItemTypes
    };
    if (!supportsDeprecatedSendTransactionFeature && !sendTransactionFeature) {
      throw new WalletNotSupportFeatureError("Wallet doesn't support SendTransaction feature.", {
        cause: { requiredFeature: { featureName: "SendTransaction", value: requiredFeature } }
      });
    }
    if (options.requireExtraCurrencies) {
      if (!sendTransactionFeature || !sendTransactionFeature.extraCurrencySupported) {
        throw new WalletNotSupportFeatureError(`Wallet is not able to handle such SendTransaction request. Extra currencies support is required.`, {
          cause: {
            requiredFeature: { featureName: "SendTransaction", value: requiredFeature }
          }
        });
      }
    }
    if ((_a = options.requiredItemTypes) === null || _a === void 0 ? void 0 : _a.length) {
      if (!(sendTransactionFeature === null || sendTransactionFeature === void 0 ? void 0 : sendTransactionFeature.itemTypes)) {
        throw new WalletNotSupportFeatureError(`Wallet doesn't support structured items in SendTransaction.`, {
          cause: {
            requiredFeature: { featureName: "SendTransaction", value: requiredFeature }
          }
        });
      }
      const unsupportedTypes = options.requiredItemTypes.filter((t) => !sendTransactionFeature.itemTypes.includes(t));
      if (unsupportedTypes.length) {
        throw new WalletNotSupportFeatureError(`Wallet doesn't support item types: ${unsupportedTypes.join(", ")} in SendTransaction.`, {
          cause: {
            requiredFeature: { featureName: "SendTransaction", value: requiredFeature }
          }
        });
      }
    }
    if (sendTransactionFeature && sendTransactionFeature.maxMessages !== void 0) {
      if (sendTransactionFeature.maxMessages < options.requiredMessagesNumber) {
        throw new WalletNotSupportFeatureError(`Wallet is not able to handle such SendTransaction request. Max support messages number is ${sendTransactionFeature.maxMessages}, but ${options.requiredMessagesNumber} is required.`, {
          cause: {
            requiredFeature: { featureName: "SendTransaction", value: requiredFeature }
          }
        });
      }
      return;
    }
    logWarning("Connected wallet didn't provide information about max allowed messages in the SendTransaction request. Request may be rejected by the wallet.");
  }
  function checkSignDataSupport(features, options) {
    const signDataFeature = features.find((feature) => feature && typeof feature === "object" && feature.name === "SignData");
    if (!signDataFeature) {
      throw new WalletNotSupportFeatureError("Wallet doesn't support SignData feature.", {
        cause: {
          requiredFeature: {
            featureName: "SignData",
            value: { types: options.requiredTypes }
          }
        }
      });
    }
    const unsupportedTypes = options.requiredTypes.filter((requiredType) => !signDataFeature.types.includes(requiredType));
    if (unsupportedTypes.length) {
      throw new WalletNotSupportFeatureError(`Wallet doesn't support required SignData types: ${unsupportedTypes.join(", ")}.`, {
        cause: {
          requiredFeature: { featureName: "SignData", value: { types: unsupportedTypes } }
        }
      });
    }
  }
  function checkSignMessageSupport(features, options) {
    var _a;
    const signMessageFeature = findFeature(features, "SignMessage");
    const requiredFeature = {
      minMessages: options.requiredMessagesNumber,
      extraCurrencyRequired: options.requireExtraCurrencies,
      itemTypes: options.requiredItemTypes
    };
    if (!signMessageFeature) {
      throw new WalletNotSupportFeatureError("Wallet doesn't support SignMessage feature.", {
        cause: { requiredFeature: { featureName: "SignMessage", value: requiredFeature } }
      });
    }
    if (options.requireExtraCurrencies && !signMessageFeature.extraCurrencySupported) {
      throw new WalletNotSupportFeatureError(`Wallet is not able to handle such SignMessage request. Extra currencies support is required.`, {
        cause: {
          requiredFeature: { featureName: "SignMessage", value: requiredFeature }
        }
      });
    }
    if ((_a = options.requiredItemTypes) === null || _a === void 0 ? void 0 : _a.length) {
      if (!signMessageFeature.itemTypes) {
        throw new WalletNotSupportFeatureError(`Wallet doesn't support structured items in SignMessage.`, {
          cause: {
            requiredFeature: { featureName: "SignMessage", value: requiredFeature }
          }
        });
      }
      const unsupportedTypes = options.requiredItemTypes.filter((t) => !signMessageFeature.itemTypes.includes(t));
      if (unsupportedTypes.length) {
        throw new WalletNotSupportFeatureError(`Wallet doesn't support item types: ${unsupportedTypes.join(", ")} in SignMessage.`, {
          cause: {
            requiredFeature: { featureName: "SignMessage", value: requiredFeature }
          }
        });
      }
    }
    if (signMessageFeature.maxMessages !== void 0) {
      if (signMessageFeature.maxMessages < options.requiredMessagesNumber) {
        throw new WalletNotSupportFeatureError(`Wallet is not able to handle such SignMessage request. Max support messages number is ${signMessageFeature.maxMessages}, but ${options.requiredMessagesNumber} is required.`, {
          cause: {
            requiredFeature: { featureName: "SignMessage", value: requiredFeature }
          }
        });
      }
      return;
    }
    logWarning("Connected wallet didn't provide information about max allowed messages in the SignMessage request. Request may be rejected by the wallet.");
  }
  function checkRequiredWalletFeatures(features, walletsRequiredFeatures) {
    if (typeof walletsRequiredFeatures !== "object") {
      return true;
    }
    const { sendTransaction, signData, signMessage, embeddedRequest } = walletsRequiredFeatures;
    if (sendTransaction) {
      const feature = findFeature(features, "SendTransaction");
      if (!feature) {
        return false;
      }
      if (!checkSendTransaction(feature, sendTransaction)) {
        return false;
      }
    }
    if (signData) {
      const feature = findFeature(features, "SignData");
      if (!feature) {
        return false;
      }
      if (!checkSignData(feature, signData)) {
        return false;
      }
    }
    if (signMessage) {
      const feature = findFeature(features, "SignMessage");
      if (!feature) {
        return false;
      }
      if (!checkSignMessage(feature, signMessage)) {
        return false;
      }
    }
    if (embeddedRequest) {
      const feature = findFeature(features, "EmbeddedRequest");
      if (!feature) {
        return false;
      }
    }
    return true;
  }
  function findFeature(features, requiredFeatureName) {
    return features.find((f) => f && typeof f === "object" && f.name === requiredFeatureName);
  }
  function checkSendTransaction(feature, requiredFeature) {
    var _a;
    const correctMessagesNumber = requiredFeature.minMessages === void 0 || requiredFeature.minMessages <= feature.maxMessages;
    const correctExtraCurrency = !requiredFeature.extraCurrencyRequired || feature.extraCurrencySupported;
    const correctItemTypes = !((_a = requiredFeature.itemTypes) === null || _a === void 0 ? void 0 : _a.length) || feature.itemTypes && requiredFeature.itemTypes.every((t) => feature.itemTypes.includes(t));
    return !!(correctMessagesNumber && correctExtraCurrency && correctItemTypes);
  }
  function checkSignMessage(feature, requiredFeature) {
    var _a;
    const correctMessagesNumber = requiredFeature.minMessages === void 0 || requiredFeature.minMessages <= feature.maxMessages;
    const correctExtraCurrency = !requiredFeature.extraCurrencyRequired || feature.extraCurrencySupported;
    const correctItemTypes = !((_a = requiredFeature.itemTypes) === null || _a === void 0 ? void 0 : _a.length) || feature.itemTypes && requiredFeature.itemTypes.every((t) => feature.itemTypes.includes(t));
    return !!(correctMessagesNumber && correctExtraCurrency && correctItemTypes);
  }
  function checkSignData(feature, requiredFeature) {
    return requiredFeature.types.every((requiredType) => feature.types.includes(requiredType));
  }
  function createRequestVersionEvent() {
    return {
      type: "request-version"
    };
  }
  function createResponseVersionEvent(version) {
    return {
      type: "response-version",
      version
    };
  }
  function createVersionInfo(version) {
    return {
      ton_connect_sdk_lib: version.ton_connect_sdk_lib,
      ton_connect_ui_lib: version.ton_connect_ui_lib
    };
  }
  function createConnectionInfo(version, wallet, sessionInfo) {
    var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l;
    const isTonProof = ((_a = wallet === null || wallet === void 0 ? void 0 : wallet.connectItems) === null || _a === void 0 ? void 0 : _a.tonProof) && "proof" in wallet.connectItems.tonProof;
    const authType = isTonProof ? "ton_proof" : "ton_addr";
    return {
      wallet_address: (_c = (_b = wallet === null || wallet === void 0 ? void 0 : wallet.account) === null || _b === void 0 ? void 0 : _b.address) !== null && _c !== void 0 ? _c : null,
      wallet_state_init: (_d = wallet === null || wallet === void 0 ? void 0 : wallet.account.walletStateInit) !== null && _d !== void 0 ? _d : null,
      wallet_type: (_e = wallet === null || wallet === void 0 ? void 0 : wallet.device.appName) !== null && _e !== void 0 ? _e : null,
      wallet_version: (_f = wallet === null || wallet === void 0 ? void 0 : wallet.device.appVersion) !== null && _f !== void 0 ? _f : null,
      auth_type: authType,
      custom_data: Object.assign({ client_id: (_g = sessionInfo === null || sessionInfo === void 0 ? void 0 : sessionInfo.clientId) !== null && _g !== void 0 ? _g : null, wallet_id: (_h = sessionInfo === null || sessionInfo === void 0 ? void 0 : sessionInfo.walletId) !== null && _h !== void 0 ? _h : null, chain_id: (_k = (_j = wallet === null || wallet === void 0 ? void 0 : wallet.account) === null || _j === void 0 ? void 0 : _j.chain) !== null && _k !== void 0 ? _k : null, provider: (_l = wallet === null || wallet === void 0 ? void 0 : wallet.provider) !== null && _l !== void 0 ? _l : null }, createVersionInfo(version))
    };
  }
  function createConnectionStartedEvent(version, traceId) {
    return {
      type: "connection-started",
      custom_data: createVersionInfo(version),
      trace_id: traceId !== null && traceId !== void 0 ? traceId : null
    };
  }
  function createConnectionCompletedEvent(version, wallet, sessionInfo, traceId) {
    return Object.assign({ type: "connection-completed", is_success: true, trace_id: traceId !== null && traceId !== void 0 ? traceId : null }, createConnectionInfo(version, wallet, sessionInfo));
  }
  function createConnectionErrorEvent(version, error_message, errorCode, sessionInfo, traceId) {
    var _a, _b;
    return {
      type: "connection-error",
      is_success: false,
      error_message,
      error_code: errorCode !== null && errorCode !== void 0 ? errorCode : null,
      trace_id: traceId !== null && traceId !== void 0 ? traceId : null,
      custom_data: Object.assign({ client_id: (_a = sessionInfo === null || sessionInfo === void 0 ? void 0 : sessionInfo.clientId) !== null && _a !== void 0 ? _a : null, wallet_id: (_b = sessionInfo === null || sessionInfo === void 0 ? void 0 : sessionInfo.walletId) !== null && _b !== void 0 ? _b : null }, createVersionInfo(version))
    };
  }
  function createConnectionRestoringStartedEvent(version, traceId) {
    return {
      type: "connection-restoring-started",
      custom_data: createVersionInfo(version),
      trace_id: traceId !== null && traceId !== void 0 ? traceId : null
    };
  }
  function createConnectionRestoringCompletedEvent(version, wallet, sessionInfo, traceId) {
    return Object.assign({ type: "connection-restoring-completed", is_success: true, trace_id: traceId !== null && traceId !== void 0 ? traceId : null }, createConnectionInfo(version, wallet, sessionInfo));
  }
  function createConnectionRestoringErrorEvent(version, errorMessage, traceId) {
    return {
      type: "connection-restoring-error",
      is_success: false,
      error_message: errorMessage,
      trace_id: traceId !== null && traceId !== void 0 ? traceId : null,
      custom_data: createVersionInfo(version)
    };
  }
  function createTransactionInfo(wallet, transaction) {
    var _a, _b, _c, _d;
    return {
      valid_until: (_a = String(transaction.validUntil)) !== null && _a !== void 0 ? _a : null,
      from: (_d = (_b = transaction.from) !== null && _b !== void 0 ? _b : (_c = wallet === null || wallet === void 0 ? void 0 : wallet.account) === null || _c === void 0 ? void 0 : _c.address) !== null && _d !== void 0 ? _d : null,
      messages: hasMessages(transaction) ? transaction.messages.map((message) => {
        var _a2, _b2;
        return {
          address: (_a2 = message.address) !== null && _a2 !== void 0 ? _a2 : null,
          amount: (_b2 = message.amount) !== null && _b2 !== void 0 ? _b2 : null
        };
      }) : []
    };
  }
  function createTransactionFullInfo(wallet, transaction) {
    var _a, _b, _c, _d;
    return {
      valid_until: (_a = String(transaction.validUntil)) !== null && _a !== void 0 ? _a : null,
      from: (_d = (_b = transaction.from) !== null && _b !== void 0 ? _b : (_c = wallet === null || wallet === void 0 ? void 0 : wallet.account) === null || _c === void 0 ? void 0 : _c.address) !== null && _d !== void 0 ? _d : null,
      messages: hasMessages(transaction) ? transaction.messages.map((message) => {
        var _a2, _b2, _c2, _d2;
        return {
          address: (_a2 = message.address) !== null && _a2 !== void 0 ? _a2 : null,
          amount: (_b2 = message.amount) !== null && _b2 !== void 0 ? _b2 : null,
          payload: (_c2 = message.payload) !== null && _c2 !== void 0 ? _c2 : null,
          state_init: (_d2 = message.stateInit) !== null && _d2 !== void 0 ? _d2 : null
        };
      }) : []
    };
  }
  function createTransactionSentForSignatureEvent(version, wallet, transaction, sessionInfo, traceId) {
    return Object.assign(Object.assign({ type: "transaction-sent-for-signature", trace_id: traceId !== null && traceId !== void 0 ? traceId : null }, createConnectionInfo(version, wallet, sessionInfo)), createTransactionInfo(wallet, transaction));
  }
  function createTransactionSignedEvent(version, wallet, transaction, signedTransaction, sessionInfo, traceId) {
    return Object.assign(Object.assign({ type: "transaction-signed", is_success: true, signed_transaction: signedTransaction.boc, trace_id: traceId !== null && traceId !== void 0 ? traceId : null }, createConnectionInfo(version, wallet, sessionInfo)), createTransactionInfo(wallet, transaction));
  }
  function createTransactionSigningFailedEvent(version, wallet, transaction, errorMessage, errorCode, sessionInfo, traceId) {
    return Object.assign(Object.assign({ type: "transaction-signing-failed", is_success: false, error_message: errorMessage, error_code: errorCode !== null && errorCode !== void 0 ? errorCode : null, trace_id: traceId !== null && traceId !== void 0 ? traceId : null }, createConnectionInfo(version, wallet, sessionInfo)), createTransactionFullInfo(wallet, transaction));
  }
  function createDataSentForSignatureEvent(version, wallet, data, sessionInfo, traceId) {
    return Object.assign({ type: "sign-data-request-initiated", data, trace_id: traceId !== null && traceId !== void 0 ? traceId : null }, createConnectionInfo(version, wallet, sessionInfo));
  }
  function createDataSignedEvent(version, wallet, data, signedData, sessionInfo, traceId) {
    return Object.assign({ type: "sign-data-request-completed", is_success: true, data, signed_data: signedData, trace_id: traceId !== null && traceId !== void 0 ? traceId : null }, createConnectionInfo(version, wallet, sessionInfo));
  }
  function createDataSigningFailedEvent(version, wallet, data, errorMessage, errorCode, sessionInfo, traceId) {
    return Object.assign({ type: "sign-data-request-failed", is_success: false, data, error_message: errorMessage, error_code: errorCode !== null && errorCode !== void 0 ? errorCode : null, trace_id: traceId !== null && traceId !== void 0 ? traceId : null }, createConnectionInfo(version, wallet, sessionInfo));
  }
  function createDisconnectionEvent(version, wallet, scope, sessionInfo, traceId) {
    return Object.assign({ type: "disconnection", scope, trace_id: traceId !== null && traceId !== void 0 ? traceId : null }, createConnectionInfo(version, wallet, sessionInfo));
  }
  function createWalletModalOpenedEvent(version, visibleWallets, clientId, traceId) {
    return {
      type: "wallet-modal-opened",
      visible_wallets: visibleWallets,
      client_id: clientId !== null && clientId !== void 0 ? clientId : null,
      custom_data: version,
      trace_id: traceId !== null && traceId !== void 0 ? traceId : null
    };
  }
  function createSelectedWalletEvent(version, visibleWallets, lastSelectedWallet, walletsMenu, redirectLink, redirectLinkType, clientId, traceId) {
    var _a;
    let walletRedirectMethod = redirectLinkType;
    if (!walletRedirectMethod && redirectLink) {
      walletRedirectMethod = isTelegramUrl(redirectLink) ? "tg_link" : "external_link";
    }
    return {
      type: "selected-wallet",
      wallets_menu: walletsMenu,
      visible_wallets: visibleWallets,
      client_id: clientId !== null && clientId !== void 0 ? clientId : null,
      custom_data: version,
      trace_id: traceId !== null && traceId !== void 0 ? traceId : null,
      wallet_redirect_method: walletRedirectMethod,
      wallet_redirect_link: redirectLink || void 0,
      wallet_type: (_a = lastSelectedWallet === null || lastSelectedWallet === void 0 ? void 0 : lastSelectedWallet.appName) !== null && _a !== void 0 ? _a : null
    };
  }
  var TonConnectTracker = class {
    /**
     * Version of the library.
     */
    get version() {
      return createVersionInfo({
        ton_connect_sdk_lib: this.tonConnectSdkVersion,
        ton_connect_ui_lib: this.tonConnectUiVersion
      });
    }
    constructor(options) {
      this.eventPrefix = "ton-connect-";
      this.tonConnectUiVersion = null;
      this.eventDispatcher = options === null || options === void 0 ? void 0 : options.eventDispatcher;
      this.tonConnectSdkVersion = options.tonConnectSdkVersion;
      this.init().catch();
    }
    /**
     * Called once when the tracker is created and request version other libraries.
     */
    init() {
      return __awaiter(this, void 0, void 0, function* () {
        try {
          yield this.setRequestVersionHandler();
          this.tonConnectUiVersion = yield this.requestTonConnectUiVersion();
        } catch (e) {
        }
      });
    }
    /**
     * Set request version handler.
     * @private
     */
    setRequestVersionHandler() {
      return __awaiter(this, void 0, void 0, function* () {
        yield this.eventDispatcher.addEventListener("ton-connect-request-version", () => __awaiter(this, void 0, void 0, function* () {
          yield this.eventDispatcher.dispatchEvent("ton-connect-response-version", createResponseVersionEvent(this.tonConnectSdkVersion));
        }));
      });
    }
    /**
     * Request TonConnect UI version.
     * @private
     */
    requestTonConnectUiVersion() {
      return __awaiter(this, void 0, void 0, function* () {
        return new Promise((resolve, reject) => __awaiter(this, void 0, void 0, function* () {
          try {
            yield this.eventDispatcher.addEventListener("ton-connect-ui-response-version", (event) => {
              resolve(event.detail.version);
            }, { once: true });
            yield this.eventDispatcher.dispatchEvent("ton-connect-ui-request-version", createRequestVersionEvent());
          } catch (e) {
            reject(e);
          }
        }));
      });
    }
    /**
     * Emit user action event to the window.
     * @param eventDetails
     * @private
     */
    dispatchUserActionEvent(eventDetails) {
      try {
        this.eventDispatcher.dispatchEvent(`${this.eventPrefix}${eventDetails.type}`, eventDetails).catch();
      } catch (e) {
      }
    }
    /**
     * Track connection init event.
     * @param args
     */
    trackConnectionStarted(...args) {
      try {
        const event = createConnectionStartedEvent(this.version, ...args);
        this.dispatchUserActionEvent(event);
      } catch (e) {
      }
    }
    /**
     * Track connection success event.
     * @param args
     */
    trackConnectionCompleted(...args) {
      try {
        const event = createConnectionCompletedEvent(this.version, ...args);
        this.dispatchUserActionEvent(event);
      } catch (e) {
      }
    }
    /**
     * Track connection error event.
     * @param args
     */
    trackConnectionError(...args) {
      try {
        const event = createConnectionErrorEvent(this.version, ...args);
        this.dispatchUserActionEvent(event);
      } catch (e) {
      }
    }
    /**
     * Track connection restoring init event.
     * @param args
     */
    trackConnectionRestoringStarted(...args) {
      try {
        const event = createConnectionRestoringStartedEvent(this.version, ...args);
        this.dispatchUserActionEvent(event);
      } catch (e) {
      }
    }
    /**
     * Track connection restoring success event.
     * @param args
     */
    trackConnectionRestoringCompleted(...args) {
      try {
        const event = createConnectionRestoringCompletedEvent(this.version, ...args);
        this.dispatchUserActionEvent(event);
      } catch (e) {
      }
    }
    /**
     * Track connection restoring error event.
     * @param args
     */
    trackConnectionRestoringError(...args) {
      try {
        const event = createConnectionRestoringErrorEvent(this.version, ...args);
        this.dispatchUserActionEvent(event);
      } catch (e) {
      }
    }
    /**
     * Track disconnect event.
     * @param args
     */
    trackDisconnection(...args) {
      try {
        const event = createDisconnectionEvent(this.version, ...args);
        this.dispatchUserActionEvent(event);
      } catch (e) {
      }
    }
    /**
     * Track transaction init event.
     * @param args
     */
    trackTransactionSentForSignature(...args) {
      try {
        const event = createTransactionSentForSignatureEvent(this.version, ...args);
        this.dispatchUserActionEvent(event);
      } catch (e) {
      }
    }
    /**
     * Track transaction signed event.
     * @param args
     */
    trackTransactionSigned(...args) {
      try {
        const event = createTransactionSignedEvent(this.version, ...args);
        this.dispatchUserActionEvent(event);
      } catch (e) {
      }
    }
    /**
     * Track transaction error event.
     * @param args
     */
    trackTransactionSigningFailed(...args) {
      try {
        const event = createTransactionSigningFailedEvent(this.version, ...args);
        this.dispatchUserActionEvent(event);
      } catch (e) {
      }
    }
    /**
     * Track sign data init event.
     * @param args
     */
    trackDataSentForSignature(...args) {
      try {
        const event = createDataSentForSignatureEvent(this.version, ...args);
        this.dispatchUserActionEvent(event);
      } catch (e) {
      }
    }
    /**
     * Track sign data success event.
     * @param args
     */
    trackDataSigned(...args) {
      try {
        const event = createDataSignedEvent(this.version, ...args);
        this.dispatchUserActionEvent(event);
      } catch (e) {
      }
    }
    /**
     * Track sign data error event.
     * @param args
     */
    trackDataSigningFailed(...args) {
      try {
        const event = createDataSigningFailedEvent(this.version, ...args);
        this.dispatchUserActionEvent(event);
      } catch (e) {
      }
    }
  };
  var tonConnectSdkVersion = "4.0.0";
  var bounceableTag = 17;
  var noBounceableTag = 81;
  var testOnlyTag = 128;
  function toUserFriendlyAddress(hexAddress, testOnly = false) {
    const { wc, hex } = parseHexAddress(hexAddress);
    let tag = noBounceableTag;
    if (testOnly) {
      tag |= testOnlyTag;
    }
    const addr = new Int8Array(34);
    addr[0] = tag;
    addr[1] = wc;
    addr.set(hex, 2);
    const addressWithChecksum = new Uint8Array(36);
    addressWithChecksum.set(addr);
    addressWithChecksum.set(crc16(addr), 34);
    let addressBase64 = Base64.encode(addressWithChecksum);
    return addressBase64.replace(/\+/g, "-").replace(/\//g, "_");
  }
  function isValidUserFriendlyAddress(address) {
    try {
      parseUserFriendlyAddress(address);
      return true;
    } catch (_a) {
      return false;
    }
  }
  function isValidRawAddress(address) {
    try {
      parseHexAddress(address);
      return true;
    } catch (_a) {
      return false;
    }
  }
  function toRawAddress({ wc, hex }) {
    return `${wc}:${hex}`;
  }
  function parseUserFriendlyAddress(address) {
    const base64 = address.replace(/-/g, "+").replace(/_/g, "/");
    let decoded;
    try {
      decoded = Base64.decode(base64).toUint8Array();
    } catch (_a) {
      throw new WrongAddressError(`Invalid base64 encoding in address: ${address}`);
    }
    if (decoded.length !== 36) {
      throw new WrongAddressError(`Invalid address length: ${address}`);
    }
    const addr = decoded.slice(0, 34);
    const checksum = decoded.slice(34, 36);
    const calculatedChecksum = crc16(addr);
    if (!checksum.every((byte, i) => byte === calculatedChecksum[i])) {
      throw new WrongAddressError(`Invalid checksum in address: ${address}`);
    }
    let tag = addr[0];
    let isTestOnly = false;
    let isBounceable = false;
    if (tag & testOnlyTag) {
      isTestOnly = true;
      tag = tag ^ testOnlyTag;
    }
    if (tag !== bounceableTag && tag !== noBounceableTag) {
      throw new WrongAddressError(`Unknown address tag: ${tag}`);
    }
    isBounceable = tag === bounceableTag;
    let wc = null;
    if (addr[1] === 255) {
      wc = -1;
    } else {
      wc = addr[1];
    }
    const hex = addr.slice(2);
    if (wc !== 0 && wc !== -1) {
      throw new WrongAddressError(`Invalid workchain: ${wc}`);
    }
    return {
      wc,
      hex: Array.from(hex).map((b) => b.toString(16).padStart(2, "0")).join(""),
      testOnly: isTestOnly,
      isBounceable
    };
  }
  function parseHexAddress(hexAddress) {
    if (!hexAddress.includes(":")) {
      throw new WrongAddressError(`Wrong address ${hexAddress}. Address must include ":".`);
    }
    const parts = hexAddress.split(":");
    if (parts.length !== 2) {
      throw new WrongAddressError(`Wrong address ${hexAddress}. Address must include ":" only once.`);
    }
    const wc = parseInt(parts[0]);
    if (wc !== 0 && wc !== -1) {
      throw new WrongAddressError(`Wrong address ${hexAddress}. WC must be eq 0 or -1, but ${wc} received.`);
    }
    const hex = parts[1];
    if ((hex === null || hex === void 0 ? void 0 : hex.length) !== 64) {
      throw new WrongAddressError(`Wrong address ${hexAddress}. Hex part must be 64bytes length, but ${hex === null || hex === void 0 ? void 0 : hex.length} received.`);
    }
    return {
      wc,
      hex: hexToBytes(hex)
    };
  }
  function crc16(data) {
    const poly = 4129;
    let reg = 0;
    const message = new Uint8Array(data.length + 2);
    message.set(data);
    for (let byte of message) {
      let mask = 128;
      while (mask > 0) {
        reg <<= 1;
        if (byte & mask) {
          reg += 1;
        }
        mask >>= 1;
        if (reg > 65535) {
          reg &= 65535;
          reg ^= poly;
        }
      }
    }
    return new Uint8Array([Math.floor(reg / 256), reg % 256]);
  }
  var toByteMap = {};
  for (let ord = 0; ord <= 255; ord++) {
    let s = ord.toString(16);
    if (s.length < 2) {
      s = "0" + s;
    }
    toByteMap[s] = ord;
  }
  function hexToBytes(hex) {
    hex = hex.toLowerCase();
    const length2 = hex.length;
    if (length2 % 2 !== 0) {
      throw new ParseHexError("Hex string must have length a multiple of 2: " + hex);
    }
    const length = length2 / 2;
    const result = new Uint8Array(length);
    for (let i = 0; i < length; i++) {
      const doubled = i * 2;
      const hexSubstring = hex.substring(doubled, doubled + 2);
      if (!toByteMap.hasOwnProperty(hexSubstring)) {
        throw new ParseHexError("Invalid hex character: " + hexSubstring);
      }
      result[i] = toByteMap[hexSubstring];
    }
    return result;
  }
  var BASE64_REGEX = /^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/;
  var BASE64URL_REGEX = /^[A-Za-z0-9\-_]+$/;
  var BOC_PREFIX = "te6cc";
  var INTEGER_REGEX = /^-?\d+$/;
  var POSITIVE_INTEGER_REGEX = /^\d+$/;
  var MAX_DOMAIN_BYTES = 128;
  var MAX_PAYLOAD_BYTES = 128;
  var MAX_TOTAL_BYTES = 222;
  function isValidNumber(value) {
    return typeof value === "number" && !isNaN(value);
  }
  function isValidString(value) {
    return typeof value === "string" && value.length > 0;
  }
  function isValidAddress(value) {
    return isValidString(value) && (isValidRawAddress(value) || isValidUserFriendlyAddress(value));
  }
  function isValidNetwork(value) {
    return isValidString(value) && /^-?\d+$/.test(value);
  }
  function isValidBoc(value) {
    return typeof value === "string" && (BASE64_REGEX.test(value) || BASE64URL_REGEX.test(value)) && value.startsWith(BOC_PREFIX);
  }
  function isValidObject(value) {
    return typeof value === "object" && value !== null && !Array.isArray(value);
  }
  function isValidArray(value) {
    return Array.isArray(value);
  }
  function hasExtraProperties(obj, allowedKeys) {
    return Object.keys(obj).some((key) => !allowedKeys.includes(key));
  }
  function validateSignMessageRequest(data) {
    return validateSendTransactionRequest(data);
  }
  function validateSendTransactionRequest(data) {
    if (!isValidObject(data)) {
      return "Request must be an object";
    }
    const allowedKeys = ["validUntil", "network", "from", "messages", "items"];
    if (hasExtraProperties(data, allowedKeys)) {
      return "Request contains extra properties";
    }
    if (data.validUntil) {
      if (!isValidNumber(data.validUntil)) {
        return "Incorrect 'validUntil'";
      }
      const now = Math.floor(Date.now() / 1e3);
      const fiveMinutesFromNow = now + 300;
      if (data.validUntil > fiveMinutesFromNow) {
        console.warn(`validUntil (${data.validUntil}) is more than 5 minutes from now (${now})`);
      }
    }
    if (data.network !== void 0) {
      if (!isValidNetwork(data.network)) {
        return "Invalid 'network' format";
      }
    }
    if (data.from !== void 0 && !isValidAddress(data.from)) {
      return "Invalid 'from' address format";
    }
    const hasMessagesField = isValidArray(data.messages);
    const hasItemsField = isValidArray(data.items);
    if (hasMessagesField && hasItemsField) {
      return "Request must contain either 'messages' or 'items', not both";
    }
    if (!hasMessagesField && !hasItemsField) {
      return "Request must contain 'messages' or 'items'";
    }
    if (hasMessagesField) {
      if (data.messages.length === 0) {
        return "'messages' must not be empty";
      }
      for (let i = 0; i < data.messages.length; i++) {
        const message = data.messages[i];
        const messageError = validateTransactionMessage(message, i);
        if (messageError) {
          return messageError;
        }
      }
    }
    if (hasItemsField) {
      const error = validateStructuredItems(data.items);
      if (error) {
        return error;
      }
    }
    return null;
  }
  function validateTransactionMessage(message, index) {
    if (!isValidObject(message)) {
      return `Message at index ${index} must be an object`;
    }
    const allowedKeys = ["address", "amount", "stateInit", "payload", "extraCurrency"];
    if (hasExtraProperties(message, allowedKeys)) {
      return `Message at index ${index} contains extra properties`;
    }
    if (!isValidString(message.address)) {
      return `'address' is required in message at index ${index}`;
    }
    if (!isValidUserFriendlyAddress(message.address)) {
      return `Wrong 'address' format in message at index ${index}`;
    }
    if (!isValidString(message.amount)) {
      return `'amount' is required in message at index ${index}`;
    }
    if (!/^[0-9]+$/.test(message.amount)) {
      return `Incorrect 'amount' in message at index ${index}`;
    }
    if (message.stateInit !== void 0) {
      if (!isValidString(message.stateInit) || !isValidBoc(message.stateInit)) {
        return `Invalid 'stateInit' in message at index ${index}`;
      }
    }
    if (message.payload !== void 0) {
      if (!isValidString(message.payload) || !isValidBoc(message.payload)) {
        return `Invalid 'payload' in message at index ${index}`;
      }
    }
    if (message.extraCurrency !== void 0) {
      if (!isValidObject(message.extraCurrency)) {
        return `Invalid 'extraCurrency' in message at index ${index}`;
      }
      for (const [key, value] of Object.entries(message.extraCurrency)) {
        if (!INTEGER_REGEX.test(key) || typeof value !== "string" || !POSITIVE_INTEGER_REGEX.test(value)) {
          return `Invalid 'extraCurrency' format in message at index ${index}`;
        }
      }
    }
    return null;
  }
  function validateStructuredItems(items) {
    if (items.length === 0) {
      return "'items' must not be empty";
    }
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const itemError = validateStructuredItem(item, i);
      if (itemError) {
        return itemError;
      }
    }
    return null;
  }
  function validateStructuredItem(item, index) {
    if (!isValidObject(item)) {
      return `Item at index ${index} must be an object`;
    }
    if (!isValidString(item.type)) {
      return `'type' is required in item at index ${index}`;
    }
    switch (item.type) {
      case "ton":
        return validateTonItem(item, index);
      case "jetton":
        return validateJettonItem(item, index);
      case "nft":
        return validateNftItem(item, index);
      default:
        return `Unknown item type '${item.type}' at index ${index}`;
    }
  }
  function validateTonItem(item, index) {
    const allowedKeys = ["type", "address", "amount", "payload", "stateInit", "extraCurrency"];
    if (hasExtraProperties(item, allowedKeys)) {
      return `Ton item at index ${index} contains extra properties`;
    }
    if (!isValidString(item.address)) {
      return `'address' is required in ton item at index ${index}`;
    }
    if (!isValidUserFriendlyAddress(item.address)) {
      return `Wrong 'address' format in ton item at index ${index}`;
    }
    if (!isValidString(item.amount)) {
      return `'amount' is required in ton item at index ${index}`;
    }
    if (!/^[0-9]+$/.test(item.amount)) {
      return `Incorrect 'amount' in ton item at index ${index}`;
    }
    if (item.payload !== void 0) {
      if (!isValidString(item.payload) || !isValidBoc(item.payload)) {
        return `Invalid 'payload' in ton item at index ${index}`;
      }
    }
    if (item.stateInit !== void 0) {
      if (!isValidString(item.stateInit) || !isValidBoc(item.stateInit)) {
        return `Invalid 'stateInit' in ton item at index ${index}`;
      }
    }
    if (item.extraCurrency !== void 0) {
      if (!isValidObject(item.extraCurrency)) {
        return `Invalid 'extraCurrency' in ton item at index ${index}`;
      }
      for (const [key, value] of Object.entries(item.extraCurrency)) {
        if (!INTEGER_REGEX.test(key) || typeof value !== "string" || !POSITIVE_INTEGER_REGEX.test(value)) {
          return `Invalid 'extraCurrency' format in ton item at index ${index}`;
        }
      }
    }
    return null;
  }
  function validateJettonItem(item, index) {
    const allowedKeys = [
      "type",
      "master",
      "destination",
      "amount",
      "attachAmount",
      "responseDestination",
      "customPayload",
      "forwardAmount",
      "forwardPayload",
      "queryId"
    ];
    if (hasExtraProperties(item, allowedKeys)) {
      return `Jetton item at index ${index} contains extra properties`;
    }
    if (!isValidString(item.master)) {
      return `'master' is required in jetton item at index ${index}`;
    }
    if (!isValidAddress(item.master)) {
      return `Wrong 'master' address format in jetton item at index ${index}`;
    }
    if (!isValidString(item.destination)) {
      return `'destination' is required in jetton item at index ${index}`;
    }
    if (!isValidAddress(item.destination)) {
      return `Wrong 'destination' address format in jetton item at index ${index}`;
    }
    if (!isValidString(item.amount)) {
      return `'amount' is required in jetton item at index ${index}`;
    }
    if (!/^[0-9]+$/.test(item.amount)) {
      return `Incorrect 'amount' in jetton item at index ${index}`;
    }
    if (item.attachAmount !== void 0 && (!isValidString(item.attachAmount) || !/^[0-9]+$/.test(item.attachAmount))) {
      return `Invalid 'attachAmount' in jetton item at index ${index}`;
    }
    if (item.responseDestination !== void 0 && !isValidAddress(item.responseDestination)) {
      return `Wrong 'responseDestination' address format in jetton item at index ${index}`;
    }
    if (item.customPayload !== void 0) {
      if (!isValidString(item.customPayload) || !isValidBoc(item.customPayload)) {
        return `Invalid 'customPayload' in jetton item at index ${index}`;
      }
    }
    if (item.forwardAmount !== void 0) {
      if (!isValidString(item.forwardAmount) || !/^[0-9]+$/.test(item.forwardAmount)) {
        return `Invalid 'forwardAmount' in jetton item at index ${index}`;
      }
    }
    if (item.forwardPayload !== void 0) {
      if (!isValidString(item.forwardPayload) || !isValidBoc(item.forwardPayload)) {
        return `Invalid 'forwardPayload' in jetton item at index ${index}`;
      }
    }
    if (item.queryId !== void 0) {
      if (!isValidString(item.queryId) || !/^[0-9]+$/.test(item.queryId)) {
        return `Invalid 'queryId' in jetton item at index ${index}`;
      }
    }
    return null;
  }
  function validateNftItem(item, index) {
    const allowedKeys = [
      "type",
      "nftAddress",
      "newOwner",
      "attachAmount",
      "responseDestination",
      "customPayload",
      "forwardAmount",
      "forwardPayload",
      "queryId"
    ];
    if (hasExtraProperties(item, allowedKeys)) {
      return `NFT item at index ${index} contains extra properties`;
    }
    if (!isValidString(item.nftAddress)) {
      return `'nftAddress' is required in nft item at index ${index}`;
    }
    if (!isValidAddress(item.nftAddress)) {
      return `Wrong 'nftAddress' address format in nft item at index ${index}`;
    }
    if (!isValidString(item.newOwner)) {
      return `'newOwner' is required in nft item at index ${index}`;
    }
    if (!isValidAddress(item.newOwner)) {
      return `Wrong 'newOwner' address format in nft item at index ${index}`;
    }
    if (item.attachAmount !== void 0) {
      if (!isValidString(item.attachAmount) || !/^[0-9]+$/.test(item.attachAmount)) {
        return `Invalid 'attachAmount' in nft item at index ${index}`;
      }
    }
    if (item.responseDestination !== void 0 && !isValidAddress(item.responseDestination)) {
      return `Wrong 'responseDestination' address format in nft item at index ${index}`;
    }
    if (item.customPayload !== void 0) {
      if (!isValidString(item.customPayload) || !isValidBoc(item.customPayload)) {
        return `Invalid 'customPayload' in nft item at index ${index}`;
      }
    }
    if (item.forwardAmount !== void 0) {
      if (!isValidString(item.forwardAmount) || !/^[0-9]+$/.test(item.forwardAmount)) {
        return `Invalid 'forwardAmount' in nft item at index ${index}`;
      }
    }
    if (item.forwardPayload !== void 0) {
      if (!isValidString(item.forwardPayload) || !isValidBoc(item.forwardPayload)) {
        return `Invalid 'forwardPayload' in nft item at index ${index}`;
      }
    }
    if (item.queryId !== void 0) {
      if (!isValidString(item.queryId) || !/^[0-9]+$/.test(item.queryId)) {
        return `Invalid 'queryId' in nft item at index ${index}`;
      }
    }
    return null;
  }
  function validateConnectAdditionalRequest(data) {
    if (!isValidObject(data)) {
      return "Request must be an object";
    }
    const allowedKeys = ["tonProof"];
    if (hasExtraProperties(data, allowedKeys)) {
      return "Request contains extra properties";
    }
    if (data.tonProof !== void 0) {
      if (typeof data.tonProof !== "string") {
        return "Invalid 'tonProof'";
      }
      const payload = data.tonProof;
      if (payload.length === 0) {
        return "Empty 'tonProof' payload";
      }
      const domain = getDomain();
      if (!domain) {
        return null;
      }
      const domainBytes = new TextEncoder().encode(domain).length;
      if (domainBytes > MAX_DOMAIN_BYTES) {
        return "Current domain exceeds 128 bytes limit";
      }
      const payloadBytes = new TextEncoder().encode(payload).length;
      if (payloadBytes > MAX_PAYLOAD_BYTES) {
        return "'tonProof' payload exceeds 128 bytes limit";
      }
      if (domainBytes + payloadBytes > MAX_TOTAL_BYTES) {
        return "'tonProof' domain + payload exceeds 222 bytes limit";
      }
    }
    return null;
  }
  function validateEmbeddedRequest(data) {
    if (!isValidObject(data)) {
      return "Embedded request must be an object";
    }
    if (hasExtraProperties(data, ["method", "request"])) {
      return "Embedded request contains extra properties";
    }
    if (!isValidString(data.method)) {
      return "Embedded request: 'method' is required";
    }
    if (!("request" in data)) {
      return "Embedded request: 'request' is required";
    }
    const prefixError = (inner) => inner === null ? null : `Embedded ${data.method}: ${inner}`;
    switch (data.method) {
      case "sendTransaction":
        return prefixError(validateSendTransactionRequest(data.request));
      case "signData":
        return prefixError(validateSignDataPayload(data.request));
      case "signMessage":
        return prefixError(validateSignMessageRequest(data.request));
    }
    return `Invalid 'method' value: ${data.method}`;
  }
  function validateSignDataPayload(data) {
    if (!isValidObject(data)) {
      return "Payload must be an object";
    }
    if (!isValidString(data.type)) {
      return "'type' is required";
    }
    switch (data.type) {
      case "text":
        return validateSignDataPayloadText(data);
      case "binary":
        return validateSignDataPayloadBinary(data);
      case "cell":
        return validateSignDataPayloadCell(data);
      default:
        return "Invalid 'type' value";
    }
  }
  function validateSignDataPayloadText(data) {
    const allowedKeys = ["type", "text", "network", "from"];
    if (hasExtraProperties(data, allowedKeys)) {
      return "Text payload contains extra properties";
    }
    if (!isValidString(data.text)) {
      return "'text' is required";
    }
    if (data.network !== void 0) {
      if (!isValidNetwork(data.network)) {
        return "Invalid 'network' format";
      }
    }
    if (data.from !== void 0 && !isValidAddress(data.from)) {
      return "Invalid 'from'";
    }
    return null;
  }
  function validateSignDataPayloadBinary(data) {
    const allowedKeys = ["type", "bytes", "network", "from"];
    if (hasExtraProperties(data, allowedKeys)) {
      return "Binary payload contains extra properties";
    }
    if (!isValidString(data.bytes)) {
      return "'bytes' is required";
    }
    if (data.network !== void 0) {
      if (!isValidNetwork(data.network)) {
        return "Invalid 'network' format";
      }
    }
    if (data.from !== void 0 && !isValidAddress(data.from)) {
      return "Invalid 'from'";
    }
    return null;
  }
  function validateSignDataPayloadCell(data) {
    const allowedKeys = ["type", "schema", "cell", "network", "from"];
    if (hasExtraProperties(data, allowedKeys)) {
      return "Cell payload contains extra properties";
    }
    if (!isValidString(data.schema)) {
      return "'schema' is required";
    }
    if (!isValidString(data.cell)) {
      return "'cell' is required";
    }
    if (!isValidBoc(data.cell)) {
      return "Invalid 'cell' format (must be valid base64)";
    }
    if (data.network !== void 0) {
      if (!isValidNetwork(data.network)) {
        return "Invalid 'network' format";
      }
    }
    if (data.from !== void 0 && !isValidAddress(data.from)) {
      return "Invalid 'from'";
    }
    return null;
  }
  function validateTonProofItemReply(data) {
    if (!isValidObject(data)) {
      return "ton_proof item must be an object";
    }
    const allowedKeys = ["error", "proof", "name"];
    if (hasExtraProperties(data, allowedKeys)) {
      return "ton_proof item contains extra properties";
    }
    const hasProof = Object.prototype.hasOwnProperty.call(data, "proof");
    const hasError = Object.prototype.hasOwnProperty.call(data, "error");
    if (!hasProof && !hasError) {
      return "'ton_proof' item must contain either 'proof' or 'error'";
    }
    if (hasProof && hasError) {
      return "'ton_proof' item must contain either 'proof' or 'error', not both";
    }
    if (hasProof) {
      const proof = data.proof;
      if (!isValidObject(proof)) {
        return "Invalid 'proof' object";
      }
      if (!isValidNumber(proof.timestamp)) {
        return "Invalid 'proof.timestamp'";
      }
      const domain = proof.domain;
      if (!isValidObject(domain)) {
        return "Invalid 'proof.domain'";
      }
      if (!isValidNumber(domain.lengthBytes)) {
        return "Invalid 'proof.domain.lengthBytes'";
      }
      if (!isValidString(domain.value)) {
        return "Invalid 'proof.domain.value'";
      }
      try {
        const encoderAvailable = typeof TextEncoder !== "undefined";
        const actualLength = encoderAvailable ? new TextEncoder().encode(domain.value).length : domain.value.length;
        if (actualLength !== domain.lengthBytes) {
          return "'proof.domain.lengthBytes' does not match 'proof.domain.value'";
        }
      } catch (_a) {
      }
      if (!isValidString(proof.payload)) {
        return "Invalid 'proof.payload'";
      }
      if (!isValidString(proof.signature) || !BASE64_REGEX.test(proof.signature)) {
        return "Invalid 'proof.signature' format";
      }
    }
    if (hasError) {
      const error = data.error;
      if (!isValidObject(error)) {
        return "Invalid 'error' object";
      }
      const allowedErrorKeys = ["code", "message"];
      if (hasExtraProperties(error, allowedErrorKeys)) {
        return "ton_proof error contains extra properties";
      }
      if (!isValidNumber(error.code)) {
        return "Invalid 'error.code'";
      }
      if (!isValidString(error.message)) {
        return "Invalid 'error.message'";
      }
    }
    return null;
  }
  function normalizeStructuredItem(item) {
    switch (item.type) {
      case "ton": {
        const { extraCurrency } = item, rest = __rest(item, ["extraCurrency"]);
        return Object.assign(Object.assign({}, rest), { payload: normalizeBase64(item.payload), stateInit: normalizeBase64(item.stateInit), extra_currency: extraCurrency });
      }
      case "jetton": {
        return Object.assign(Object.assign({}, item), { customPayload: normalizeBase64(item.customPayload), forwardPayload: normalizeBase64(item.forwardPayload) });
      }
      case "nft": {
        return Object.assign(Object.assign({}, item), { customPayload: normalizeBase64(item.customPayload), forwardPayload: normalizeBase64(item.forwardPayload) });
      }
    }
  }
  function pascalToKebab(value) {
    return value.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
  }
  function getStaticConnectionMetrics() {
    const metrics = {};
    try {
      const navEntries = performance.getEntriesByType("navigation");
      if (navEntries.length > 0) {
        const nav = navEntries[0];
        if (nav.responseStart && nav.requestStart) {
          metrics.conn_ttfb = Math.round(nav.responseStart - nav.requestStart);
        }
      }
    } catch (e) {
    }
    return metrics;
  }
  function getDynamicConnectionMetrics() {
    const metrics = {};
    try {
      const navigatorWithConnection = navigator;
      const connection = navigatorWithConnection.connection || navigatorWithConnection.mozConnection || navigatorWithConnection.webkitConnection;
      if (connection) {
        if (connection.rtt !== void 0) {
          metrics.conn_rtt = connection.rtt;
        }
        if (connection.effectiveType) {
          metrics.conn_network_type = connection.effectiveType;
        } else if (connection.type) {
          metrics.conn_network_type = connection.type;
        }
      }
    } catch (e) {
    }
    return metrics;
  }
  var AnalyticsManager = class _AnalyticsManager {
    constructor(options = {}) {
      var _a, _b, _c, _d, _e, _f;
      this.events = [];
      this.timeoutId = null;
      this.isProcessing = false;
      this.backoff = 1;
      this.shouldSend = true;
      this.batchTimeoutMs = (_a = options.batchTimeoutMs) !== null && _a !== void 0 ? _a : 2e3;
      this.currentBatchTimeoutMs = this.batchTimeoutMs;
      this.maxBatchSize = (_b = options.maxBatchSize) !== null && _b !== void 0 ? _b : 100;
      this.analyticsUrl = (_c = options.analyticsUrl) !== null && _c !== void 0 ? _c : "https://analytics.ton.org/events";
      this.mode = (_d = options.mode) !== null && _d !== void 0 ? _d : "telemetry";
      this.baseEvent = Object.assign({ subsystem: "dapp-sdk", version: tonConnectSdkVersion, client_environment: (_f = (_e = options.environment) === null || _e === void 0 ? void 0 : _e.getClientEnvironment) === null || _f === void 0 ? void 0 : _f.call(_e) }, getStaticConnectionMetrics());
      this.addWindowFocusAndBlurSubscriptions();
    }
    scoped(sharedData) {
      return new Proxy(this, {
        get(target, prop) {
          const propName = prop.toString();
          if (propName.startsWith("emit")) {
            const eventNamePascal = propName.replace("emit", "");
            const eventNameKebab = pascalToKebab(eventNamePascal);
            return function(event) {
              const executedData = Object.fromEntries(Object.entries(sharedData !== null && sharedData !== void 0 ? sharedData : {}).map(([key, value]) => [
                key,
                typeof value === "function" ? value() : value
              ]));
              return target.emit(Object.assign(Object.assign({ event_name: eventNameKebab }, executedData), event));
            };
          }
          return target[prop];
        }
      });
    }
    emit(event) {
      var _a;
      if (this.mode === "off") {
        return;
      }
      const traceId = (_a = event.trace_id) !== null && _a !== void 0 ? _a : UUIDv7();
      const dynamicMetrics = getDynamicConnectionMetrics();
      const enhancedEvent = Object.assign(Object.assign(Object.assign(Object.assign({}, this.baseEvent), dynamicMetrics), event), { event_id: UUIDv7(), client_timestamp: Math.floor(Date.now() / 1e3), trace_id: traceId });
      const filteredEvent = this.mode === "telemetry" ? this.filterFullModeFields(enhancedEvent) : enhancedEvent;
      if (isQaModeEnabled()) {
        logDebug(filteredEvent);
      }
      this.events.push(filteredEvent);
      if (this.events.length >= this.maxBatchSize) {
        void this.flush();
        return;
      }
      this.startTimeout();
    }
    startTimeout() {
      if (this.timeoutId || this.isProcessing) {
        return;
      }
      this.timeoutId = setTimeout(() => {
        void this.flush();
      }, this.currentBatchTimeoutMs);
    }
    flush() {
      return __awaiter(this, void 0, void 0, function* () {
        if (this.isProcessing || this.events.length === 0 || !this.shouldSend) {
          return;
        }
        this.clearTimeout();
        this.isProcessing = true;
        const eventsToSend = this.extractEventsToSend();
        try {
          yield this.processEventsBatch(eventsToSend);
          logDebug("Analytics events sent successfully");
        } catch (error) {
          this.restoreEvents(eventsToSend);
          logError("Failed to send analytics events:", error);
        } finally {
          this.isProcessing = false;
          this.scheduleNextFlushIfNeeded();
        }
      });
    }
    clearTimeout() {
      if (this.timeoutId) {
        clearTimeout(this.timeoutId);
        this.timeoutId = null;
      }
    }
    extractEventsToSend() {
      const eventsToSend = this.events.slice(0, this.maxBatchSize);
      this.events = this.events.slice(this.maxBatchSize);
      return eventsToSend;
    }
    processEventsBatch(eventsToSend) {
      return __awaiter(this, void 0, void 0, function* () {
        logDebug("Sending analytics events...", eventsToSend.length);
        try {
          const response = yield this.sendEvents(eventsToSend);
          this.handleResponse(response);
        } catch (err) {
          this.handleUnknownError(err);
        }
      });
    }
    handleResponse(response) {
      const { status, statusText } = response;
      if (this.isTooManyRequests(status)) {
        this.handleTooManyRequests(status, statusText);
      } else if (this.isClientError(status)) {
        this.handleClientError(status, statusText);
      } else if (this.isServerError(status)) {
        this.handleUnknownError({ status, statusText });
      }
    }
    restoreEvents(eventsToSend) {
      this.events.unshift(...eventsToSend);
    }
    scheduleNextFlushIfNeeded() {
      if (this.events.length > 0) {
        this.startTimeout();
      }
    }
    sendEvents(events) {
      return __awaiter(this, void 0, void 0, function* () {
        return yield fetch(this.analyticsUrl, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-Client-Timestamp": Math.floor(Date.now() / 1e3).toString()
          },
          body: JSON.stringify(events)
        });
      });
    }
    isClientError(status) {
      return status >= _AnalyticsManager.HTTP_STATUS.CLIENT_ERROR_START && status < _AnalyticsManager.HTTP_STATUS.SERVER_ERROR_START;
    }
    isServerError(status) {
      return status >= _AnalyticsManager.HTTP_STATUS.SERVER_ERROR_START;
    }
    isTooManyRequests(status) {
      return status === _AnalyticsManager.HTTP_STATUS.TOO_MANY_REQUESTS;
    }
    handleClientError(status, statusText) {
      logError("Failed to send analytics events:", new TonConnectError(`Analytics API error: ${status} ${statusText}`));
    }
    handleUnknownError(error) {
      if (this.backoff < _AnalyticsManager.MAX_BACKOFF_ATTEMPTS) {
        this.backoff++;
        this.currentBatchTimeoutMs *= _AnalyticsManager.BACKOFF_MULTIPLIER;
        throw new TonConnectError(`Unknown analytics API error: ${error}`);
      } else {
        this.currentBatchTimeoutMs = this.batchTimeoutMs;
        this.backoff = 1;
        return;
      }
    }
    handleTooManyRequests(status, statusText) {
      throw new TonConnectError(`Analytics API error: ${status} ${statusText}`);
    }
    addWindowFocusAndBlurSubscriptions() {
      const document2 = getDocument();
      if (!document2) {
        return;
      }
      try {
        document2.addEventListener("visibilitychange", () => {
          if (document2.hidden) {
            this.clearTimeout();
            this.shouldSend = false;
          } else {
            this.shouldSend = true;
            this.scheduleNextFlushIfNeeded();
          }
        });
      } catch (e) {
        logError("Cannot subscribe to the document.visibilitychange: ", e);
      }
    }
    getMode() {
      return this.mode;
    }
    getPendingEventsCount() {
      return this.events.length;
    }
    filterFullModeFields(event) {
      const filtered = Object.assign({}, event);
      for (const field of _AnalyticsManager.FULL_MODE_FIELDS) {
        delete filtered[field];
      }
      const eventName = "event_name" in event ? String(event.event_name) : "";
      const isErrorEvent = "error_code" in event || "error_message" in event || eventName.includes("error") || eventName === "connection-error" || eventName === "transaction-signing-failed" || eventName === "sign-data-request-failed";
      if (!isErrorEvent && "wallet_address" in filtered) {
        delete filtered.wallet_address;
      }
      return filtered;
    }
    setWalletListDownloadDuration(duration) {
      this.baseEvent = Object.assign(Object.assign({}, this.baseEvent), { wallet_list_download_duration: duration });
    }
  };
  AnalyticsManager.HTTP_STATUS = {
    TOO_MANY_REQUESTS: 429,
    CLIENT_ERROR_START: 400,
    SERVER_ERROR_START: 500
  };
  AnalyticsManager.MAX_BACKOFF_ATTEMPTS = 5;
  AnalyticsManager.BACKOFF_MULTIPLIER = 2;
  AnalyticsManager.FULL_MODE_FIELDS = [
    "user_id",
    "tg_id",
    "locale",
    "tma_is_premium"
  ];
  var BrowserEventDispatcher = class {
    constructor() {
      this.window = getWindow();
    }
    /**
     * Dispatches an event with the given name and details to the browser window.
     * @param eventName - The name of the event to dispatch.
     * @param eventDetails - The details of the event to dispatch.
     * @returns A promise that resolves when the event has been dispatched.
     */
    dispatchEvent(eventName, eventDetails) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a;
        const event = new CustomEvent(eventName, { detail: eventDetails });
        (_a = this.window) === null || _a === void 0 ? void 0 : _a.dispatchEvent(event);
      });
    }
    /**
     * Adds an event listener to the browser window.
     * @param eventName - The name of the event to listen for.
     * @param listener - The listener to add.
     * @param options - The options for the listener.
     * @returns A function that removes the listener.
     */
    addEventListener(eventName, listener, options) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a;
        (_a = this.window) === null || _a === void 0 ? void 0 : _a.addEventListener(eventName, listener, options);
        return () => {
          var _a2;
          return (_a2 = this.window) === null || _a2 === void 0 ? void 0 : _a2.removeEventListener(eventName, listener);
        };
      });
    }
  };
  function buildVersionInfo(version) {
    return {
      "@tonconnect/sdk": version.ton_connect_sdk_lib || "",
      "@tonconnect/ui": version.ton_connect_ui_lib || ""
    };
  }
  function buildTonConnectEvent(detail) {
    var _a, _b, _c, _d, _e, _f, _g, _h;
    return {
      versions: buildVersionInfo(detail.custom_data),
      network_id: (_a = detail.custom_data.chain_id) !== null && _a !== void 0 ? _a : "",
      client_id: (_b = detail.custom_data.client_id) !== null && _b !== void 0 ? _b : "",
      wallet_id: (_c = detail.custom_data.wallet_id) !== null && _c !== void 0 ? _c : "",
      wallet_address: (_d = detail.wallet_address) !== null && _d !== void 0 ? _d : "",
      wallet_app_name: (_e = detail.wallet_type) !== null && _e !== void 0 ? _e : "",
      wallet_app_version: (_f = detail.wallet_version) !== null && _f !== void 0 ? _f : "",
      wallet_state_init: (_g = detail.wallet_state_init) !== null && _g !== void 0 ? _g : "",
      trace_id: (_h = detail.trace_id) !== null && _h !== void 0 ? _h : void 0
    };
  }
  function bindEventsTo(eventDispatcher, analytics) {
    eventDispatcher.addEventListener("ton-connect-ui-wallet-modal-opened", (event) => {
      var _a;
      const { detail } = event;
      analytics.emitConnectionStarted({
        client_id: detail.client_id || "",
        versions: buildVersionInfo(detail.custom_data),
        main_screen: detail.visible_wallets,
        trace_id: (_a = detail.trace_id) !== null && _a !== void 0 ? _a : void 0
      });
    });
    eventDispatcher.addEventListener("ton-connect-ui-selected-wallet", (event) => {
      var _a, _b;
      const { detail } = event;
      analytics.emitConnectionSelectedWallet({
        client_id: detail.client_id || "",
        versions: buildVersionInfo(detail.custom_data),
        main_screen: detail.visible_wallets,
        wallets_menu: detail.wallets_menu,
        trace_id: (_a = detail.trace_id) !== null && _a !== void 0 ? _a : void 0,
        wallet_app_name: (_b = detail.wallet_type) !== null && _b !== void 0 ? _b : "",
        wallet_redirect_method: detail.wallet_redirect_method,
        wallet_redirect_link: detail.wallet_redirect_link
      });
    });
    eventDispatcher.addEventListener("ton-connect-connection-completed", (event) => {
      const { detail } = event;
      analytics.emitConnectionCompleted(buildTonConnectEvent(detail));
    });
    eventDispatcher.addEventListener("ton-connect-connection-error", (event) => {
      var _a, _b;
      const { detail } = event;
      analytics.emitConnectionError({
        client_id: detail.custom_data.client_id || "",
        wallet_id: detail.custom_data.wallet_id || "",
        error_code: (_a = detail.error_code) !== null && _a !== void 0 ? _a : 0,
        error_message: detail.error_message,
        trace_id: (_b = detail.trace_id) !== null && _b !== void 0 ? _b : void 0
      });
    });
    eventDispatcher.addEventListener("ton-connect-disconnection", (event) => {
      const { detail } = event;
      analytics.emitDisconnection(buildTonConnectEvent(detail));
    });
    eventDispatcher.addEventListener("ton-connect-transaction-sent-for-signature", (event) => {
      const { detail } = event;
      analytics.emitTransactionSent(buildTonConnectEvent(detail));
    });
    eventDispatcher.addEventListener("ton-connect-transaction-signed", (event) => {
      const { detail } = event;
      analytics.emitTransactionSigned(Object.assign(Object.assign({}, buildTonConnectEvent(detail)), { signed_boc: event.detail.signed_transaction }));
    });
    eventDispatcher.addEventListener("ton-connect-transaction-signing-failed", (event) => {
      var _a;
      const { detail } = event;
      analytics.emitTransactionSigningFailed(Object.assign(Object.assign({}, buildTonConnectEvent(detail)), { valid_until: Number(detail.valid_until), messages: detail.messages.map((message) => {
        var _a2, _b, _c, _d;
        return {
          address: (_a2 = message.address) !== null && _a2 !== void 0 ? _a2 : "",
          amount: (_b = message.amount) !== null && _b !== void 0 ? _b : "",
          payload: (_c = message.payload) !== null && _c !== void 0 ? _c : "",
          state_init: (_d = message.state_init) !== null && _d !== void 0 ? _d : ""
        };
      }), error_message: detail.error_message, error_code: (_a = detail.error_code) !== null && _a !== void 0 ? _a : 0 }));
    });
    eventDispatcher.addEventListener("ton-connect-sign-data-request-initiated", (event) => {
      const { detail } = event;
      analytics === null || analytics === void 0 ? void 0 : analytics.emitSignDataRequestInitiated(buildTonConnectEvent(detail));
    });
    eventDispatcher.addEventListener("ton-connect-sign-data-request-completed", (event) => {
      const { detail } = event;
      analytics === null || analytics === void 0 ? void 0 : analytics.emitSignDataRequestCompleted(buildTonConnectEvent(detail));
    });
    eventDispatcher.addEventListener("ton-connect-sign-data-request-failed", (event) => {
      var _a;
      const { detail } = event;
      let signDataValue = "";
      let signDataSchema = void 0;
      if (detail.data.type === "text") {
        signDataValue = detail.data.text;
      }
      if (detail.data.type === "cell") {
        signDataValue = detail.data.cell;
        signDataSchema = detail.data.schema;
      }
      if (detail.data.type === "binary") {
        signDataValue = detail.data.bytes;
      }
      analytics === null || analytics === void 0 ? void 0 : analytics.emitSignDataRequestFailed(Object.assign(Object.assign({}, buildTonConnectEvent(detail)), { sign_data_type: detail.data.type, sign_data_value: signDataValue, sign_data_schema: signDataSchema, error_code: (_a = detail.error_code) !== null && _a !== void 0 ? _a : 0, error_message: detail.error_message }));
    });
  }
  var DefaultEnvironment = class {
    getClientEnvironment() {
      return "";
    }
    getBrowser() {
      return "";
    }
    getLocale() {
      return "";
    }
    getPlatform() {
      return "";
    }
    getTelegramUser() {
      return void 0;
    }
  };
  var state = {};
  function initializeWalletConnect(UniversalConnectorCls, walletConnectOptions) {
    if ((state === null || state === void 0 ? void 0 : state.walletConnectOptions) !== void 0 || (state === null || state === void 0 ? void 0 : state.UniversalConnectorCls) !== void 0) {
      throw new TonConnectError("Wallet Connect already initialized.");
    }
    if (typeof UniversalConnectorCls !== "function" || !("init" in UniversalConnectorCls)) {
      throw new TonConnectError("Initialize UniversalConnectorCls must be set");
    }
    state.UniversalConnectorCls = UniversalConnectorCls;
    state.walletConnectOptions = walletConnectOptions;
  }
  function isWalletConnectInitialized() {
    return state.UniversalConnectorCls !== void 0 && state.walletConnectOptions !== void 0;
  }
  function getUniversalConnector() {
    if (state.UniversalConnectorCls === void 0) {
      throw new TonConnectError("Wallet Connect is not initialized.");
    }
    return state.UniversalConnectorCls;
  }
  function getWalletConnectOptions() {
    if (state.walletConnectOptions === void 0) {
      throw new TonConnectError("Wallet Connect is not initialized.");
    }
    return state.walletConnectOptions;
  }
  var DEFAULT_REQUEST_ID = "0";
  var DEFAULT_EVENT_ID = 0;
  var WalletConnectProvider = class _WalletConnectProvider {
    constructor(connectionStorage) {
      this.connectionStorage = connectionStorage;
      this.type = "injected";
      this.listeners = [];
      this.connector = void 0;
      const { projectId, metadata } = getWalletConnectOptions();
      this.config = {
        networks: [
          {
            namespace: "ton",
            chains: [
              {
                id: -239,
                chainNamespace: "ton",
                caipNetworkId: "ton:-239",
                name: "TON",
                nativeCurrency: { name: "TON", symbol: "TON", decimals: 9 },
                rpcUrls: { default: { http: [] } }
              },
              {
                id: -3,
                chainNamespace: "ton",
                caipNetworkId: "ton:-3",
                name: "TON",
                nativeCurrency: { name: "TON", symbol: "TON", decimals: 9 },
                rpcUrls: { default: { http: [] } }
              }
            ],
            methods: ["ton_sendMessage", "ton_signData"],
            events: []
          }
        ],
        projectId,
        metadata
      };
    }
    static fromStorage(storage) {
      return __awaiter(this, void 0, void 0, function* () {
        return new _WalletConnectProvider(storage);
      });
    }
    initialize() {
      return __awaiter(this, void 0, void 0, function* () {
        if (!this.connector) {
          this.connector = yield getUniversalConnector().init(this.config);
        }
        return this.connector;
      });
    }
    connect(message, options) {
      var _a, _b;
      const traceId = (_a = options === null || options === void 0 ? void 0 : options.traceId) !== null && _a !== void 0 ? _a : UUIDv7();
      const abortController = createAbortController(options === null || options === void 0 ? void 0 : options.signal);
      (_b = this.abortController) === null || _b === void 0 ? void 0 : _b.abort();
      this.abortController = abortController;
      void this._connect(message, {
        traceId,
        signal: abortController.signal,
        abortController
      }).catch((error) => logDebug("WalletConnect connect unexpected error", error));
    }
    _connect(message, options) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b;
        const connector = yield this.initialize();
        if ((_a = options.signal) === null || _a === void 0 ? void 0 : _a.aborted) {
          logDebug("WalletConnect connect aborted before start");
          this.clearAbortController(options.abortController);
          return;
        }
        const tonProof = message.items.find((item) => item.name === "ton_proof");
        const authentication = tonProof ? [
          {
            domain: new URL(this.config.metadata.url).hostname,
            chains: ["ton:-239"],
            nonce: "",
            uri: "ton_proof",
            ttl: 0,
            statement: tonProof.payload
          }
        ] : void 0;
        logDebug("Connecting through this.connector.connect");
        try {
          yield connector.connect({ authentication });
        } catch (error) {
          if ((_b = options.signal) === null || _b === void 0 ? void 0 : _b.aborted) {
            logDebug("WalletConnect connect aborted via signal");
            this.clearAbortController(options.abortController);
            return;
          }
          logDebug("WalletConnect connect error", error);
          const event = {
            id: DEFAULT_EVENT_ID,
            event: "connect_error",
            traceId: options.traceId,
            payload: {
              code: CONNECT_EVENT_ERROR_CODES.USER_REJECTS_ERROR,
              message: "User declined the connection"
            }
          };
          logDebug("WalletConnect connect response:", event);
          this.emit(event);
          this.clearAbortController(options.abortController);
          return;
        }
        logDebug("Connected through this.connector.connect");
        try {
          yield this.onConnect(connector, Object.assign(Object.assign({}, options), { includeTonProof: true }));
        } catch (error) {
          logDebug("WalletConnect onConnect error", error);
          yield this.disconnect({ traceId: options.traceId, signal: options.signal });
        } finally {
          this.clearAbortController(options.abortController);
        }
      });
    }
    restoreConnection(options) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b;
        const traceId = (_a = options === null || options === void 0 ? void 0 : options.traceId) !== null && _a !== void 0 ? _a : UUIDv7();
        const abortController = createAbortController(options === null || options === void 0 ? void 0 : options.signal);
        (_b = this.abortController) === null || _b === void 0 ? void 0 : _b.abort();
        this.abortController = abortController;
        if (abortController.signal.aborted) {
          return;
        }
        try {
          logDebug("Restoring WalletConnect connection...");
          const storedConnection = yield this.connectionStorage.getWalletConnectConnection();
          if (!storedConnection || abortController.signal.aborted) {
            return;
          }
          const connector = yield this.initialize();
          if (abortController.signal.aborted) {
            return;
          }
          yield this.onConnect(connector, {
            includeTonProof: false,
            traceId,
            signal: abortController.signal
          });
          logDebug("WalletConnect successfully restored.");
        } catch (error) {
          logDebug("WalletConnect restore error", error);
          yield this.disconnect({ traceId, signal: abortController.signal });
        } finally {
          this.clearAbortController(abortController);
        }
      });
    }
    closeConnection() {
      var _a;
      (_a = this.abortController) === null || _a === void 0 ? void 0 : _a.abort();
      this.abortController = void 0;
      void this.disconnect();
    }
    disconnect(options) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b;
        const abortController = createAbortController(options === null || options === void 0 ? void 0 : options.signal);
        (_a = this.abortController) === null || _a === void 0 ? void 0 : _a.abort();
        this.abortController = abortController;
        if (abortController.signal.aborted) {
          return;
        }
        try {
          yield this.connectionStorage.removeConnection();
          if (abortController.signal.aborted) {
            return;
          }
          yield (_b = this.connector) === null || _b === void 0 ? void 0 : _b.disconnect();
        } catch (error) {
          logDebug("WalletConnect disconnect error", error);
        } finally {
          this.clearAbortController(abortController);
        }
      });
    }
    sendRequest(request, optionsOrOnRequestSent) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b, _c, _d;
        if (!this.connector) {
          throw new TonConnectError("Wallet Connect not initialized");
        }
        const options = {};
        if (typeof optionsOrOnRequestSent === "function") {
          options.onRequestSent = optionsOrOnRequestSent;
        } else {
          options.onRequestSent = optionsOrOnRequestSent === null || optionsOrOnRequestSent === void 0 ? void 0 : optionsOrOnRequestSent.onRequestSent;
          options.signal = optionsOrOnRequestSent === null || optionsOrOnRequestSent === void 0 ? void 0 : optionsOrOnRequestSent.signal;
          options.attempts = optionsOrOnRequestSent === null || optionsOrOnRequestSent === void 0 ? void 0 : optionsOrOnRequestSent.attempts;
          options.traceId = optionsOrOnRequestSent === null || optionsOrOnRequestSent === void 0 ? void 0 : optionsOrOnRequestSent.traceId;
        }
        (_a = options.traceId) !== null && _a !== void 0 ? _a : options.traceId = UUIDv7();
        try {
          if ((_b = options.signal) === null || _b === void 0 ? void 0 : _b.aborted) {
            throw new TonConnectError("WalletConnect request aborted");
          }
          logDebug("Send wallet-connect request:", Object.assign(Object.assign({}, request), { id: DEFAULT_REQUEST_ID }));
          if (request.method === "sendTransaction") {
            const _e = JSON.parse(request.params[0]), { network } = _e, sendTransactionPayload = __rest(_e, ["network"]);
            const promise = this.connector.request({
              method: "ton_sendMessage",
              params: sendTransactionPayload
            }, `ton:${network}`);
            (_c = options === null || options === void 0 ? void 0 : options.onRequestSent) === null || _c === void 0 ? void 0 : _c.call(options);
            const result = yield promise;
            logDebug("Wallet message received:", { result, id: DEFAULT_REQUEST_ID });
            return {
              result,
              id: DEFAULT_REQUEST_ID,
              traceId: options.traceId
            };
          } else if (request.method === "signData") {
            const _f = JSON.parse(request.params[0]), { network } = _f, signDataPayload = __rest(_f, ["network"]);
            const promise = this.connector.request({
              method: "ton_signData",
              params: signDataPayload
            }, `ton:${network}`);
            (_d = options === null || options === void 0 ? void 0 : options.onRequestSent) === null || _d === void 0 ? void 0 : _d.call(options);
            const result = yield promise;
            logDebug("Wallet message received:", { result, id: DEFAULT_REQUEST_ID });
            return { result, traceId: options.traceId, id: DEFAULT_REQUEST_ID };
          } else if (request.method === "disconnect") {
            return {
              id: DEFAULT_REQUEST_ID,
              traceId: options.traceId
            };
          }
        } catch (error) {
          logDebug("WalletConnect request error", error, error.stack);
          const result = yield this.handleWalletConnectError(error, {
            traceId: options.traceId
          });
          logDebug("Wallet message received:", result);
          return result;
        }
        return {
          id: DEFAULT_REQUEST_ID,
          error: { code: DISCONNECT_ERROR_CODES.UNKNOWN_ERROR, message: "Not implemented." },
          traceId: options.traceId
        };
      });
    }
    handleWalletConnectError(error, options) {
      return __awaiter(this, void 0, void 0, function* () {
        if (typeof error === "object" && error !== null) {
          const message = String("message" in error ? error.message : "msg" in error ? error.msg : error);
          if (message.toLowerCase().includes("reject")) {
            return {
              id: DEFAULT_REQUEST_ID,
              traceId: options.traceId,
              error: {
                code: SEND_TRANSACTION_ERROR_CODES.USER_REJECTS_ERROR,
                message
              }
            };
          }
          if (message.toLowerCase().includes("tonvalidationerror")) {
            return {
              id: DEFAULT_REQUEST_ID,
              traceId: options.traceId,
              error: {
                code: SEND_TRANSACTION_ERROR_CODES.BAD_REQUEST_ERROR,
                message
              }
            };
          }
          return {
            id: DEFAULT_REQUEST_ID,
            traceId: options.traceId,
            error: {
              code: SEND_TRANSACTION_ERROR_CODES.UNKNOWN_ERROR,
              message
            }
          };
        }
        return {
          id: DEFAULT_REQUEST_ID,
          traceId: options.traceId,
          error: {
            code: SEND_TRANSACTION_ERROR_CODES.UNKNOWN_ERROR,
            message: String(error)
          }
        };
      });
    }
    listen(callback) {
      this.listeners.push(callback);
      return () => this.listeners = this.listeners.filter((listener) => listener !== callback);
    }
    buildTonProof(connector) {
      var _a, _b, _c;
      const auth = (_a = connector.provider.session.authentication) === null || _a === void 0 ? void 0 : _a[0];
      const iat = (_b = auth === null || auth === void 0 ? void 0 : auth.p) === null || _b === void 0 ? void 0 : _b.iat;
      const statement = (_c = auth === null || auth === void 0 ? void 0 : auth.p) === null || _c === void 0 ? void 0 : _c.statement;
      if (!iat || !statement) {
        return;
      }
      const domain = auth.p.domain;
      return {
        name: "ton_proof",
        proof: {
          timestamp: Math.floor(new Date(iat).getTime() / 1e3),
          domain: {
            lengthBytes: domain.length,
            value: domain
          },
          payload: statement,
          signature: auth.s.s
        }
      };
    }
    onConnect(connector, options) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b, _c, _d;
        if ((_a = options.signal) === null || _a === void 0 ? void 0 : _a.aborted) {
          logDebug("WalletConnect onConnect aborted");
          return;
        }
        const session = connector.provider.session;
        const tonNamespace = session.namespaces["ton"];
        if (!((_b = tonNamespace === null || tonNamespace === void 0 ? void 0 : tonNamespace.accounts) === null || _b === void 0 ? void 0 : _b[0])) {
          yield this.disconnectWithError({
            traceId: options.traceId,
            code: CONNECT_EVENT_ERROR_CODES.BAD_REQUEST_ERROR,
            message: "Connection error. No TON accounts connected."
          });
          return;
        }
        const account = tonNamespace.accounts[0];
        const [, network, address] = account.split(":", 3);
        const publicKey = (_c = session.sessionProperties) === null || _c === void 0 ? void 0 : _c.ton_getPublicKey;
        if (!publicKey) {
          yield this.disconnectWithError({
            traceId: options.traceId,
            code: CONNECT_EVENT_ERROR_CODES.BAD_REQUEST_ERROR,
            message: "Connection error. No sessionProperties.ton_getPublicKey provided."
          });
          return;
        }
        const stateInit = (_d = session.sessionProperties) === null || _d === void 0 ? void 0 : _d.ton_getStateInit;
        if (!stateInit) {
          yield this.disconnectWithError({
            traceId: options.traceId,
            code: CONNECT_EVENT_ERROR_CODES.BAD_REQUEST_ERROR,
            message: "Connection error. No sessionProperties.ton_getStateInit provided."
          });
          return;
        }
        connector.provider.once("session_delete", () => __awaiter(this, void 0, void 0, function* () {
          try {
            yield this.connectionStorage.removeConnection();
            const event = {
              event: "disconnect",
              traceId: UUIDv7(),
              payload: {}
            };
            logDebug("Wallet message received:", event);
            this.emit(event);
          } catch (err) {
            logDebug("Error while deleting session", err);
          }
        }));
        const tonProof = (options === null || options === void 0 ? void 0 : options.includeTonProof) ? this.buildTonProof(connector) : void 0;
        const parsedAddress = isValidUserFriendlyAddress(address) ? toRawAddress(parseUserFriendlyAddress(address)) : address;
        const features = this.buildFeatureList(tonNamespace.methods);
        const payload = {
          items: [
            {
              name: "ton_addr",
              address: parsedAddress,
              network,
              publicKey,
              walletStateInit: stateInit
            },
            ...tonProof ? [tonProof] : []
          ],
          device: {
            appName: "wallet_connect",
            appVersion: "",
            maxProtocolVersion: 2,
            features,
            platform: "browser"
          }
        };
        logDebug("WalletConnect connect response:", {
          event: "connect",
          payload,
          id: DEFAULT_EVENT_ID
        });
        this.emit({ event: "connect", payload, traceId: options.traceId });
        yield this.storeConnection();
      });
    }
    buildFeatureList(methods) {
      const features = [];
      if (methods.includes("ton_sendMessage")) {
        features.push("SendTransaction", {
          name: "SendTransaction",
          maxMessages: 4,
          extraCurrencySupported: false
        });
      }
      if (methods.includes("ton_signData")) {
        features.push({ name: "SignData", types: ["text", "binary", "cell"] });
      }
      return features;
    }
    disconnectWithError(options) {
      return __awaiter(this, void 0, void 0, function* () {
        yield this.disconnect();
        const payload = {
          code: options.code,
          message: options.message
        };
        logDebug("WalletConnect connect response:", {
          event: "connect_error",
          id: DEFAULT_EVENT_ID,
          payload
        });
        this.emit({
          event: "connect_error",
          traceId: options.traceId,
          payload
        });
      });
    }
    clearAbortController(abortController) {
      if (this.abortController === abortController) {
        this.abortController = void 0;
      }
    }
    emit(event, listeners) {
      (listeners !== null && listeners !== void 0 ? listeners : this.listeners).forEach((listener) => listener(event));
    }
    storeConnection() {
      return this.connectionStorage.storeConnection({
        type: "wallet-connect"
      });
    }
  };
  function buildAppRequestPayload(richRequest) {
    switch (richRequest.method) {
      case "sendTransaction": {
        const tx = richRequest.request;
        return Object.assign(Object.assign(Object.assign(Object.assign({ m: "st" }, tx.from ? { f: tx.from } : {}), tx.network ? { n: tx.network } : {}), { vu: tx.validUntil }), buildWireTransactionBody(tx));
      }
      case "signMessage": {
        const msg = richRequest.request;
        return Object.assign(Object.assign(Object.assign(Object.assign({ m: "sm" }, msg.from ? { f: msg.from } : {}), msg.network ? { n: msg.network } : {}), { vu: msg.validUntil }), buildWireTransactionBody(msg));
      }
      case "signData": {
        const sd = richRequest.request;
        const base = Object.assign(Object.assign({ m: "sd" }, sd.from ? { f: sd.from } : {}), sd.network ? { n: sd.network } : {});
        switch (sd.type) {
          case "text":
            return Object.assign(Object.assign({}, base), { t: "text", tx: sd.text });
          case "binary":
            return Object.assign(Object.assign({}, base), { t: "binary", b: sd.bytes });
          case "cell":
            return Object.assign(Object.assign({}, base), { t: "cell", s: sd.schema, c: sd.cell });
        }
      }
    }
  }
  function buildWireTransactionBody(tx) {
    if (hasItems(tx)) {
      return {
        i: tx.items.map((item) => buildWireItem(item))
      };
    }
    return {
      ms: tx.messages.map((msg) => {
        const wire = {
          a: msg.address,
          am: msg.amount
        };
        if (msg.payload) {
          wire.p = normalizeBase64(msg.payload);
        }
        if (msg.stateInit) {
          wire.si = normalizeBase64(msg.stateInit);
        }
        if (msg.extraCurrency) {
          wire.ec = msg.extraCurrency;
        }
        return wire;
      })
    };
  }
  function buildWireItem(item) {
    switch (item.type) {
      case "ton":
        return Object.assign(Object.assign(Object.assign({ t: "ton", a: item.address, am: item.amount }, item.payload ? { p: normalizeBase64(item.payload) } : {}), item.stateInit ? { si: normalizeBase64(item.stateInit) } : {}), item.extraCurrency ? { ec: item.extraCurrency } : {});
      case "jetton":
        return Object.assign(Object.assign(Object.assign(Object.assign(Object.assign(Object.assign({ t: "jetton", ma: item.master, d: item.destination, am: item.amount }, item.attachAmount ? { aa: item.attachAmount } : {}), item.responseDestination ? { rd: item.responseDestination } : {}), item.customPayload ? { cp: normalizeBase64(item.customPayload) } : {}), item.forwardAmount ? { fa: item.forwardAmount } : {}), item.forwardPayload ? { fp: normalizeBase64(item.forwardPayload) } : {}), item.queryId ? { qi: item.queryId } : {});
      case "nft":
        return Object.assign(Object.assign(Object.assign(Object.assign(Object.assign(Object.assign({ t: "nft", na: item.nftAddress, no: item.newOwner }, item.attachAmount ? { aa: item.attachAmount } : {}), item.responseDestination ? { rd: item.responseDestination } : {}), item.customPayload ? { cp: normalizeBase64(item.customPayload) } : {}), item.forwardAmount ? { fa: item.forwardAmount } : {}), item.forwardPayload ? { fp: normalizeBase64(item.forwardPayload) } : {}), item.queryId ? { qi: item.queryId } : {});
    }
  }
  var WireEmbeddedRequestParser = class {
    constructor() {
      this.convertToWireEmbeddedRequest = buildAppRequestPayload;
    }
    isError(response) {
      return "error" in response;
    }
    convertFromRpcResponse(method, response) {
      if (this.isError(response)) {
        return { ok: false, error: response.error };
      }
      switch (method) {
        case "sendTransaction":
          return { ok: true, result: { boc: response.result } };
        case "signMessage": {
          return {
            ok: true,
            result: {
              internalBoc: response.result.internalBoc
            }
          };
        }
        case "signData": {
          return { ok: true, result: response.result };
        }
        default:
          throw new Error(`Unexpected embedded request method: ${method}`);
      }
    }
  };
  var wireRequestParser = new WireEmbeddedRequestParser();
  var Consumable = class {
    /**
     * Wrap `value`. If `value` is already a `Consumable`, returns it
     * unchanged so the type stays flat.
     */
    constructor(value) {
      this.__isConsumable = true;
      if (value && typeof value === "object" && value.__isConsumable) {
        return value;
      }
      this.value = value;
    }
    /** Read the wrapped value without consuming it. `undefined` once consumed. */
    peek() {
      return this.value;
    }
    /**
     * Take ownership of the wrapped value. The next call returns `undefined`.
     * Use this when the value is about to be acted on exactly once.
     */
    consume() {
      logDebug("Consuming object", this.value);
      const value = this.value;
      this.value = void 0;
      return value;
    }
    /** `true` once {@link Consumable.consume} has been called. */
    get consumed() {
      return this.value === void 0;
    }
  };
  var TonConnect = class {
    /**
     * Fetch the wallets-list registry without instantiating a connector.
     * Equivalent to {@link ITonConnect.getWallets} but usable before
     * constructing a `TonConnect`.
     */
    static getWallets() {
      return this.walletsList.getWallets();
    }
    /**
     * Shows if the wallet is connected right now.
     */
    get connected() {
      return this._wallet !== null;
    }
    /**
     * Current connected account or null if no account is connected.
     */
    get account() {
      var _a;
      return ((_a = this._wallet) === null || _a === void 0 ? void 0 : _a.account) || null;
    }
    /**
     * Current connected wallet or null if no account is connected.
     */
    get wallet() {
      return this._wallet;
    }
    set wallet(value) {
      this._wallet = value;
      this.statusChangeSubscriptions.forEach((callback) => callback(this._wallet));
    }
    /**
     * Create a new connector. See {@link TonConnectOptions} for every option;
     * the most common shape is `{ manifestUrl }` in the browser, and
     * `{ manifestUrl, storage }` in Node.js / non-browser hosts.
     *
     * @throws `DappMetadataError` when `manifestUrl` is omitted and
     *         `window.location.origin` is not available.
     */
    constructor(options) {
      var _a, _b, _c;
      this._wallet = null;
      this.provider = null;
      this.statusChangeSubscriptions = [];
      this.statusChangeErrorSubscriptions = [];
      const manifestUrl = (options === null || options === void 0 ? void 0 : options.manifestUrl) || getWebPageManifest();
      this.dappSettings = {
        manifestUrl,
        storage: (options === null || options === void 0 ? void 0 : options.storage) || new DefaultStorage()
      };
      this.walletsRequiredFeatures = options === null || options === void 0 ? void 0 : options.walletsRequiredFeatures;
      this.environment = (_a = options === null || options === void 0 ? void 0 : options.environment) !== null && _a !== void 0 ? _a : new DefaultEnvironment();
      this.walletsList = new WalletsListManager({
        walletsListSource: options === null || options === void 0 ? void 0 : options.walletsListSource,
        cacheTTLMs: options === null || options === void 0 ? void 0 : options.walletsListCacheTTLMs,
        onDownloadDurationMeasured: (duration) => {
          var _a2;
          (_a2 = this.analytics) === null || _a2 === void 0 ? void 0 : _a2.setWalletListDownloadDuration(duration);
        }
      });
      const eventDispatcher = (_b = options === null || options === void 0 ? void 0 : options.eventDispatcher) !== null && _b !== void 0 ? _b : new BrowserEventDispatcher();
      this.tracker = new TonConnectTracker({
        eventDispatcher,
        tonConnectSdkVersion
      });
      this.environment = (_c = options === null || options === void 0 ? void 0 : options.environment) !== null && _c !== void 0 ? _c : new DefaultEnvironment();
      this.initAnalytics(manifestUrl, eventDispatcher, options);
      if (!this.dappSettings.manifestUrl) {
        throw new DappMetadataError("Dapp tonconnect-manifest.json must be specified if window.location.origin is undefined. See more https://github.com/ton-connect/docs/blob/main/requests-responses.md#app-manifest");
      }
      this.bridgeConnectionStorage = new BridgeConnectionStorage(this.dappSettings.storage, this.walletsList);
      if (!(options === null || options === void 0 ? void 0 : options.disableAutoPauseConnection)) {
        this.addWindowFocusAndBlurSubscriptions();
      }
    }
    /**
     * Returns available wallets list.
     */
    getWallets() {
      return this.walletsList.getWallets();
    }
    /**
     * Allows to subscribe to connection status changes and handle connection errors.
     * @param callback will be called after connections status changes with actual wallet or null.
     * @param errorsHandler (optional) will be called with some instance of TonConnectError when connect error is received.
     * @returns unsubscribe callback.
     */
    onStatusChange(callback, errorsHandler) {
      this.statusChangeSubscriptions.push(callback);
      if (errorsHandler) {
        this.statusChangeErrorSubscriptions.push(errorsHandler);
      }
      return () => {
        this.statusChangeSubscriptions = this.statusChangeSubscriptions.filter((item) => item !== callback);
        if (errorsHandler) {
          this.statusChangeErrorSubscriptions = this.statusChangeErrorSubscriptions.filter((item) => item !== errorsHandler);
        }
      };
    }
    // eslint-disable-next-line complexity
    connect(wallet, requestOrOptions, additionalOptions) {
      var _a, _b, _c, _d;
      const options = Object.assign({}, additionalOptions);
      if (typeof requestOrOptions === "object" && requestOrOptions !== null && "tonProof" in requestOrOptions) {
        options.request = requestOrOptions;
      }
      if (typeof requestOrOptions === "object" && requestOrOptions !== null && ("openingDeadlineMS" in requestOrOptions || "signal" in requestOrOptions || "request" in requestOrOptions || "traceId" in requestOrOptions)) {
        options.request = requestOrOptions === null || requestOrOptions === void 0 ? void 0 : requestOrOptions.request;
        options.openingDeadlineMS = requestOrOptions === null || requestOrOptions === void 0 ? void 0 : requestOrOptions.openingDeadlineMS;
        options.signal = requestOrOptions === null || requestOrOptions === void 0 ? void 0 : requestOrOptions.signal;
        options.embeddedRequest = requestOrOptions === null || requestOrOptions === void 0 ? void 0 : requestOrOptions.embeddedRequest;
      }
      const embeddedRequest = new Consumable(options.embeddedRequest);
      if (options.request) {
        const validationError = validateConnectAdditionalRequest(options.request);
        if (validationError) {
          if (isQaModeEnabled()) {
            console.error("ConnectAdditionalRequest validation failed: " + validationError);
          } else {
            throw new TonConnectError("ConnectAdditionalRequest validation failed: " + validationError);
          }
        }
      }
      if (embeddedRequest.peek()) {
        const validationError = validateEmbeddedRequest(embeddedRequest.peek());
        if (validationError) {
          if (isQaModeEnabled()) {
            console.error("EmbeddedRequest validation failed: " + validationError);
          } else {
            throw new TonConnectError("EmbeddedRequest validation failed: " + validationError);
          }
        }
      }
      if (this.connected) {
        throw new WalletAlreadyConnectedError();
      }
      const abortController = createAbortController(options === null || options === void 0 ? void 0 : options.signal);
      (_a = this.abortController) === null || _a === void 0 ? void 0 : _a.abort();
      this.abortController = abortController;
      if (abortController.signal.aborted) {
        throw new TonConnectError("Connection was aborted");
      }
      (_b = this.provider) === null || _b === void 0 ? void 0 : _b.closeConnection();
      this.provider = this.createProvider(wallet);
      abortController.signal.addEventListener("abort", () => {
        var _a2;
        (_a2 = this.provider) === null || _a2 === void 0 ? void 0 : _a2.closeConnection();
        this.provider = null;
      });
      const traceId = (_c = options === null || options === void 0 ? void 0 : options.traceId) !== null && _c !== void 0 ? _c : UUIDv7();
      this.tracker.trackConnectionStarted(traceId);
      const peeked = embeddedRequest.peek();
      const wireConsumable = peeked ? new Consumable(wireRequestParser.convertToWireEmbeddedRequest(peeked)) : void 0;
      const url = this.provider.connect(this.createConnectRequest(options === null || options === void 0 ? void 0 : options.request), {
        openingDeadlineMS: options === null || options === void 0 ? void 0 : options.openingDeadlineMS,
        signal: abortController.signal,
        traceId,
        embeddedRequest: wireConsumable
      });
      if (wireConsumable === null || wireConsumable === void 0 ? void 0 : wireConsumable.consumed) {
        this.pendingEmbeddedRequestMethod = (_d = embeddedRequest.consume()) === null || _d === void 0 ? void 0 : _d.method;
      }
      return url;
    }
    /**
     * Try to restore existing session and reconnect to the corresponding wallet. Call it immediately when your app is loaded.
     */
    restoreConnection(options) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b, _c;
        const traceId = (_a = options === null || options === void 0 ? void 0 : options.traceId) !== null && _a !== void 0 ? _a : UUIDv7();
        this.tracker.trackConnectionRestoringStarted(traceId);
        const abortController = createAbortController(options === null || options === void 0 ? void 0 : options.signal);
        (_b = this.abortController) === null || _b === void 0 ? void 0 : _b.abort();
        this.abortController = abortController;
        if (abortController.signal.aborted) {
          this.tracker.trackConnectionRestoringError("Connection restoring was aborted", traceId);
          return;
        }
        const [bridgeConnectionType, embeddedWallet] = yield Promise.all([
          this.bridgeConnectionStorage.storedConnectionType(),
          this.walletsList.getEmbeddedWallet()
        ]);
        if (abortController.signal.aborted) {
          this.tracker.trackConnectionRestoringError("Connection restoring was aborted", traceId);
          return;
        }
        let provider = null;
        try {
          switch (bridgeConnectionType) {
            case "http":
              provider = yield BridgeProvider.fromStorage(this.bridgeConnectionStorage, this.analytics);
              break;
            case "injected":
              provider = yield InjectedProvider.fromStorage(this.bridgeConnectionStorage, this.analytics);
              break;
            case "wallet-connect":
              provider = yield WalletConnectProvider.fromStorage(this.bridgeConnectionStorage);
              break;
            default:
              if (embeddedWallet) {
                provider = this.createProvider(embeddedWallet);
              } else {
                return;
              }
          }
        } catch (err) {
          logDebug("Provider is not restored", err);
          this.tracker.trackConnectionRestoringError("Provider is not restored", traceId);
          yield this.bridgeConnectionStorage.removeConnection();
          provider === null || provider === void 0 ? void 0 : provider.closeConnection();
          provider = null;
          return;
        }
        if (abortController.signal.aborted) {
          provider === null || provider === void 0 ? void 0 : provider.closeConnection();
          this.tracker.trackConnectionRestoringError("Connection restoring was aborted", traceId);
          return;
        }
        if (!provider) {
          logError("Provider is not restored");
          this.tracker.trackConnectionRestoringError("Provider is not restored", traceId);
          return;
        }
        (_c = this.provider) === null || _c === void 0 ? void 0 : _c.closeConnection();
        this.provider = provider;
        provider.listen(this.walletEventsListener.bind(this));
        const onAbortRestore = () => {
          this.tracker.trackConnectionRestoringError("Connection restoring was aborted", traceId);
          provider === null || provider === void 0 ? void 0 : provider.closeConnection();
          provider = null;
        };
        abortController.signal.addEventListener("abort", onAbortRestore);
        const restoreConnectionTask = callForSuccess((_options) => __awaiter(this, void 0, void 0, function* () {
          yield provider === null || provider === void 0 ? void 0 : provider.restoreConnection({
            openingDeadlineMS: options === null || options === void 0 ? void 0 : options.openingDeadlineMS,
            signal: _options.signal,
            traceId
          });
          abortController.signal.removeEventListener("abort", onAbortRestore);
          if (this.connected) {
            const sessionInfo = this.getSessionInfo();
            this.tracker.trackConnectionRestoringCompleted(this.wallet, sessionInfo, traceId);
          } else {
            this.tracker.trackConnectionRestoringError("Connection restoring failed", traceId);
          }
        }), {
          attempts: Number.MAX_SAFE_INTEGER,
          delayMs: 2e3,
          signal: options === null || options === void 0 ? void 0 : options.signal
        });
        const restoreConnectionTimeout = new Promise(
          (resolve) => setTimeout(() => resolve(), 12e3)
          // connection deadline
        );
        return Promise.race([restoreConnectionTask, restoreConnectionTimeout]);
      });
    }
    sendTransaction(transaction, optionsOrOnRequestSent) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b, _c, _d;
        const options = {};
        if (typeof optionsOrOnRequestSent === "function") {
          options.onRequestSent = optionsOrOnRequestSent;
        } else {
          options.onRequestSent = optionsOrOnRequestSent === null || optionsOrOnRequestSent === void 0 ? void 0 : optionsOrOnRequestSent.onRequestSent;
          options.signal = optionsOrOnRequestSent === null || optionsOrOnRequestSent === void 0 ? void 0 : optionsOrOnRequestSent.signal;
          options.traceId = optionsOrOnRequestSent === null || optionsOrOnRequestSent === void 0 ? void 0 : optionsOrOnRequestSent.traceId;
        }
        const validationError = validateSendTransactionRequest(transaction);
        if (validationError) {
          if (isQaModeEnabled()) {
            console.error("SendTransactionRequest validation failed: " + validationError);
          } else {
            throw new TonConnectError("SendTransactionRequest validation failed: " + validationError);
          }
        }
        const abortController = createAbortController(options === null || options === void 0 ? void 0 : options.signal);
        if (abortController.signal.aborted) {
          throw new TonConnectError("Transaction sending was aborted");
        }
        this.checkConnection();
        const { requiredMessagesNumber, requireExtraCurrencies, requiredItemTypes } = this.extractRequiredFeatures(transaction);
        checkSendTransactionSupport(this.wallet.device.features, {
          requiredMessagesNumber,
          requireExtraCurrencies,
          requiredItemTypes
        });
        const sessionInfo = this.getSessionInfo();
        const traceId = (_a = options === null || options === void 0 ? void 0 : options.traceId) !== null && _a !== void 0 ? _a : UUIDv7();
        this.tracker.trackTransactionSentForSignature(this.wallet, transaction, sessionInfo, traceId);
        const from = transaction.from || this.account.address;
        const network = transaction.network || this.account.chain;
        if (((_b = this.wallet) === null || _b === void 0 ? void 0 : _b.account.chain) && network !== this.wallet.account.chain) {
          if (!isQaModeEnabled()) {
            throw new WalletWrongNetworkError("Wallet connected to a wrong network", {
              cause: {
                expectedChainId: (_c = this.wallet) === null || _c === void 0 ? void 0 : _c.account.chain,
                actualChainId: network
              }
            });
          }
          console.error("Wallet connected to a wrong network", {
            expectedChainId: (_d = this.wallet) === null || _d === void 0 ? void 0 : _d.account.chain,
            actualChainId: network
          });
        }
        const rpcPayload = hasItems(transaction) ? this.buildItemsRpcPayload(transaction, from, network) : this.buildMessagesRpcPayload(transaction, from, network);
        const response = yield this.provider.sendRequest(sendTransactionParser.convertToRpcRequest(rpcPayload), {
          onRequestSent: options.onRequestSent,
          signal: abortController.signal,
          traceId
        });
        if (sendTransactionParser.isError(response)) {
          this.tracker.trackTransactionSigningFailed(this.wallet, transaction, response.error.message, response.error.code, sessionInfo, traceId);
          return sendTransactionParser.parseAndThrowError(response);
        }
        const result = sendTransactionParser.convertFromRpcResponse(response);
        this.tracker.trackTransactionSigned(this.wallet, transaction, result, sessionInfo, traceId);
        return Object.assign(Object.assign({}, result), { traceId: response.traceId });
      });
    }
    extractRequiredFeatures(transaction) {
      var _a;
      const useItems = hasItems(transaction);
      const requiredMessagesNumber = useItems ? transaction.items.length : transaction.messages.length;
      const requireExtraCurrencies = useItems ? (_a = transaction.items) === null || _a === void 0 ? void 0 : _a.filter((i) => i.type === "ton").some((m) => m.extraCurrency && Object.keys(m.extraCurrency).length > 0) : transaction.messages.some((m) => m.extraCurrency && Object.keys(m.extraCurrency).length > 0);
      const requiredItemTypes = useItems ? [...new Set(transaction.items.map((item) => item.type))] : void 0;
      return { requiredMessagesNumber, requireExtraCurrencies, requiredItemTypes };
    }
    signData(data, options) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b, _c, _d;
        const abortController = createAbortController(options === null || options === void 0 ? void 0 : options.signal);
        if (abortController.signal.aborted) {
          throw new TonConnectError("data sending was aborted");
        }
        const validationError = validateSignDataPayload(data);
        if (validationError) {
          if (isQaModeEnabled()) {
            console.error("SignDataPayload validation failed: " + validationError);
          } else {
            throw new TonConnectError("SignDataPayload validation failed: " + validationError);
          }
        }
        this.checkConnection();
        checkSignDataSupport(this.wallet.device.features, { requiredTypes: [data.type] });
        const sessionInfo = this.getSessionInfo();
        const traceId = (_a = options === null || options === void 0 ? void 0 : options.traceId) !== null && _a !== void 0 ? _a : UUIDv7();
        this.tracker.trackDataSentForSignature(this.wallet, data, sessionInfo, traceId);
        const from = data.from || this.account.address;
        const network = data.network || this.account.chain;
        if (((_b = this.wallet) === null || _b === void 0 ? void 0 : _b.account.chain) && network !== this.wallet.account.chain) {
          if (!isQaModeEnabled()) {
            throw new WalletWrongNetworkError("Wallet connected to a wrong network", {
              cause: {
                expectedChainId: (_c = this.wallet) === null || _c === void 0 ? void 0 : _c.account.chain,
                actualChainId: network
              }
            });
          }
          console.error("Wallet connected to a wrong network", {
            expectedChainId: (_d = this.wallet) === null || _d === void 0 ? void 0 : _d.account.chain,
            actualChainId: network
          });
        }
        const response = yield this.provider.sendRequest(signDataParser.convertToRpcRequest(Object.assign(Object.assign(Object.assign({}, data), data.type === "cell" ? { cell: normalizeBase64(data.cell) } : {}), {
          from,
          network
        })), { onRequestSent: options === null || options === void 0 ? void 0 : options.onRequestSent, signal: abortController.signal, traceId });
        if (signDataParser.isError(response)) {
          this.tracker.trackDataSigningFailed(this.wallet, data, response.error.message, response.error.code, sessionInfo, traceId);
          return signDataParser.parseAndThrowError(response);
        }
        const result = signDataParser.convertFromRpcResponse(response);
        this.tracker.trackDataSigned(this.wallet, data, result, sessionInfo, traceId);
        return Object.assign(Object.assign({}, result), { traceId });
      });
    }
    signMessage(message, options) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b, _c, _d;
        const abortController = createAbortController(options === null || options === void 0 ? void 0 : options.signal);
        if (abortController.signal.aborted) {
          throw new TonConnectError("Message signing was aborted");
        }
        const validationError = validateSignMessageRequest(message);
        if (validationError) {
          if (isQaModeEnabled()) {
            console.error("SignMessageRequest validation failed: " + validationError);
          } else {
            throw new TonConnectError("SignMessageRequest validation failed: " + validationError);
          }
        }
        this.checkConnection();
        const { requiredMessagesNumber, requireExtraCurrencies, requiredItemTypes } = this.extractRequiredFeatures(message);
        checkSignMessageSupport(this.wallet.device.features, {
          requiredMessagesNumber,
          requireExtraCurrencies,
          requiredItemTypes
        });
        const traceId = (_a = options === null || options === void 0 ? void 0 : options.traceId) !== null && _a !== void 0 ? _a : UUIDv7();
        const from = message.from || this.account.address;
        const network = message.network || this.account.chain;
        if (((_b = this.wallet) === null || _b === void 0 ? void 0 : _b.account.chain) && network !== this.wallet.account.chain) {
          if (!isQaModeEnabled()) {
            throw new WalletWrongNetworkError("Wallet connected to a wrong network", {
              cause: {
                expectedChainId: (_c = this.wallet) === null || _c === void 0 ? void 0 : _c.account.chain,
                actualChainId: network
              }
            });
          }
          console.error("Wallet connected to a wrong network", {
            expectedChainId: (_d = this.wallet) === null || _d === void 0 ? void 0 : _d.account.chain,
            actualChainId: network
          });
        }
        const rpcPayload = hasItems(message) ? this.buildItemsRpcPayload(message, from, network) : this.buildMessagesRpcPayload(message, from, network);
        const response = yield this.provider.sendRequest(signMessageParser.convertToRpcRequest(rpcPayload), {
          onRequestSent: options === null || options === void 0 ? void 0 : options.onRequestSent,
          signal: abortController.signal,
          traceId
        });
        if (signMessageParser.isError(response)) {
          return signMessageParser.parseAndThrowError(response);
        }
        const result = signMessageParser.convertFromRpcResponse(response);
        return Object.assign(Object.assign({}, result), { traceId: response.traceId });
      });
    }
    /**
     * Set desired network for the connection. Can only be set before connecting.
     * If wallet connects with a different chain, the SDK will throw an error and abort connection.
     * @param network desired network id (e.g., '-239', '-3', or custom). Pass undefined to allow any network.
     */
    setConnectionNetwork(network) {
      if (this.connected) {
        throw new TonConnectError("Cannot change network while wallet is connected");
      }
      this.desiredChainId = network;
    }
    /**
     * Disconnect from the connected wallet and drop current session.
     */
    disconnect(options) {
      return __awaiter(this, void 0, void 0, function* () {
        var _a, _b;
        if (!this.connected) {
          throw new WalletNotConnectedError();
        }
        const abortController = createAbortController(options === null || options === void 0 ? void 0 : options.signal);
        const prevAbortController = this.abortController;
        this.abortController = abortController;
        if (abortController.signal.aborted) {
          throw new TonConnectError("Disconnect was aborted");
        }
        const traceId = (_a = options === null || options === void 0 ? void 0 : options.traceId) !== null && _a !== void 0 ? _a : UUIDv7();
        this.onWalletDisconnected("dapp", { traceId });
        yield (_b = this.provider) === null || _b === void 0 ? void 0 : _b.disconnect({
          signal: abortController.signal,
          traceId
        });
        prevAbortController === null || prevAbortController === void 0 ? void 0 : prevAbortController.abort();
      });
    }
    /**
     * Gets the current session ID if available.
     * @returns session ID string or null if not available.
     */
    getSessionId() {
      return __awaiter(this, void 0, void 0, function* () {
        if (!this.provider) {
          return null;
        }
        try {
          const connection = yield this.bridgeConnectionStorage.getConnection();
          if (!connection || connection.type !== "http") {
            return null;
          }
          if ("sessionCrypto" in connection) {
            return connection.sessionCrypto.sessionId;
          } else {
            return connection.session.sessionCrypto.sessionId;
          }
        } catch (_a) {
          return null;
        }
      });
    }
    getSessionInfo() {
      var _a;
      if (((_a = this.provider) === null || _a === void 0 ? void 0 : _a.type) !== "http") {
        return null;
      }
      if (!("session" in this.provider)) {
        return null;
      }
      try {
        const session = this.provider.session;
        if (!session) {
          return null;
        }
        const clientId = session.sessionCrypto.sessionId;
        let walletId = null;
        if ("walletPublicKey" in session) {
          walletId = session.walletPublicKey;
        }
        return { clientId, walletId };
      } catch (_b) {
        return null;
      }
    }
    buildMessagesRpcPayload(transaction, from, network) {
      return {
        from,
        network,
        valid_until: transaction.validUntil,
        messages: transaction.messages.map((_a) => {
          var { extraCurrency, payload, stateInit } = _a, msg = __rest(_a, ["extraCurrency", "payload", "stateInit"]);
          return Object.assign(Object.assign({}, msg), { payload: normalizeBase64(payload), stateInit: normalizeBase64(stateInit), extra_currency: extraCurrency });
        })
      };
    }
    buildItemsRpcPayload(transaction, from, network) {
      return {
        from,
        network,
        valid_until: transaction.validUntil,
        items: transaction.items.map((item) => normalizeStructuredItem(item))
      };
    }
    /**
     * Pause bridge HTTP connection. Might be helpful, if you want to pause connections while browser tab is unfocused,
     * or if you use SDK with NodeJS and want to save server resources.
     */
    pauseConnection() {
      var _a;
      if (((_a = this.provider) === null || _a === void 0 ? void 0 : _a.type) !== "http") {
        return;
      }
      this.provider.pause();
    }
    /**
     * Unpause bridge HTTP connection if it is paused.
     */
    unPauseConnection() {
      var _a;
      if (((_a = this.provider) === null || _a === void 0 ? void 0 : _a.type) !== "http") {
        return Promise.resolve();
      }
      return this.provider.unPause();
    }
    addWindowFocusAndBlurSubscriptions() {
      const document2 = getDocument();
      if (!document2) {
        return;
      }
      try {
        document2.addEventListener("visibilitychange", () => {
          if (document2.hidden) {
            this.pauseConnection();
          } else {
            this.unPauseConnection().catch(() => {
            });
          }
        });
      } catch (e) {
        logError("Cannot subscribe to the document.visibilitychange: ", e);
      }
    }
    initAnalytics(manifestUrl, eventDispatcher, options) {
      var _a;
      const analyticsSettings = options === null || options === void 0 ? void 0 : options.analytics;
      const mode = (_a = analyticsSettings === null || analyticsSettings === void 0 ? void 0 : analyticsSettings.mode) !== null && _a !== void 0 ? _a : "telemetry";
      if (mode === "off") {
        return;
      }
      const analytics = new AnalyticsManager({
        environment: this.environment,
        mode
      });
      this.analytics = analytics;
      const telegramUser = this.environment.getTelegramUser();
      const sharedAnalyticsData = {
        browser: this.environment.getBrowser(),
        platform: this.environment.getPlatform(),
        manifest_json_url: manifestUrl,
        origin_url: getOriginWithPath,
        locale: this.environment.getLocale()
      };
      if (telegramUser) {
        sharedAnalyticsData.tg_id = telegramUser.id;
        sharedAnalyticsData.tma_is_premium = telegramUser.isPremium;
      }
      bindEventsTo(eventDispatcher, analytics.scoped(sharedAnalyticsData));
    }
    createProvider(wallet) {
      let provider;
      if (!Array.isArray(wallet) && isWalletConnectionSourceJS(wallet)) {
        provider = new InjectedProvider(this.bridgeConnectionStorage, wallet.jsBridgeKey, this.analytics);
      } else if (!Array.isArray(wallet) && isWalletConnectionSourceWalletConnect(wallet)) {
        provider = new WalletConnectProvider(this.bridgeConnectionStorage);
      } else {
        provider = new BridgeProvider(this.bridgeConnectionStorage, wallet, this.analytics);
      }
      provider.listen(this.walletEventsListener.bind(this));
      return provider;
    }
    walletEventsListener(e) {
      switch (e.event) {
        case "connect":
          this.onWalletConnected(e.payload, {
            traceId: e.traceId,
            response: e.response
          });
          break;
        case "connect_error":
          this.tracker.trackConnectionError(e.payload.message, e.payload.code, this.getSessionInfo(), e.traceId);
          const walletError = connectErrorsParser.parseError(e.payload);
          this.onWalletConnectError(walletError);
          break;
        case "disconnect":
          this.onWalletDisconnected("wallet", { traceId: e.traceId });
      }
    }
    onWalletConnected(connectEvent, options) {
      var _a, _b;
      const method = this.pendingEmbeddedRequestMethod;
      this.pendingEmbeddedRequestMethod = void 0;
      const tonAccountItem = connectEvent.items.find((item) => item.name === "ton_addr");
      const tonProofItem = connectEvent.items.find((item) => item.name === "ton_proof");
      if (!tonAccountItem) {
        throw new TonConnectError("ton_addr connection item was not found");
      }
      const hasRequiredFeatures = checkRequiredWalletFeatures(connectEvent.device.features, this.walletsRequiredFeatures);
      if (!hasRequiredFeatures) {
        (_a = this.provider) === null || _a === void 0 ? void 0 : _a.disconnect();
        this.onWalletConnectError(new WalletMissingRequiredFeaturesError("Wallet does not support required features", { cause: { connectEvent } }));
        return;
      }
      const wallet = {
        device: connectEvent.device,
        provider: this.provider.type,
        account: {
          address: tonAccountItem.address,
          chain: tonAccountItem.network,
          walletStateInit: tonAccountItem.walletStateInit,
          publicKey: tonAccountItem.publicKey
        }
      };
      if (this.desiredChainId && wallet.account.chain !== this.desiredChainId) {
        const expectedChainId = this.desiredChainId;
        const actualChainId = wallet.account.chain;
        (_b = this.provider) === null || _b === void 0 ? void 0 : _b.disconnect();
        this.onWalletConnectError(new WalletWrongNetworkError("Wallet connected to a wrong network", {
          cause: { expectedChainId, actualChainId }
        }));
        return;
      }
      if (tonProofItem) {
        const validationError = validateTonProofItemReply(tonProofItem);
        let tonProof = void 0;
        if (validationError) {
          if (isQaModeEnabled()) {
            console.error("TonProofItem validation failed: " + validationError);
          }
          tonProof = {
            name: "ton_proof",
            error: {
              code: CONNECT_ITEM_ERROR_CODES.UNKNOWN_ERROR,
              message: validationError
            }
          };
        } else {
          try {
            if ("proof" in tonProofItem) {
              tonProof = {
                name: "ton_proof",
                proof: {
                  timestamp: tonProofItem.proof.timestamp,
                  domain: {
                    lengthBytes: tonProofItem.proof.domain.lengthBytes,
                    value: tonProofItem.proof.domain.value
                  },
                  payload: tonProofItem.proof.payload,
                  signature: tonProofItem.proof.signature
                }
              };
            } else if ("error" in tonProofItem) {
              tonProof = {
                name: "ton_proof",
                error: {
                  code: tonProofItem.error.code,
                  message: tonProofItem.error.message
                }
              };
            } else {
              throw new TonConnectError("Invalid data format");
            }
          } catch (e) {
            tonProof = {
              name: "ton_proof",
              error: {
                code: CONNECT_ITEM_ERROR_CODES.UNKNOWN_ERROR,
                message: "Invalid data format"
              }
            };
          }
        }
        wallet.connectItems = { tonProof };
      }
      if (options.response && method) {
        wallet.embeddedResponse = wireRequestParser.convertFromRpcResponse(method, options.response);
      }
      this.wallet = wallet;
      const sessionInfo = this.getSessionInfo();
      this.tracker.trackConnectionCompleted(wallet, sessionInfo, options === null || options === void 0 ? void 0 : options.traceId);
    }
    onWalletConnectError(error) {
      this.statusChangeErrorSubscriptions.forEach((errorsHandler) => errorsHandler(error));
      logDebug(error);
      if (error instanceof ManifestNotFoundError || error instanceof ManifestContentErrorError) {
        logError(error);
        throw error;
      }
    }
    onWalletDisconnected(scope, options) {
      const sessionInfo = this.getSessionInfo();
      this.tracker.trackDisconnection(this.wallet, scope, sessionInfo, options === null || options === void 0 ? void 0 : options.traceId);
      this.wallet = null;
    }
    checkConnection() {
      if (!this.connected) {
        throw new WalletNotConnectedError();
      }
    }
    createConnectRequest(request) {
      const items = [
        Object.assign({ name: "ton_addr" }, this.desiredChainId ? { network: this.desiredChainId } : {})
      ];
      if (request === null || request === void 0 ? void 0 : request.tonProof) {
        items.push({
          name: "ton_proof",
          payload: request.tonProof
        });
      }
      return {
        manifestUrl: this.dappSettings.manifestUrl,
        items
      };
    }
  };
  TonConnect.walletsList = new WalletsListManager();
  TonConnect.isWalletInjected = (walletJSKey) => InjectedProvider.isWalletInjected(walletJSKey);
  TonConnect.isInsideWalletBrowser = (walletJSKey) => InjectedProvider.isInsideWalletBrowser(walletJSKey);

  // src/index.ts
  var g = globalThis;
  g.TonConnectSDK = esm_exports;
  var nativeStorage = {
    getItem: (key) => g.__nativeStorageGet(key),
    setItem: (key, value) => g.__nativeStorageSet(key, value),
    removeItem: (key) => g.__nativeStorageRemove(key)
  };
  var instance = null;
  var unsubscribe = null;
  g.__tcCreateEngine = function(manifestUrl) {
    instance = new TonConnect({
      manifestUrl,
      storage: nativeStorage,
      analytics: { mode: "off" }
    });
    unsubscribe = instance.onStatusChange(
      (walletOrNull) => g.__tcEmitEvent(JSON.stringify({ kind: "status", wallet: walletOrNull })),
      (error) => g.__tcEmitEvent(JSON.stringify({ kind: "error", message: String(error) }))
    );
  };
  g.__tcConnect = function(sourceJSON, requestJSON) {
    const source = JSON.parse(sourceJSON);
    const request = requestJSON ? JSON.parse(requestJSON) : void 0;
    return instance.connect(source, request);
  };
  g.__tcRestore = function() {
    return instance.restoreConnection();
  };
  g.__tcSendTransaction = function(txJSON, signal) {
    const tx = JSON.parse(txJSON);
    if (tx.valid_until !== void 0) {
      tx.validUntil = tx.valid_until;
      delete tx.valid_until;
    }
    return instance.sendTransaction(tx, signal ? { signal } : void 0).then((r) => JSON.stringify(r === void 0 ? null : r));
  };
  g.__tcSignData = function(payloadJSON, signal) {
    return instance.signData(JSON.parse(payloadJSON), signal ? { signal } : void 0).then((r) => JSON.stringify(r === void 0 ? null : r));
  };
  g.__tcDisconnect = function() {
    return instance.disconnect();
  };
  g.__tcPause = function() {
    instance == null ? void 0 : instance.pauseConnection();
  };
  g.__tcUnpause = function() {
    instance == null ? void 0 : instance.unPauseConnection();
  };
  g.__tcDestroy = function() {
    if (unsubscribe) {
      unsubscribe();
      unsubscribe = null;
    }
    instance = null;
  };
  g.__tcIsConnected = function() {
    return !!(instance && instance.connected);
  };
  var walletSim = null;
  g.__tcTestWalletCreate = function() {
    walletSim = new SessionCrypto();
    return walletSim.sessionId;
  };
  g.__tcTestWalletEncrypt = function(clientIdHex, json) {
    const bytes = walletSim.encrypt(json, hexToByteArray(clientIdHex));
    let bin = "";
    for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
    return btoa(bin);
  };
  g.__tcTestWalletDecrypt = function(clientIdHex, messageB64) {
    const bin = atob(messageB64);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return walletSim.decrypt(bytes, hexToByteArray(clientIdHex));
  };
})();
