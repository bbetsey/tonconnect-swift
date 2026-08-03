import Foundation

/// spec/connect.md § ConnectEvent — discriminated on "event": "connect" | "connect_error"
public enum ConnectEvent: Equatable, Sendable {
    case success(id: Int, payload: ConnectSuccessPayload, response: WalletResponse?)
    case error(id: Int, code: ConnectErrorCode, message: String)
}

extension ConnectEvent: Codable {
    private enum CodingKeys: String, CodingKey {
        case event
        case id
        case payload
        case response
    }

    private struct ErrorPayload: Codable {
        let code: ConnectErrorCode
        let message: String?
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let event = try container.decode(String.self, forKey: .event)
        // Wire tolerance (style): the spec numbers wallet events, but live
        // wallets vary — Tonhub's bridge connect reply omits `id` entirely
        // (tonwhales/wallet, TonConnectAuthenticateFragment: the QR/Link path
        // builds the event without it; the JS SDK never checks it, so the bug is
        // invisible in the browser ecosystem). A numeric string is accepted for
        // symmetry with WalletResponse.id; a missing id becomes a synthetic 0 —
        // the same default JSCoreEngine fabricates. Replay protection degrades
        // gracefully: a fresh connect resets the monotonicity counter, and an
        // id-less wallet disconnect is already ignored by the existing guard.
        let id: Int
        if let number = try? container.decode(Int.self, forKey: .id) {
            id = number
        } else if let string = try? container.decode(String.self, forKey: .id),
                  let parsed = Int(string) {
            id = parsed
        } else {
            id = 0
        }
        switch event {
        case "connect":
            self = .success(
                id: id,
                payload: try container.decode(ConnectSuccessPayload.self, forKey: .payload),
                response: try container.decodeIfPresent(WalletResponse.self, forKey: .response)
            )
        case "connect_error":
            let payload = try container.decode(ErrorPayload.self, forKey: .payload)
            self = .error(id: id, code: payload.code, message: payload.message ?? "")
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .event, in: container,
                debugDescription: "Unknown ConnectEvent event: \(event)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .success(let id, let payload, let response):
            try container.encode("connect", forKey: .event)
            try container.encode(id, forKey: .id)
            try container.encode(payload, forKey: .payload)
            try container.encodeIfPresent(response, forKey: .response)
        case .error(let id, let code, let message):
            try container.encode("connect_error", forKey: .event)
            try container.encode(id, forKey: .id)
            try container.encode(ErrorPayload(code: code, message: message), forKey: .payload)
        }
    }
}

/// spec/connect.md § ConnectEvent (success) payload
public struct ConnectSuccessPayload: Codable, Equatable, Sendable {
    public let items: [ConnectItemReply]
    public let device: DeviceInfo

    public init(items: [ConnectItemReply], device: DeviceInfo) {
        self.items = items
        self.device = device
    }
}

/// spec/connect.md § ConnectItemReply — "ton_addr" reply, or "ton_proof" success/error
public enum ConnectItemReply: Equatable, Sendable {
    case tonAddress(TonAddressItemReply)
    case tonProofSuccess(TonProof)
    case tonProofError(code: ConnectItemErrorCode, message: String?)
    case unknown(name: String)
}

extension ConnectItemReply: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case proof
        case error
    }

    private struct ProofError: Codable {
        let code: ConnectItemErrorCode
        let message: String?
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        switch name {
        case "ton_addr":
            self = .tonAddress(try TonAddressItemReply(from: decoder))
        case "ton_proof":
            if container.contains(.error) {
                let body = try container.decode(ProofError.self, forKey: .error)
                self = .tonProofError(code: body.code, message: body.message)
            } else {
                self = .tonProofSuccess(try container.decode(TonProof.self, forKey: .proof))
            }
        default:
            self = .unknown(name: name)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .tonAddress(let reply):
            try container.encode("ton_addr", forKey: .name)
            try reply.encode(to: encoder)
        case .tonProofSuccess(let proof):
            try container.encode("ton_proof", forKey: .name)
            try container.encode(proof, forKey: .proof)
        case .tonProofError(let code, let message):
            try container.encode("ton_proof", forKey: .name)
            try container.encode(ProofError(code: code, message: message), forKey: .error)
        case .unknown(let name):
            try container.encode(name, forKey: .name)
        }
    }
}

/// spec/connect.md § TonAddressItemReply
public struct TonAddressItemReply: Codable, Equatable, Sendable {
    public let address: String
    public let network: String
    public let publicKey: String
    public let walletStateInit: String
    
