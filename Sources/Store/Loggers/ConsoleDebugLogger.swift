//
//  ConsoleDebugLogger.swift
//  
//
//  Created by Max Kuznetsov on 25.08.2021.
//

import Foundation

public struct ConsoleDebugLogger: ActionLogger {
    var options: Options

    public init(options: ConsoleDebugLogger.Options) {
        self.options = options
    }

    public func log(_ action: LoggingAction) {
        #if DEBUG
        switch options {
        case .error where action.action is Actions.Error:
            printAction(action)

        case .all:
            printAction(action)

        default:
            break
        }
        #endif
    }

    private func printAction(_ action: LoggingAction) {
        print("Reduce\t\t \(action)\n---------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
    }
}

public extension ConsoleDebugLogger {
    enum Options: Sendable {
        case none, error, all
    }
}
