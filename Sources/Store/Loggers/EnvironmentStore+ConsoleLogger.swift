import Foundation

public extension EnvironmentStore {
    convenience init(initial state: State, accessToken: String) {
        self.init(initial: state, accessToken: accessToken, logger: ConsoleDebugLogger(options: .all))
    }

    convenience init(initial state: State, debugLoggerOptions options: ConsoleDebugLogger.Options, accessToken: String) {
        self.init(initial: state, accessToken: accessToken, logger: ConsoleDebugLogger(options: options))
    }
}