    private enum CodingKeys: String, CodingKey {
        case address, network, publicKey, walletStateInit
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        address = try container.decode(String.self, forKey: .address)
        // Wire tolerance (style): the spec's CHAIN is a string enum, but a
        // hand-rolled wallet may serialize the network as a bare number.
        if let string = try? container.decode(String.self, forKey: .network) {
            network = string
        } else {
            network = String(try container.decode(Int.self, forKey: .network))
        }
        // The JSCore glue always treated these as optional (live-wallet empirics:
        // `?? ""`) — the native DTO mirrors that precedent.
        publicKey = try container.decodeIfPresent(String.self, forKey: .publicKey) ?? ""
        walletStateInit = try container.decodeIfPresent(String.self, forKey: .walletStateInit) ?? ""
    }

    public init(address: String, network: String, publicKey: String, walletStateInit: String) {
        self.address = address
        self.network = network
        self.publicKey = publicKey
        self.walletStateInit = walletStateInit
    }
}

/// spec/connect.md § TonProofItemReply (success) proof body
public struct TonProof: Codable, Equatable, Sendable {
    /// The dApp domain the wallet signed over, with the byte length the wallet
    /// used — both are needed to rebuild the signed message when verifying.
    public struct Domain: Codable, Equatable, Sendable {
        public let lengthBytes: Int
        public let value: String

        public init(lengthBytes: Int, value: String) {
            self.lengthBytes = lengthBytes
            self.value = value
        }
    }

    /// Signature unix seconds. Per spec — int64: live Tonkeeper sends a NUMBER
    /// (observed on a live wallet; the JS SDK validates isValidNumber). A numeric STRING
    /// ("123") is accepted leniently (style) for wallets that serialize
    /// int64 as a string; a number is always emitted outward (synthesized encode).
    public let timestamp: Int64
    public let domain: Domain
    public let signature: String
    public let payload: String

    public init(timestamp: Int64, domain: Domain, signature: String, payload: String) {
        self.timestamp = timestamp
        self.domain = domain
        self.signature = signature
        self.payload = payload
    }

    private enum CodingKeys: String, CodingKey {
        case timestamp, domain, signature, payload
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let number = try? container.decode(Int64.self, forKey: .timestamp) {
            timestamp = number
        } else {
            let raw = try container.decode(String.self, forKey: .timestamp)
            guard let parsed = Int64(raw) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .timestamp, in: container,
                    debugDescription: "timestamp is neither int64 nor numeric string: \(raw)")
            }
            timestamp = parsed
        }
        domain = try container.decode(Domain.self, forKey: .domain)
        signature = try container.decode(String.self, forKey: .signature)
        // Some wallets do not echo the request payload back — tolerate its absence.
        payload = try container.decodeIfPresent(String.self, forKey: .payload) ?? ""
    }
}

/// spec/connect.md § DeviceInfo
public struct DeviceInfo: Codable, Equatable, Sendable {
    public let platform: DevicePlatform
    public let appName: String
    public let appVersion: String
    public let maxProtocolVersion: Int
    public let features: [Feature]
    
    private enum CodingKeys: String, CodingKey {
        case platform, appName, appVersion, maxProtocolVersion, features
    }

    /// Wire tolerance (style): only what the engine actually needs is
    /// required; a sparse DeviceInfo from a minimal wallet must not fail connect.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        platform = try container.decodeIfPresent(DevicePlatform.self, forKey: .platform)
            ?? .unknown("unknown")
        appName = try container.decodeIfPresent(String.self, forKey: .appName) ?? ""
        appVersion = try container.decodeIfPresent(String.self, forKey: .appVersion) ?? ""
        maxProtocolVersion = try container.decodeIfPresent(Int.self, forKey: .maxProtocolVersion) ?? 2
        features = try container.decodeIfPresent([Feature].self, forKey: .features) ?? []
    }

    public init(
        platform: DevicePlatform,
        appName: String,
        appVersion: String,
        maxProtocolVersion: Int,
        features: [Feature]
    ) {
        self.platform = platform
        self.appName = appName
        self.appVersion = appVersion
        self.maxProtocolVersion = maxProtocolVersion
        self.features = features
    }
}

/// spec/connect.md § DeviceInfo.platform — versioned wire value (.unknown fallback)
public enum DevicePlatform: Equatable, Sendable {
    case iphone
    case ipad
    case android
    case windows
    case mac
    case linux
    case browser
    case unknown(String)

    public init(rawValue: String) {
        switch rawValue {
        case "iphone": self = .iphone
        case "ipad": self = .ipad
        case "android": self = .android
        case "windows": self = .windows
        case "mac": self = .mac
        case "linux": self = .linux
        case "browser": self = .browser
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .iphone: return "iphone"
        case .ipad: return "ipad"
        case .android: return "android"
        case .windows: return "windows"
        case .mac: return "mac"
        case .linux: return "linux"
        case .browser: return "browser"
        case .unknown(let raw): return raw
        }
    }
}

