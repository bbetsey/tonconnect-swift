import Foundation

/// TEP-2 conversion of a raw address (0:hex64) to user-friendly (UQ…/EQ…).
/// The form: tag(1) + workchain(1) + hash(32) + crc16(2), then base64url.
extension Account {
    /// nil for a malformed raw address (no ":", bad hex, hash != 32 bytes) —
    /// an address with a wrong checksum is never produced.
    /// The testnet flag comes from self.network ("-3" = testnet).
    public func userFriendlyAddress(bounceable: Bool = false) -> String? {
        let parts = address.split(separator: ":")
        guard parts.count == 2,
              let workchain = Int8(parts[0]),
              let hash = Self.dataFromHex(String(parts[1])), hash.count == 32 else { return nil }
        var tag: UInt8 = bounceable ? 0x11 : 0x51
        if network == "-3" { tag |= 0x80 }
        var payload = Data([tag, UInt8(bitPattern: workchain)])
        payload.append(hash)
        let crc = Self.crc16XModem(payload)
        payload.append(UInt8(crc >> 8))
        payload.append(UInt8(crc & 0xFF))
        return payload.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }

    /// CRC16-CCITT/XMODEM (poly 0x1021, init 0x0000) — the TON address checksum,
    /// NOT cryptography (no secrets/keys involved).
    private static func crc16XModem(_ data: Data) -> UInt16 {
        var crc: UInt16 = 0
        for byte in data {
            crc ^= UInt16(byte) << 8
            for _ in 0..<8 {
                crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1
            }
        }
        return crc
    }

    private static func dataFromHex(_ hex: String) -> Data? {
        guard hex.count % 2 == 0 else { return nil }
        var data = Data(capacity: hex.count / 2)
        var index = hex.startIndex
        while index < hex.endIndex {
            let next = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<next], radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        return data
    }
}
