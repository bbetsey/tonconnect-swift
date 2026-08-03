import Foundation
import Testing
import TonConnectCore

struct DTORoundTripTests {

    // MARK: - Fixtures (inline, spec-derived)

    enum Fixtures {
        static let connectRequest = """
        {
          "manifestUrl": "https://example.com/tonconnect-manifest.json",
          "items": [
            { "name": "ton_addr" },
            { "name": "ton_proof", "payload": "challenge-123" }
          ]
        }
        """

        static let connectEventSuccess = """
        {
          "event": "connect",
          "id": 1,
          "payload": {
            "items": [
              {
                "name": "ton_addr",
                "address": "0:abc123",
                "network": "-239",
                "publicKey": "deadbeef",
                "walletStateInit": "te6ccStateInit"
              },
              {
                "name": "ton_proof",
                "proof": {
                  "timestamp": 1719999999,
                  "domain": { "lengthBytes": 11, "value": "example.com" },
                  "signature": "c2lnbmF0dXJl",
                  "payload": "challenge-123"
                }
              }
            ],
            "device": {
              "platform": "iphone",
              "appName": "Tonkeeper",
              "appVersion": "4.0.0",
              "maxProtocolVersion": 2,
              "features": [
                { "name": "SendTransaction", "maxMessages": 4 },
                { "name": "SignData", "types": ["text", "binary", "cell"] }
              ]
            }
          }
        }
        """

        static let connectEventUnknownCode = """
        { "event": "connect_error", "id": 2, "payload": { "code": 9999, "message": "future error" } }
        """

        static let deviceInfoUnknownPlatform = """
        {
          "platform": "vision",
          "appName": "FutureWallet",
          "appVersion": "1.0",
          "maxProtocolVersion": 3,
          "features": []
        }
        """

        static let connectEventExtraKey = """
        {
          "event": "connect_error",
          "id": 3,
          "payload": { "code": 300, "message": "declined" },
          "futureField": true
        }
        """

        static let appRequestSendTransaction = """
        {
          "method": "sendTransaction",
          "params": ["{\\"valid_until\\":1719999999,\\"messages\\":[{\\"address\\":\\"0:abc\\",\\"amount\\":\\"10000000\\"}]}"],
          "id": "1"
        }
        """

        static let walletResponseSuccess = """
        { "result": "te6ccResultBoc", "id": "1" }
        """

        static let walletResponseUserDeclined = """
        { "error": { "code": 300, "message": "user declined" }, "id": "2" }
        """

        static let walletResponseUnknownCode = """
        { "error": { "code": 9999, "message": "from the future" }, "id": "3" }
        """

        static let signDataText = """
        { "type": "text", "text": "hello" }
        """

        static let signDataBinary = """
        { "type": "binary", "bytes": "aGVsbG8=" }
        """

        static let signDataCell = """
        { "type": "cell", "schema": "message#_ text:string = Message;", "cell": "te6ccCell" }
        """

        static let manifestRequiredOnly = """
        { "url": "https://example.com", "name": "Example dApp", "iconUrl": "https://example.com/icon.png" }
        """

        static let manifestWithOptionals = """
        {
          "url": "https://example.com",
          "name": "Example dApp",
          "iconUrl": "https://example.com/icon.png",
          "termsOfUseUrl": "https://example.com/terms",
          "privacyPolicyUrl": "https://example.com/privacy"
        }
        """

        static let manifestWithReservedKey = """
        {
          "url": "https://example.com",
          "name": "Example dApp",
          "iconUrl": "https://example.com/icon.png",
          "version": 2
        }
        """
    }

    // MARK: - Helpers

