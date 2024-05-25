//
//  LogDistributor.swift
//  SwiftUI-UDF
//
//  Created by Max Kuznetsov on 22.02.2023.
//

import Foundation

struct LogDistributor {
    var loggers: [ActionLogger]

    func distribute(action: InternalAction) {
        self.distribute(action: LoggingAction(action))
    }

    func distribute(action: LoggingAction) {
        loggers.forEach { logger in
            if logger.actionFilters.allSatisfy({ $0.include(action: action) }) {
                logger.log(action, description: logger.actionDescriptor.description(for: action))
            }
        }
    }
}
