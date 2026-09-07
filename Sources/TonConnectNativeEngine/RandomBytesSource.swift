import CTweetNacl
import Foundation
import Security

/// The random-bytes tap. Everything internal — invisible outside the package.
protocol RandomBytesSource {
    func fill(_ buffer: UnsafeMutablePointer<UInt8>?, count: Int)
}

/// The production source: the system CSPRNG. A failure is fatal, NOT a silent fallback.
struct SecureRandomBytesSource: RandomBytesSource {
    func fill(_ buffer: UnsafeMutablePointer<UInt8>?, count: Int) {
        guard let buffer else { return }
        let status = SecRandomCopyBytes(kSecRandomDefault, count, buffer)
        guard status == errSecSuccess else {
            fatalError("SecRandomCopyBytes failed: OSStatus \(status)")
        }
    }
}

/// For tests/vectors ONLY: deterministic bytes.
/// Every fill call starts from the beginning of bytes and repeats them
/// cyclically — two identical calls get identical bytes (needed for the vectors).
struct FixedBytesSource: RandomBytesSource {
    let bytes: [UInt8]

    func fill(_ buffer: UnsafeMutablePointer<UInt8>?, count: Int) {
        precondition(!bytes.isEmpty, "FixedBytesSource needs at least one byte")
        guard let buffer else { return }
        for i in 0..<count {
            buffer[i] = bytes[i % bytes.count]
        }
    }
}

enum RandomBytesBridge {
    // PRIVATE + locked accessor: both the write (withSource) and the read (the
    // trampoline) go under ONE lock — otherwise a data race on the multi-word existential.
    //
    // nonisolated(unsafe): Swift 6 rejects mutable static state it cannot see a
    // lock around. The lock IS there — every access below takes it — but the
    // compiler cannot follow that, and the alternative (an OSAllocatedUnfairLock
    // holding the source) would deadlock: withSource holds the lock across body,
    // while the trampoline reads the source from inside body, so the lock must
    // stay recursive. "unsafe" here means "checked by hand", not "unchecked".
    nonisolated(unsafe) private static var current: RandomBytesSource = SecureRandomBytesSource()

    /// install() before the first crypto use — the abort() in the C shim is unreachable in normal operation.
    static let bootstrap: Void = { install() }()

    static func install() {
        tc_set_randombytes { buffer, length in
            RandomBytesBridge.activeSource.fill(buffer, count: Int(length))
        }
    }

    /// Locked read — the only read point of current (for the trampoline).
    private static var activeSource: RandomBytesSource {
        lock.lock(); defer { lock.unlock() }
        return current
    }

    // NSRecursiveLock, not NSLock: withSource holds the lock across the whole
    // body, while the trampoline reads activeSource under the same lock from inside it.
    private static let lock = NSRecursiveLock()

    /// The ONLY sanctioned way to swap the source in tests:
    /// "lock → substitute → run → restore → unlock".
    /// @Suite(.serialized) serializes tests only within one Suite; different
    /// Suites run in parallel, so only the lock provides atomicity.
    static func withSource<T>(_ source: RandomBytesSource, _ body: () throws -> T) rethrows -> T {
        lock.lock()
        let previous = current
        defer { current = previous; lock.unlock() }
        _ = bootstrap
        current = source
        return try body()
    }
}
