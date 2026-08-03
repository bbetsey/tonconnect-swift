import Foundation
import Security
import Testing
import TonConnectCore
import TonConnectConformance

struct StorageParityTests {

    struct InMemoryStorageFactory: StorageFactory {
        let label = "InMemoryStorage"
        func makeStorage() async throws -> any TonConnectStorage { InMemoryStorage() }
    }

    struct KeychainStorageFactory: StorageFactory {
        let label = "KeychainStorage"
        func makeStorage() async throws -> any TonConnectStorage {
            KeychainStorage(service: "tonconnect-swift.tests")
        }
    }

    @Test func testInMemoryStoragePassesStorageConformanceSuite() async throws {
        try await StorageConformanceSuite.runAll(factory: InMemoryStorageFactory())
    }

    /// Gate-and-defer (spike): runners without Keychain entitlements get a
    /// visible skip on errSecMissingEntitlement (-34018); every other probe error
    /// falls through to the real assertions. True Keychain parity is re-verified
    /// by a hosted demo app, which carries real entitlements.
    @Test func testKeychainStoragePassesStorageConformanceSuiteWhenAvailable() async throws {
        let factory = KeychainStorageFactory()
        let probe = try await factory.makeStorage()
        do {
            try await probe.set("probe", forKey: "capability-probe")
            try await probe.remove("capability-probe")
        } catch let error as TonConnectError
            where error == .storageFailure(status: errSecMissingEntitlement) {
            print("SKIP [KeychainStorage]: SecItemAdd unavailable under this runner (errSecMissingEntitlement) — verified from a hosted app instead")
            return
        }
        try await StorageConformanceSuite.runAll(factory: factory)
    }
}
