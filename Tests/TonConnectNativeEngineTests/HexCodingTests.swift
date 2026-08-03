import Testing
@testable import TonConnectNativeEngine

// The randomness seam is untouched — no .serialized needed.
struct HexCodingTests {

    @Test
    func testToHexStringEncodesBytesLowercaseWithLeadingZeros() {
        #expect(HexCoding.toHexString([0x00, 0x0f, 0xff]) == "000fff")
        #expect(HexCoding.toHexString([]) == "")
    }

    @Test
    func testHexToByteArrayDecodesValidHex() throws {
        #expect(try HexCoding.hexToByteArray("000fff") == [0x00, 0x0f, 0xff])
        #expect(try HexCoding.hexToByteArray("") == [])
    }

    @Test
    func testHexToByteArrayWithOddLengthThrowsOddLength() {
        #expect(throws: HexError.oddLength) {
            _ = try HexCoding.hexToByteArray("abc")
        }
    }

    @Test
    func testHexToByteArrayWithInvalidCharacterThrows() {
        #expect(throws: HexError.invalidCharacter) {
            _ = try HexCoding.hexToByteArray("zz")
        }
    }

    @Test
    func testHexRoundTripPreservesBytes() throws {
        let bytes = [UInt8](0...255)
        #expect(try HexCoding.hexToByteArray(HexCoding.toHexString(bytes)) == bytes)
        #expect(HexCoding.toHexString(try HexCoding.hexToByteArray("deadbeef")) == "deadbeef")
    }
}
