import Foundation
import JavaScriptCore

/// atob/btoa for the JSContext — a critical polyfill:
/// without it the bundle load fails with "ReferenceError: Buffer is not defined"
/// (tweetnacl-util picks its base64 path by typeof atob at module top level).
public struct Base64Polyfill: JSPolyfill {
    public init() {}

    public func apply(to context: JSContext) {
        // Byte-per-char semantics, not UTF-8 — critical for the session crypto's data
        let btoa: @convention(block) (String) -> String = { input in
            Data(input.unicodeScalars.map { UInt8($0.value & 0xFF) }).base64EncodedString()
        }
        let atob: @convention(block) (String) -> String = { input in
            guard let data = Data(base64Encoded: input) else { return "" }
            return String(String.UnicodeScalarView(data.map { Unicode.Scalar($0) }))
        }
        context.setObject(btoa, forKeyedSubscript: "btoa" as NSString)
        context.setObject(atob, forKeyedSubscript: "atob" as NSString)
    }
}
