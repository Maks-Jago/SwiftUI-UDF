//===--- LogDistributor.swift ---------------------------------------------===//
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

/// A distributor that sends logging actions to multiple loggers.
struct LogDistributor {
    /// A list of loggers that will handle the distributed actions.
    var loggers: [ActionLogger]

    /// Distributes an `InternalAction` to all loggers.
    ///
    /// - Parameter action: The `InternalAction` to be logged.
    func distribute(action: InternalAction) {
        self.distribute(action: LoggingAction(action))
    }

    /// Distributes a `LoggingAction` to all loggers.
    ///
    /// - Parameter action: The `LoggingAction` to be logged.
    /// This method checks each logger's filters to determine if the action should be logged.
    func distribute(action: LoggingAction) {
        for logger in loggers {
            if logger.actionFilters.allSatisfy({ $0.include(action: action) }) {
                logger.log(action, description: logger.actionDescriptor.description(for: action))
            }
        }
    }
}
