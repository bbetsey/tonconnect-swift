import Foundation

/// spec/connect.md § ConnectRequest
public struct ConnectRequest: Codable, Equatable, Sendable {
    public let manifestUrl: String
    public let items: [ConnectItem]

    public init(manifestUrl: String, items: [ConnectItem]) {
        self.manifestUrl = manifestUrl
        self.items = items
    }
}

/// spec/connect.md § ConnectRequest — discriminated union on "name":
/// "ton_addr" | "ton_proof". NETWORK_ID is a raw String, not a closed enum.
public enum ConnectItem: Equatable, Sendable {
    case tonAddress(network: String?)
    case tonProof(payload: String)
}

extension ConnectItem: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case network
        case payload
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        switch name {
        case "ton_addr":
            self = .tonAddress(network: try container.decodeIfPresent(String.self, forKey: .network))
        case "ton_proof":
            self = .tonProof(payload: try container.decode(String.self, forKey: .payload))
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .name, in: container,
                debugDescription: "Unknown ConnectItem name: \(name)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .tonAddress(let network):
            try container.encode("ton_addr", forKey: .name)
            try container.encodeIfPresent(network, forKey: .network)
        case .tonProof(let payload):
            try container.encode("ton_proof", forKey: .name)
            try container.encode(payload, forKey: .payload)
        }
    }
}
