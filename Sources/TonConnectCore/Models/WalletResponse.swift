import Foundation

/// spec/rpc.md § WalletResponse — discriminated on presence of "result" vs "error"
public enum WalletResponse: Equatable, Sendable {
    case success(result: String, id: String)
    case error(code: RPCErrorCode, message: String, id: String)
}

extension WalletResponse: Codable {
    private enum CodingKeys: String, CodingKey {
        case result
        case error
        case id
    }

    private struct ErrorBody: Codable {
        let code: RPCErrorCode
        // Wire tolerance (style): some wallets send an error without a message.
        let message: String?
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try Self.decodeFlexibleID(container)
        if container.contains(.error) {
            let body = try container.decode(ErrorBody.self, forKey: .error)
            self = .error(code: body.code, message: body.message ?? "", id: id)
        } else if let string = try? container.decode(String.self, forKey: .result) {
            // sendTransaction: result is a string (boc).
            self = .success(result: string, id: id)
        } else {
            // signData (and future methods): result is a JSON OBJECT (live Tonkeeper:
            // {"signature","address","timestamp","payload"}).
            // Preserved as raw JSON text — the consumer parses it per method.
            // Key order is not preserved on reassembly (JSONFragment), which is
            // acceptable: signatures verify over fields, not over frame bytes.
            let fragment = try container.decode(JSONFragment.self, forKey: .result)
            self = .success(result: fragment.rawJSON, id: id)
        }
    }

    /// id is a string per spec, but the wire type varies across wallets (same
    /// tolerance as TonProof.timestamp): a number is accepted and stringified.
    private static func decodeFlexibleID(_ container: KeyedDecodingContainer<CodingKeys>) throws -> String {
        if let string = try? container.decode(String.self, forKey: .id) { return string }
        return String(try container.decode(Int64.self, forKey: .id))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .success(let result, let id):
            try container.encode(result, forKey: .result)
            try container.encode(id, forKey: .id)
        case .error(let code, let message, let id):
            try container.encode(ErrorBody(code: code, message: message), forKey: .error)
            try container.encode(id, forKey: .id)
        }
    }
}

/// A minimal container for an arbitrary JSON value: decodes anything and
/// reconstructs compact JSON text. Used for WalletResponse result objects;
/// object keys come out in lexicographic order on reassembly (determinism for tests).
enum JSONFragment: Decodable {
    case string(String)
    case integer(Int64)
    case number(Double)
    case bool(Bool)
    case null
    case array([JSONFragment])
    case object([String: JSONFragment])

    init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        if single.decodeNil() { self = .null }
        else if let value = try? single.decode(Bool.self) { self = .bool(value) }
        else if let value = try? single.decode(Int64.self) { self = .integer(value) }
        else if let value = try? single.decode(Double.self) { self = .number(value) }
        else if let value = try? single.decode(String.self) { self = .string(value) }
        else if let value = try? single.decode([JSONFragment].self) { self = .array(value) }
        else { self = .object(try single.decode([String: JSONFragment].self)) }
    }

    /// Compact JSON text of the value (no whitespace; object keys sorted).
    var rawJSON: String {
        switch self {
        case .string(let value):
            let data = (try? JSONEncoder().encode(value)) ?? Data()
            return String(decoding: data, as: UTF8.self)
        case .integer(let value): return String(value)
        case .number(let value): return String(value)
        case .bool(let value): return value ? "true" : "false"
        case .null: return "null"
        case .array(let items):
            return "[" + items.map(\.rawJSON).joined(separator: ",") + "]"
        case .object(let fields):
            let body = fields.sorted { $0.key < $1.key }
                .map { key, value in "\"\(key)\":\(value.rawJSON)" }
                .joined(separator: ",")
            return "{" + body + "}"
        }
    }
}

/// spec/rpc.md § RPC error codes (all methods) — versioned wire value
public enum RPCErrorCode: Equatable, Sendable {
    case unknownError // 0
    case badRequest // 1
    case unknownApp // 100
    case userDeclined // 300
    case methodNotSupported // 400
    case unknown(Int)

    public init(rawValue: Int) {
        switch rawValue {
        case 0: self = .unknownError
        case 1: self = .badRequest
        case 100: self = .unknownApp
        case 300: self = .userDeclined
        case 400: self = .methodNotSupported
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: Int {
        switch self {
        case .unknownError: return 0
        case .badRequest: return 1
        case .unknownApp: return 100
        case .userDeclined: return 300
        case .methodNotSupported: return 400
        case .unknown(let raw): return raw
        }
    }
}

extension RPCErrorCode: Codable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(Int.self)
        self.init(rawValue: raw)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
