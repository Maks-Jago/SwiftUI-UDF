import Foundation

public extension EnvironmentStore {
    convenience init(initial state: State, accessToken: String, logOptions: LogDistributor.Options) throws {
        try self.init(initial: state, accessToken: accessToken, logger: ConsoleDebugLogger(options: .all), logOptions: logOptions)
    }

    convenience init(initial state: State, consoleLoggerOptions: ConsoleDebugLogger.Options, accessToken: String, logOptions: LogDistributor.Options) throws {
        try self.init(initial: state, accessToken: accessToken, logger: ConsoleDebugLogger(options: consoleLoggerOptions), logOptions: logOptions)
    }
}
