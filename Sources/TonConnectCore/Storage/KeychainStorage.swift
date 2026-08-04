import Foundation
import Security

/// The default session store: `TonConnectStorage` on top of the Security
/// framework. This is the package's only OS-privileged surface — everything else
/// is plain networking — so the session survives app restarts and stays out of
/// backups' plain text.
///
/// Note that the Keychain is unavailable to a package's own test bundle without a
/// host app (`errSecMissingEntitlement`); the suite therefore verifies parity
/// against `InMemoryStorage` and checks the real thing from a hosted app.
public struct KeychainStorage: TonConnectStorage {
    private let service: String

    /// - Parameter service: the Keychain service the session is filed under.
    ///   Override it to keep two dApps inside one app from sharing a session.
    ///
    /// The macOS deprecation is a misuse of the attribute in the service of an
    /// honest diagnostic: nothing here is being replaced, the platform simply is
    /// not supported. `unavailable` would say it better and cannot be used — it
    /// is a hard error, and this type has to stay reachable from the test bundle,
    /// which runs on macOS.
    #if os(macOS)
    @available(macOS, deprecated: 14, message: """
        macOS is not a supported platform. This writes to the legacy file-based \
        keychain, where kSecAttrAccessibleAfterFirstUnlock has no effect; the \
        package builds on macOS only so swift build, swift test and DocC have a host.
        """)
    #endif
    public init(service: String = "tonconnect-swift") {
        self.service = service
    }

    public func set(_ value: String, forKey key: String) async throws {
        let data = Data(value.utf8)
        var query = baseQuery(forKey: key)
        query[kSecValueData as String] = data
        // Readable after first unlock; NOT the device-only variant used by the
        // v1 app — deliberate divergence so the session survives app reinstall.
        // The iCloud-sync attribute is intentionally never set (defaults to false —
        // session material must not leave this device). Do NOT add a biometric
        // access-control attribute here: combining it with an accessibility flag
        // fails with errSecParam (-50).
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            let attributesToUpdate: [String: Any] = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(
                baseQuery(forKey: key) as CFDictionary,
                attributesToUpdate as CFDictionary
            )
            guard updateStatus == errSecSuccess else {
                throw TonConnectError.storageFailure(status: updateStatus)
            }
        } else if status != errSecSuccess {
            throw TonConnectError.storageFailure(status: status)
        }
    }

    public func get(_ key: String) async throws -> String? {
        var query = baseQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw TonConnectError.storageFailure(status: status)
        }
        return String(data: data, encoding: .utf8)
    }

    public func remove(_ key: String) async throws {
        let status = SecItemDelete(baseQuery(forKey: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TonConnectError.storageFailure(status: status)
        }
    }

    private func baseQuery(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }
}
