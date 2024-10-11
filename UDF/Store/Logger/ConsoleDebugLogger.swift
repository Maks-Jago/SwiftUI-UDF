//===--- ConsoleDebugLogger.swift -----------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

/// A logger that outputs actions to the console for debugging purposes.
public struct ConsoleDebugLogger: ActionLogger {
    /// An array of action filters used to filter which actions should be logged.
    public var actionFilters: [ActionFilter] = []

    /// The action descriptor used to generate a description for the actions being logged.
    public var actionDescriptor: ActionDescriptor

    /// Initializes a new `ConsoleDebugLogger`.
    ///
    /// - Parameters:
    ///   - filters: An array of `ActionFilter` instances used to filter the actions for logging.
    ///   - descriptor: The `ActionDescriptor` used to describe the actions. Defaults to `StringDescribingActionDescriptor`.
    public init(filters: [ActionFilter], descriptor: ActionDescriptor = StringDescribingActionDescriptor()) {
        self.actionFilters = filters
        self.actionDescriptor = descriptor
    }

    /// Logs an action to the console with a given description.
    ///
    /// - Parameters:
    ///   - action: The `LoggingAction` to be logged.
    ///   - description: A `String` representing the description of the action.
    public func log(_ action: LoggingAction, description: String) {
        print(
            "Reduce\t\t \(description)\n---------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
        )
    }
}

public extension ActionLogger where Self == ConsoleDebugLogger {
    /// Returns a `ConsoleDebugLogger` that logs actions using the default filter.
    static var consoleDebug: ActionLogger { ConsoleDebugLogger(filters: [.default]) }

    /// Returns a `ConsoleDebugLogger` that logs all actions verbosely.
    static var consoleDebugVerbose: ActionLogger { ConsoleDebugLogger(filters: [.verbose]) }

    /// Returns a `ConsoleDebugLogger` that logs only error actions.
    static var consoleDebugOnlyErrors: ActionLogger { ConsoleDebugLogger(filters: [.errorOnly]) }

    /// Creates a `ConsoleDebugLogger` with additional custom filters.
    ///
    /// - Parameter extraFilters: An array of extra `ActionFilter` instances to be included along with the default debug-only filter.
    /// - Returns: An `ActionLogger` instance with the specified filters.
    static func consoleDebug(extraFilters: [ActionFilter]) -> ActionLogger {
        ConsoleDebugLogger(filters: [.debugOnly] + extraFilters)
    }
}
