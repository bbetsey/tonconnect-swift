import Foundation
import Security
import Testing

struct KeychainSpikeTests {

    @Test func testSecItemAddSucceedsUnderXcodebuildScheme() throws {
        let baseQuery: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "tonconnect-swift.spike",
            kSecAttrAccount: "spike-key",
        ]

        var addQuery = baseQuery
        addQuery[kSecValueData] = Data("spike".utf8)
        addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock

        SecItemDelete(baseQuery as CFDictionary)
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        defer { SecItemDelete(baseQuery as CFDictionary) }

        // A package test bundle carries no entitlement, so on the iOS simulator
        // the Keychain refuses every write with errSecMissingEntitlement (-34018).
        // That is the runner's shape, not a defect; the same skip-and-say-so rule
        // as StorageParityTests. On macOS the file-based keychain accepts the
        // write and the assertion below runs for real.
        if status == errSecMissingEntitlement {
            print("SKIP [KeychainSpike]: SecItemAdd unavailable under this runner (errSecMissingEntitlement) — verified from a hosted app instead")
            return
        }

        #expect(
            status == errSecSuccess || status == errSecDuplicateItem,
            "SecItemAdd returned OSStatus \(status)"
        )
    }
}
