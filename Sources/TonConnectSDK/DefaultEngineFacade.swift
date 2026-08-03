import TonConnectCore
import TonConnectNativeEngine

#if canImport(UIKit)
extension TonConnect {
    /// Convenience constructor: builds the default (Native) engine internally so the
    /// consumer never imports TonConnectNativeEngine. The engine behind this
    /// initializer has been swapped once already without touching a call site.
    /// The outer `throws` is preserved for API stability even though NativeEngine's
    /// init does not throw (Demo's `try! TonConnect(manifestUrl:)` keeps compiling).
    public convenience init(
        manifestUrl: String,
        storage: any TonConnectStorage = KeychainStorage()
    ) throws {
        let engine = NativeEngine(
            manifestUrl: manifestUrl,
            storage: storage,
            opener: SystemWalletOpener(),
            returnStrategy: .back
        )
        self.init(engine: engine, returnStrategy: .back)
    }
}
#endif
