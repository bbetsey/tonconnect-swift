import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// The wallet-opening abstraction — injected for testability.
public protocol WalletOpener: Sendable {
    func open(_ url: URL)
}

#if canImport(UIKit)
/// The production opener. Deliberately the completion-handler overload, NOT async —
/// the async variant would insert an await between the gesture and open(), and iOS
/// would refuse to open the wallet.
public struct SystemWalletOpener: WalletOpener {
    public init() {}
    public func open(_ url: URL) {
        // UIApplication.open is a main-thread-only API (flagged by the Main Thread Checker).
        // The completion-handler overload, no await.
        if Thread.isMainThread {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            DispatchQueue.main.async {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}
#endif
