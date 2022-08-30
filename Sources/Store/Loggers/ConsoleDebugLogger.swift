//
//  ConsoleDebugLogger.swift
//  
//
//  Created by Max Kuznetsov on 25.08.2021.
//

import Foundation

public struct ConsoleDebugLogger: ActionLogging {
    var options: Options

    public init(options: ConsoleDebugLogger.Options) {
        self.options = options
    }

    public func log(_ action: AnyAction) {
        #if DEBUG
        switch options {
        case .error where action.value is Actions.Error:
            printAction(action)

        case .all:
            printAction(action)

        default:
            break
        }
        #endif
    }

    private func printAction(_ action: AnyAction) {
        print("Reduce\t\t \(action)\n---------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
    }
}

public extension ConsoleDebugLogger {
    enum Options {
        case none, error, all
    }
}