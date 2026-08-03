import Foundation

/// Hex coding 1:1 with the oracle (@tonconnect/protocol: toHexString / hexToByteArray).
/// The oracle's rules: lowercase, NO "0x", every byte exactly 2 characters
/// (leading zero), an odd-length string → an error. Everything internal.

enum HexError: Error, Equatable {
    case oddLength
    case invalidCharacter
}

enum HexCoding {

    static func toHexString(_ bytes: [UInt8]) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }

    static func hexToByteArray(_ hex: String) throws -> [UInt8] {
        guard hex.count % 2 == 0 else { throw HexError.oddLength }

        var bytes: [UInt8] = []
        bytes.reserveCapacity(hex.count / 2)

        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            guard
                let high = hex[index].hexDigitValue,
                let low = hex[hex.index(after: index)].hexDigitValue
            else {
                throw HexError.invalidCharacter
            }
            bytes.append(UInt8(high << 4 | low))
            index = nextIndex
        }
        return bytes
    }
}
