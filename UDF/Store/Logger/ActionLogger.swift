//===--- ActionLogging.swift ---------------------------------------------===//
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

/// A protocol that defines a filter for actions, determining whether an action should be included in the logging process.
public protocol ActionFilter: Sendable {
    /// Determines whether a given action should be included.
    ///
    /// - Parameter action: The action to be evaluated.
    /// - Returns: A Boolean value indicating whether the action should be included.
    func include(action: LoggingAction) -> Bool
}

/// A protocol that provides a description for actions to be used in logging.
public protocol ActionDescriptor: Sendable {
    /// Returns a description for a given action.
    ///
    /// - Parameter action: The action to be described.
    /// - Returns: A string describing the action.
    func description(for action: LoggingAction) -> String
}

/// A protocol for logging actions, including the use of filters and descriptors.
public protocol ActionLogger: Sendable {
    /// An array of `ActionFilter` objects used to determine which actions should be logged.
    var actionFilters: [ActionFilter] { get }

    /// An `ActionDescriptor` used to generate descriptions for the actions to be logged.
    var actionDescriptor: ActionDescriptor { get }

    /// Logs a given action with a specified description.
    ///
    /// - Parameters:
    ///   - action: The action to log.
    ///   - description: The description of the action.
    func log(_ action: LoggingAction, description: String)
}
