import Foundation

/// Something went wrong on the Swift↔JavaScript boundary rather than in the
/// TON Connect protocol itself: the bundle would not load, the context is gone,
/// a call raised a JS exception, or a promise was collected before it settled.
/// The engine maps these to `TonConnectError` before they reach a consumer.
public enum JSBridgeError: Error, Equatable, Sendable {
    case jsException(message: String)
    case notAPromise
    case bundleLoadFailed(String)
    case contextUnavailable
    case promiseCollected
}

extension JSBridgeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .jsException(let m): return "JS exception: \(m)"
        case .notAPromise: return "Expected a JS Promise but got a non-Promise value"
        case .bundleLoadFailed(let m): return "Failed to load vendored SDK bundle: \(m)"
        case .contextUnavailable: return "JSContext could not be created"
        case .promiseCollected: return "JS promise was garbage-collected before settling"
        }
    }
}