    private func decode<T: Decodable>(_ type: T.Type, from json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    private func roundTrip<T: Codable & Equatable>(_ json: String, as type: T.Type) throws -> (first: T, second: T) {
        let first = try JSONDecoder().decode(T.self, from: Data(json.utf8))
        let reencoded = try JSONEncoder().encode(first)
        let second = try JSONDecoder().decode(T.self, from: reencoded)
        return (first, second)
    }

    // MARK: - Task 1: ConnectRequest / ConnectEvent

    @Test func testConnectRequestRoundTripsPreservingItemDiscriminators() throws {
        let (first, second) = try roundTrip(Fixtures.connectRequest, as: ConnectRequest.self)
        #expect(first == second)
        #expect(first.items == [.tonAddress(network: nil), .tonProof(payload: "challenge-123")])
        let encoded = String(decoding: try JSONEncoder().encode(first), as: UTF8.self)
        #expect(encoded.contains("ton_addr"))
        #expect(encoded.contains("ton_proof"))
    }

    @Test func testConnectEventSuccessRoundTripsWithDeviceInfoAndFeatures() throws {
        let (first, second) = try roundTrip(Fixtures.connectEventSuccess, as: ConnectEvent.self)
        #expect(first == second)
        guard case .success(let id, let payload, let response) = first else {
            Issue.record("Expected .success, got \(first)")
            return
        }
        #expect(id == 1)
        #expect(response == nil)
        #expect(payload.items.count == 2)
        #expect(payload.device.platform == .iphone)
        #expect(payload.device.features.contains(.signData(types: ["text", "binary", "cell"])))
    }

    @Test func testConnectEventDecodesUnknownErrorCodeToUnknownCase() throws {
        let event = try decode(ConnectEvent.self, from: Fixtures.connectEventUnknownCode)
        guard case .error(_, let code, _) = event else {
            Issue.record("Expected .error, got \(event)")
            return
        }
        #expect(code == .unknown(9999))
    }

    @Test func testDeviceInfoDecodesUnknownPlatformToUnknownCase() throws {
        let device = try decode(DeviceInfo.self, from: Fixtures.deviceInfoUnknownPlatform)
        #expect(device.platform == .unknown("vision"))
    }

    @Test func testConnectEventDecodesDespiteExtraTopLevelKey() throws {
        let event = try decode(ConnectEvent.self, from: Fixtures.connectEventExtraKey)
        guard case .error(let id, let code, _) = event else {
            Issue.record("Expected .error, got \(event)")
            return
        }
        #expect(id == 3)
        #expect(code == .userDeclined)
    }

    // MARK: - Task 2: AppRequest / WalletResponse / payloads

    @Test func testAppRequestRoundTripsAndParamsDecodeAsSendTransactionPayload() throws {
        let (first, second) = try roundTrip(Fixtures.appRequestSendTransaction, as: AppRequest.self)
        #expect(first == second)
        #expect(first.method == "sendTransaction")
        let payload = try decode(SendTransactionPayload.self, from: first.params[0])
        #expect(payload.validUntil == 1_719_999_999)
        #expect(payload.messages == [.init(address: "0:abc", amount: "10000000", payload: nil, stateInit: nil)])
    }

    @Test func testWalletResponseSuccessRoundTripsAndErrorMapsUserDeclined() throws {
        let (first, second) = try roundTrip(Fixtures.walletResponseSuccess, as: WalletResponse.self)
        #expect(first == second)
        #expect(first == .success(result: "te6ccResultBoc", id: "1"))
        let declined = try decode(WalletResponse.self, from: Fixtures.walletResponseUserDeclined)
        #expect(declined == .error(code: .userDeclined, message: "user declined", id: "2"))
    }

    @Test func testWalletResponseDecodesUnknownRPCCodeToUnknownCase() throws {
        let response = try decode(WalletResponse.self, from: Fixtures.walletResponseUnknownCode)
        guard case .error(let code, _, _) = response else {
            Issue.record("Expected .error, got \(response)")
            return
        }
        #expect(code == .unknown(9999))
    }

    @Test func testSignDataPayloadDecodesAllThreeTypeDiscriminators() throws {
        let text = try decode(SignDataPayload.self, from: Fixtures.signDataText)
        #expect(text == .text(text: "hello", network: nil, from: nil))
        let binary = try decode(SignDataPayload.self, from: Fixtures.signDataBinary)
        #expect(binary == .binary(bytes: "aGVsbG8=", network: nil, from: nil))
        let cell = try decode(SignDataPayload.self, from: Fixtures.signDataCell)
        #expect(cell == .cell(schema: "message#_ text:string = Message;", cell: "te6ccCell", network: nil, from: nil))
    }

    // MARK: - Task 3: WalletManifest

    @Test func testWalletManifestRequiredOnlyRoundTrips() throws {
        let (first, second) = try roundTrip(Fixtures.manifestRequiredOnly, as: WalletManifest.self)
        #expect(first == second)
        #expect(first == WalletManifest(url: "https://example.com", name: "Example dApp", iconUrl: "https://example.com/icon.png"))
    }

    @Test func testWalletManifestRoundTripsWithOptionalPolicyURLs() throws {
        let (first, second) = try roundTrip(Fixtures.manifestWithOptionals, as: WalletManifest.self)
        #expect(first == second)
        #expect(first.termsOfUseUrl == "https://example.com/terms")
        #expect(first.privacyPolicyUrl == "https://example.com/privacy")
    }

    @Test func testWalletManifestIgnoresReservedVersionKey() throws {
        let manifest = try decode(WalletManifest.self, from: Fixtures.manifestWithReservedKey)
        #expect(manifest == WalletManifest(url: "https://example.com", name: "Example dApp", iconUrl: "https://example.com/icon.png"))
    }
    
    @Test func testTonProofTimestampAcceptsNumericStringLegacyForm() throws {
        let json = """
        {
          "timestamp": "1719999999",
          "domain": { "lengthBytes": 11, "value": "example.com" },
          "signature": "c2lnbmF0dXJl",
          "payload": "challenge-123"
        }
        """
        let proof = try JSONDecoder().decode(TonProof.self, from: Data(json.utf8))
        #expect(proof.timestamp == 1_719_999_999)
    }
    
    @Test func testWalletResponseSignDataObjectResultDecodesToRawJSONString() throws {
        let json = """
        {"id":"2","result":{"signature":"c2lnbmF0dXJl","address":"0:abc","timestamp":1753600000,"payload":{"type":"text","text":"hi"}}}
        """
        let response = try JSONDecoder().decode(WalletResponse.self, from: Data(json.utf8))
        guard case .success(let result, let id) = response else {
            Issue.record("expected .success, got \(response)")
            return
        }
        #expect(id == "2")
        #expect(result.contains("\"signature\":\"c2lnbmF0dXJl\""))
        #expect(result.contains("\"timestamp\":1753600000"))
    }

    @Test func testWalletResponseNumericIDDecodesAsString() throws {
        let json = """
        {"id":7,"result":"te6ccBoc"}
        """
        let response = try JSONDecoder().decode(WalletResponse.self, from: Data(json.utf8))
        guard case .success(let result, let id) = response else {
            Issue.record("expected .success, got \(response)")
            return
        }
        #expect(id == "7")
        #expect(result == "te6ccBoc")
    }
    
    @Test func testConnectEventWithoutIDDecodesWithSyntheticZeroID() throws {
        // Tonhub's bridge connect reply omits `id` (spec violation on the wallet
        // side, invisible to the JS SDK) — the decoder must tolerate it.
        let json = """
        {
          "event": "connect",
          "payload": {
            "items": [
              {
                "name": "ton_addr",
                "address": "0:abc123",
                "network": "-239",
                "publicKey": "deadbeef",
                "walletStateInit": "te6ccStateInit"
              }
            ],
            "device": {
              "platform": "iphone",
              "appName": "Tonhub",
              "appVersion": "5.0",
              "maxProtocolVersion": 2,
              "features": ["SendTransaction", { "name": "SendTransaction", "maxMessages": 4 }]
            }
          }
        }
        """
        let event = try JSONDecoder().decode(ConnectEvent.self, from: Data(json.utf8))
        guard case .success(let id, let payload, _) = event else {
            Issue.record("expected .success, got \(event)")
            return
        }
        #expect(id == 0)
        #expect(payload.device.appName == "Tonhub")
    }
    
    @Test func testUnknownConnectItemReplyDecodesAsUnknownCase() throws {
        let json = """
        {"event":"connect","id":1,"payload":{"items":[
          {"name":"ton_addr","address":"0:abc","network":"-239","publicKey":"dead","walletStateInit":"init"},
          {"name":"solana_proof","proof":{"whatever":true}}
        ],"device":{"platform":"iphone","appName":"W","appVersion":"1","maxProtocolVersion":2,"features":[]}}}
        """
        let event = try JSONDecoder().decode(ConnectEvent.self, from: Data(json.utf8))
        guard case .success(_, let payload, _) = event else {
            Issue.record("expected .success, got \(event)"); return
        }
        #expect(payload.items.count == 2)
        #expect(payload.items.contains { if case .unknown(let name) = $0 { return name == "solana_proof" }; return false })
    }

    @Test func testTonAddressReplyToleratesNumericNetworkAndMissingOptionalFields() throws {
        let json = """
        {"name":"ton_addr","address":"0:abc","network":-239}
        """
        let reply = try JSONDecoder().decode(ConnectItemReply.self, from: Data(json.utf8))
        guard case .tonAddress(let address) = reply else {
            Issue.record("expected .tonAddress, got \(reply)"); return
        }
        #expect(address.network == "-239")
        #expect(address.publicKey == "")
        #expect(address.walletStateInit == "")
    }

    @Test func testWalletResponseErrorWithoutMessageDecodes() throws {
        let json = """
        {"error":{"code":300},"id":"1"}
        """
        let response = try JSONDecoder().decode(WalletResponse.self, from: Data(json.utf8))
        guard case .error(let code, let message, let id) = response else {
            Issue.record("expected .error, got \(response)"); return
        }
        #expect(code == .userDeclined)
        #expect(message == "")
        #expect(id == "1")
    }
}
