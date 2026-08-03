import Testing
import TonConnectCore

struct UserFriendlyAddressTests {

    private static let specRaw = "0:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

    private func makeAccount(address: String, network: String) -> Account {
        Account(address: address, network: network, publicKey: "", walletStateInit: "")
    }

    // MARK: - verified TEP-2 vectors

    @Test func testMainnetNonBounceableMatchesTEP2SpecVector() {
        let account = makeAccount(address: Self.specRaw, network: "-239")
        #expect(account.userFriendlyAddress() == "UQABI0VniavN7wEjRWeJq83vASNFZ4mrze8BI0VniavN7_z7")
    }

    @Test func testMainnetBounceableMatchesVerifiedVector() {
        let account = makeAccount(address: Self.specRaw, network: "-239")
        #expect(account.userFriendlyAddress(bounceable: true) == "EQABI0VniavN7wEjRWeJq83vASNFZ4mrze8BI0VniavN76E-")
    }

    @Test func testTestnetNonBounceableMatchesVerifiedVector() {
        let account = makeAccount(address: Self.specRaw, network: "-3")
        #expect(account.userFriendlyAddress() == "0QABI0VniavN7wEjRWeJq83vASNFZ4mrze8BI0VniavN70dx")
    }

    @Test func testTestnetBounceableMatchesVerifiedVector() {
        let account = makeAccount(address: Self.specRaw, network: "-3")
        #expect(account.userFriendlyAddress(bounceable: true) == "kQABI0VniavN7wEjRWeJq83vASNFZ4mrze8BI0VniavN7xq0")
    }

    @Test func testMasterchainNonBounceableMatchesVerifiedVector() {
        let account = makeAccount(
            address: "-1:e56754f83426f69b09267bd876ac97c44821345b7e266bd956a7bfbfb98df35c",
            network: "-239"
        )
        #expect(account.userFriendlyAddress() == "Uf_lZ1T4NCb2mwkme9h2rJfESCE0W34ma9lWp7-_uY3zXGYv")
    }

    // MARK: - invalid input → nil

    @Test func testAddressWithoutColonReturnsNil() {
        let account = makeAccount(address: "0123456789abcdef", network: "-239")
        #expect(account.userFriendlyAddress() == nil)
    }

    @Test func testAddressWithInvalidHexReturnsNil() {
        let account = makeAccount(
            address: "0:zz23456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
            network: "-239"
        )
        #expect(account.userFriendlyAddress() == nil)
    }

    @Test func testAddressWithShortHashReturnsNil() {
        let account = makeAccount(address: "0:0123456789abcdef", network: "-239")
        #expect(account.userFriendlyAddress() == nil)
    }
}
