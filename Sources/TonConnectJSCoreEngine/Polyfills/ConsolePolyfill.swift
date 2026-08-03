import JavaScriptCore
import os

/// console.log/info/debug/warn/error from JS → os.Logger.
/// Not print(): the package is open source, the consumer's stdout must stay clean.
/// Filtering: subsystem "tonconnect-swift", category "JSConsole".
public struct ConsolePolyfill: JSPolyfill {
    private let logger = Logger(subsystem: "tonconnect-swift", category: "JSConsole")

    public init() {}

    public func apply(to context: JSContext) {
        let logger = self.logger

        let logBlock: @convention(block) (String) -> Void = { logger.info("\($0, privacy: .public)") }
        let debugBlock: @convention(block) (String) -> Void = { logger.debug("\($0, privacy: .public)") }
        let warnBlock: @convention(block) (String) -> Void = { logger.notice("\($0, privacy: .public)") }
        let errorBlock: @convention(block) (String) -> Void = { logger.error("\($0, privacy: .public)") }

        let console = JSValue(newObjectIn: context)!
        console.setObject(logBlock, forKeyedSubscript: "log" as NSString)
        console.setObject(logBlock, forKeyedSubscript: "info" as NSString)
        console.setObject(debugBlock, forKeyedSubscript: "debug" as NSString)
        console.setObject(warnBlock, forKeyedSubscript: "warn" as NSString)
        console.setObject(errorBlock, forKeyedSubscript: "error" as NSString)
        context.setObject(console, forKeyedSubscript: "console" as NSString)
    }
}
