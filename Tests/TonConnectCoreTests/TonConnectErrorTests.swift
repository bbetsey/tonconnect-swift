import Foundation
import Security
import Testing
import TonConnectCore

struct TonConnectErrorTests {

    @Test func testStorageFailureEqualityHoldsForSameOSStatus() {
        #expect(
            TonConnectError.storageFailure(status: errSecItemNotFound)
                == TonConnectError.storageFailure(status: errSecItemNotFound)
        )
    }

    @Test func testDecodeFailureDiffersFromStorageFailure() {
        #expect(TonConnectError.decodeFailure("bad") != TonConnectError.storageFailure(status: 0))
    }

    @Test func testStorageFailureErrorDescriptionContainsOSStatus() {
        let description = (TonConnectError.storageFailure(status: -25300) as LocalizedError)
            .errorDescription
        #expect(description?.contains("-25300") == true)
    }
}