extension DevicePlatform: Codable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self.init(rawValue: raw)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// spec/connect.md § Feature — discriminated on "name"; unrecognized name → .unknown
public enum Feature: Equatable, Sendable {
    case sendTransaction(maxMessages: Int, extraCurrencySupported: Bool?, itemTypes: [String]?)
    case signData(types: [String])
    case signMessage(maxMessages: Int, extraCurrencySupported: Bool?, itemTypes: [String]?)
    case embeddedRequest
    case unknown(name: String)
}

extension Feature: Codable {
    private enum CodingKeys: String, CodingKey {
        case name
        case maxMessages
        case extraCurrencySupported
        case itemTypes
        case types
    }

    public init(from decoder: Decoder) throws {
        // The spec's legacy form (observed on a live Tonkeeper): a features
        // element may be a bare "SendTransaction" string — a deprecated alias of
        // basic support (1 message). An unknown string → .unknown.
        if let single = try? decoder.singleValueContainer(),
           let legacyName = try? single.decode(String.self) {
            switch legacyName {
            case "SendTransaction":
                self = .sendTransaction(maxMessages: 1, extraCurrencySupported: nil, itemTypes: nil)
            default:
                self = .unknown(name: legacyName)
            }
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        switch name {
        case "SendTransaction":
            self = .sendTransaction(
                maxMessages: try container.decode(Int.self, forKey: .maxMessages),
                extraCurrencySupported: try container.decodeIfPresent(Bool.self, forKey: .extraCurrencySupported),
                itemTypes: try container.decodeIfPresent([String].self, forKey: .itemTypes)
            )
        case "SignData":
            self = .signData(types: try container.decode([String].self, forKey: .types))
        case "SignMessage":
            self = .signMessage(
                maxMessages: try container.decode(Int.self, forKey: .maxMessages),
                extraCurrencySupported: try container.decodeIfPresent(Bool.self, forKey: .extraCurrencySupported),
                itemTypes: try container.decodeIfPresent([String].self, forKey: .itemTypes)
            )
        case "EmbeddedRequest":
            self = .embeddedRequest
        default:
            self = .unknown(name: name)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .sendTransaction(let maxMessages, let extraCurrencySupported, let itemTypes):
            try container.encode("SendTransaction", forKey: .name)
            try container.encode(maxMessages, forKey: .maxMessages)
            try container.encodeIfPresent(extraCurrencySupported, forKey: .extraCurrencySupported)
            try container.encodeIfPresent(itemTypes, forKey: .itemTypes)
        case .signData(let types):
            try container.encode("SignData", forKey: .name)
            try container.encode(types, forKey: .types)
        case .signMessage(let maxMessages, let extraCurrencySupported, let itemTypes):
            try container.encode("SignMessage", forKey: .name)
            try container.encode(maxMessages, forKey: .maxMessages)
            try container.encodeIfPresent(extraCurrencySupported, forKey: .extraCurrencySupported)
            try container.encodeIfPresent(itemTypes, forKey: .itemTypes)
        case .embeddedRequest:
            try container.encode("EmbeddedRequest", forKey: .name)
        case .unknown(let name):
            try container.encode(name, forKey: .name)
        }
    }
}

/// spec/connect.md § Connect Event error codes — versioned wire value
public enum ConnectErrorCode: Equatable, Sendable {
    case unknownError // 0
    case badRequest // 1
    case manifestNotFound // 2
    case manifestContentError // 3
    case unknownApp // 100
    case userDeclined // 300
    case methodNotSupported // 400
    case unknown(Int)

    public init(rawValue: Int) {
        switch rawValue {
        case 0: self = .unknownError
        case 1: self = .badRequest
        case 2: self = .manifestNotFound
        case 3: self = .manifestContentError
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
        case .manifestNotFound: return 2
        case .manifestContentError: return 3
        case .unknownApp: return 100
        case .userDeclined: return 300
        case .methodNotSupported: return 400
        case .unknown(let raw): return raw
        }
    }
}

extension ConnectErrorCode: Codable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(Int.self)
        self.init(rawValue: raw)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// spec/connect.md § Connect Item error codes — versioned wire value
public enum ConnectItemErrorCode: Equatable, Sendable {
    case unknownError // 0
    case methodNotSupported // 400
    case unknown(Int)

    public init(rawValue: Int) {
        switch rawValue {
        case 0: self = .unknownError
        case 400: self = .methodNotSupported
        default: self = .unknown(rawValue)
        }
    }

    public var rawValue: Int {
        switch self {
        case .unknownError: return 0
        case .methodNotSupported: return 400
        case .unknown(let raw): return raw
        }
    }
}

extension ConnectItemErrorCode: Codable {
    public init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(Int.self)
        self.init(rawValue: raw)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
