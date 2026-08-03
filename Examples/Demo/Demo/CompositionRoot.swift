import TonConnectCore   // the TonConnect facade, Account and the protocol types
import TonConnectUI     // TonConnectButton, tonConnectOperationSheet
import TonConnectSDK    // convenience init(manifestUrl:) — builds the default engine

@MainActor
enum CompositionRoot {
    static let manifestUrl = "https://bbetsey.github.io/tc-m/demo.json"
    static func makeTonConnect() -> TonConnect {
        // Force-unwrap is acceptable in an example's composition root: the
        // initializer only throws on a malformed manifest URL, and this one is a
        // compile-time constant. Do not copy this into an app that reads the URL
        // from configuration.
        try! TonConnect(manifestUrl: manifestUrl)
    }
}
