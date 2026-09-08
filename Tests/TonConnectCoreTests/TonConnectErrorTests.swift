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

    // MARK: - timeout

    @Test func testTimeoutErrorDescriptionPrintsWholeSecondsWithoutAFraction() {
        let description = (TonConnectError.timeout(after: .seconds(90)) as LocalizedError)
            .errorDescription
        #expect(description == "TON Connect request timed out after 90s")
    }

    @Test func testTimeoutErrorDescriptionKeepsAFractionOfASecond() {
        let description = (TonConnectError.timeout(after: .milliseconds(250)) as LocalizedError)
            .errorDescription
        #expect(description == "TON Connect request timed out after 0.25s")
    }

    @Test func testTimeoutEqualityHoldsForTheSameDuration() {
        #expect(TonConnectError.timeout(after: .seconds(5)) == TonConnectError.timeout(after: .seconds(5)))
        #expect(TonConnectError.timeout(after: .seconds(5)) != TonConnectError.timeout(after: .seconds(6)))
    }
}
