import JavaScriptCore
import Security

/// crypto.getRandomValues via SecRandomCopyBytes (Apple's CSPRNG).
/// On status != errSecSuccess — fatalError, NEVER a silent fallback
/// (the kit-ios print+undefined path is forbidden: weak randomness breaks the
/// session cryptography without a sound).
public final class SecureRandomPolyfill: JSPolyfill {
    public init() {}

    public func apply(to context: JSContext) {
        let getSecureRandomBytes: @convention(block) (Int) -> JSValue = { length in
            precondition(length > 0, "getSecureRandomBytes: non-positive length \(length)") // V5 Input Validation
            // JSContext.current() — the context invoking the block right now.
            // Do not capture the context from apply(to:): the context holds the
            // block, the block would hold the context — a strong-reference cycle
            // whose leak would break the deinit tests.
            guard let context = JSContext.current() else {
                fatalError("getSecureRandomBytes called outside a JSContext")
            }
            var bytes = [UInt8](repeating: 0, count: length)
            let status = SecRandomCopyBytes(kSecRandomDefault, length, &bytes)
            guard status == errSecSuccess else {
                fatalError("SecRandomCopyBytes failed: OSStatus \(status)") // fatal, NOT a fallback
            }
            let array = JSValue(newArrayIn: context)!
            for (i, b) in bytes.enumerated() { array.setObject(b, atIndexedSubscript: i) }
            return array
        }
        context.setObject(getSecureRandomBytes, forKeyedSubscript: "getSecureRandomBytes" as NSString)
        context.evaluateScript("""
            globalThis.crypto = {
                getRandomValues: function(array) {
                    const bytes = getSecureRandomBytes(array.length);
                    for (let i = 0; i < array.length; i++) { array[i] = bytes[i]; }
                    return array;
                }
            };
            """)
    }
}
