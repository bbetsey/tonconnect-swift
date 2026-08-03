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

        #expect(
            status == errSecSuccess || status == errSecDuplicateItem,
            "SecItemAdd returned OSStatus \(status) — errSecMissingEntitlement is -34018"
        )
    }
}
