import JavaScriptCore

/// The mini browser environment the vendored libraries expect:
/// - self: tweetnacl detects the PRNG via self.crypto — without self it throws 'no PRNG'
/// - performance.now: the SDK measures time on the restore/reconnect path
/// - URL/URLSearchParams: the SDK builds universal links and bridge URLs via
///   new URL(...) (a Web API absent in JSC). Only the surface the SDK touches is
///   implemented: absolute-URL parsing, searchParams.append/get, toString.
/// - TextEncoder/TextDecoder: the SDK's crypto encodes strings to bytes before the NaCl box
public final class EnvironmentPolyfill: JSPolyfill {
    public init() {}
    public func apply(to context: JSContext) {
        context.evaluateScript("""
        (function(){
          if (typeof globalThis.self === 'undefined') { globalThis.self = globalThis; }
          if (typeof globalThis.performance === 'undefined') {
            globalThis.performance = { now: function(){ return Date.now(); } };
          }
        if (typeof globalThis.TextEncoder === 'undefined') {
          class TextEncoder {
            encode(str) {
              str = String(str);
              var out = [];
              for (var i = 0; i < str.length; i++) {
                var cp = str.codePointAt(i);
                if (cp > 0xFFFF) i++;
                if (cp < 0x80) out.push(cp);
                else if (cp < 0x800) out.push(0xC0 | (cp >> 6), 0x80 | (cp & 63));
                else if (cp < 0x10000) out.push(0xE0 | (cp >> 12), 0x80 | ((cp >> 6) & 63), 0x80 | (cp & 63));
                else out.push(0xF0 | (cp >> 18), 0x80 | ((cp >> 12) & 63), 0x80 | ((cp >> 6) & 63), 0x80 | (cp & 63));
              }
              return new Uint8Array(out);
            }
          }
          class TextDecoder {
            decode(input) {
              var bytes = input instanceof Uint8Array
                ? input
                : new Uint8Array(input && input.buffer ? input.buffer : input);
              var out = '', i = 0;
              while (i < bytes.length) {
                var b = bytes[i++], cp;
                if (b < 0x80) cp = b;
                else if (b < 0xE0) cp = ((b & 31) << 6) | (bytes[i++] & 63);
                else if (b < 0xF0) cp = ((b & 15) << 12) | ((bytes[i++] & 63) << 6) | (bytes[i++] & 63);
                else cp = ((b & 7) << 18) | ((bytes[i++] & 63) << 12) | ((bytes[i++] & 63) << 6) | (bytes[i++] & 63);
                out += String.fromCodePoint(cp);
              }
              return out;
            }
          }
          globalThis.TextEncoder = TextEncoder;
          globalThis.TextDecoder = TextDecoder;
        }
          if (typeof globalThis.URL === 'undefined') {
            class URLSearchParams {
              constructor(init) {
                this._pairs = [];
                if (typeof init === 'string' && init.length) {
                  var parts = init.split('&');
                  for (var i = 0; i < parts.length; i++) {
                    if (!parts[i]) continue;
                    var eq = parts[i].indexOf('=');
                    var k = eq === -1 ? parts[i] : parts[i].slice(0, eq);
                    var v = eq === -1 ? '' : parts[i].slice(eq + 1);
                    this._pairs.push([decodeURIComponent(k), decodeURIComponent(v)]);
                  }
                }
              }
              append(k, v) { this._pairs.push([String(k), String(v)]); }
              set(k, v) { this.delete(k); this.append(k, v); }
              get(k) {
                for (var i = 0; i < this._pairs.length; i++) {
                  if (this._pairs[i][0] === String(k)) return this._pairs[i][1];
                }
                return null;
              }
              has(k) { return this.get(k) !== null; }
              delete(k) { this._pairs = this._pairs.filter(function(p){ return p[0] !== String(k); }); }
              toString() {
                return this._pairs.map(function(p){
                  return encodeURIComponent(p[0]) + '=' + encodeURIComponent(p[1]);
                }).join('&');
              }
            }
            class URL {
              constructor(url, base) {
                var input = String(url);
                var ABS = /^([a-zA-Z][a-zA-Z0-9+.-]*):\\/\\/([^\\/?#]*)([^?#]*)(\\?[^#]*)?(#.*)?$/;
                var m = input.match(ABS);
                if (!m && base !== undefined) {
                  // Naive relative resolve: enough for the SDK's path concatenation.
                  var b = String(base);
                  input = b.replace(/[?#].*$/, '').replace(/\\/$/, '') + '/' + input.replace(/^\\//, '');
                  m = input.match(ABS);
                }
                if (!m) throw new TypeError('Invalid URL: ' + String(url));
                this.protocol = m[1] + ':';
                this.host = m[2];
                var colon = m[2].indexOf(':');
                this.hostname = colon === -1 ? m[2] : m[2].slice(0, colon);
                this.port = colon === -1 ? '' : m[2].slice(colon + 1);
                this.pathname = m[3] || '';
                this.hash = m[5] || '';
                this.searchParams = new URLSearchParams(m[4] ? m[4].slice(1) : '');
              }
              get origin() { return this.protocol + '//' + this.host; }
              get search() { var s = this.searchParams.toString(); return s ? '?' + s : ''; }
              get href() { return this.protocol + '//' + this.host + this.pathname + this.search + this.hash; }
              toString() { return this.href; }
            }
            globalThis.URLSearchParams = URLSearchParams;
            globalThis.URL = URL;
          }
        })();
        """)
    }
}
