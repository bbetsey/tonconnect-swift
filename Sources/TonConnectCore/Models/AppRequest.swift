import Foundation

/// spec/rpc.md § AppRequest — params are JSON-encoded strings, method-specific
public struct AppRequest: Codable, Equatable, Sendable {
    public let method: String
    public let params: [String]
    public let id: String

    public init(method: String, params: [String], id: String) {
        self.method = method
        self.params = params
        self.id = id
    }
}

/// spec/rpc.md § DisconnectRequest
public struct DisconnectRequest: Codable, Equatable, Sendable {
    public let method: String
    public let params: [String]
    public let id: String

    public init(id: String) {
        self.method = "disconnect"
        self.params = []
        self.id = id
    }
}

/// spec/rpc.md § SendTransactionRequest — payload is JSON-encoded inside params[0].
/// The spec's optional `items` field is omitted: its element shape is not yet
/// spec-verified; default Codable synthesis ignores an incoming key.
public struct SendTransactionPayload: Codable, Equatable, Sendable {
    /// One outgoing message of the transaction. `amount` is in nanotons as a
    /// decimal string, and `payload`/`stateInit` are base64 BOCs when present.
    public struct Message: Codable, Equatable, Sendable {
        public let address: String
        public let amount: String
        public let payload: String?
        public let stateInit: String?

        public init(address: String, amount: String, payload: String?, stateInit: String?) {
            self.address = address
            self.amount = amount
            self.payload = payload
            self.stateInit = stateInit
        }
    }

    public let validUntil: Int?
    public let network: String?
    public let from: String?
    public let messages: [Message]

    private enum CodingKeys: String, CodingKey {
        case validUntil = "valid_until"
        case network
        case from
        case messages
    }

    public init(validUntil: Int?, network: String?, from: String?, messages: [Message]) {
        self.validUntil = validUntil
        self.network = network
        self.from = from
        self.messages = messages
    }
}

/// spec/rpc.md § SignDataRequest — payload discriminated on "type"
public enum SignDataPayload: Equatable, Sendable {
    case text(text: String, network: String?, from: String?)
    case binary(bytes: String, network: String?, from: String?)
    case cell(schema: String, cell: String, network: String?, from: String?)
}

extension SignDataPayload: Codable {
    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case bytes
        case schema
        case cell
        case network
        case from
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        let network = try container.decodeIfPresent(String.self, forKey: .network)
        let from = try container.decodeIfPresent(String.self, forKey: .from)
        switch type {
        case "text":
            self = .text(
                text: try container.decode(String.self, forKey: .text),
                network: network, from: from
            )
        case "binary":
            self = .binary(
                bytes: try container.decode(String.self, forKey: .bytes),
                network: network, from: from
            )
        case "cell":
            self = .cell(
                schema: try container.decode(String.self, forKey: .schema),
                cell: try container.decode(String.self, forKey: .cell),
                network: network, from: from
            )
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: container,
                debugDescription: "Unknown SignDataPayload type: \(type)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let text, let network, let from):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
            try container.encodeIfPresent(network, forKey: .network)
            try container.encodeIfPresent(from, forKey: .from)
        case .binary(let bytes, let network, let from):
            try container.encode("binary", forKey: .type)
            try container.encode(bytes, forKey: .bytes)
            try container.encodeIfPresent(network, forKey: .network)
            try container.encodeIfPresent(from, forKey: .from)
        case .cell(let schema, let cell, let network, let from):
            try container.encode("cell", forKey: .type)
            try container.encode(schema, forKey: .schema)
            try container.encode(cell, forKey: .cell)
            try container.encodeIfPresent(network, forKey: .network)
            try container.encodeIfPresent(from, forKey: .from)
        }
    }
}
