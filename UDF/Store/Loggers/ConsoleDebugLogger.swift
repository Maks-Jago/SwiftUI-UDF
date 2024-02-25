//
//  ConsoleDebugLogger.swift
//  
//
//  Created by Max Kuznetsov on 25.08.2021.
//

import Foundation

public struct ConsoleDebugLogger: ActionLogger {
    public var actionFilters: [ActionFilter] = []
    public var actionDescriptor: ActionDescriptor

    public init(filters: [ActionFilter], descriptor: ActionDescriptor = StringDescribingActionDescriptor()) {
        self.actionFilters = filters
        self.actionDescriptor = descriptor
    }

    public func log(_ action: LoggingAction, description: String) {
        print("Reduce\t\t \(description)\n---------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
    }
}

public extension ActionLogger where Self == ConsoleDebugLogger {
    static var consoleDebug: ActionLogger { ConsoleDebugLogger(filters: [.default]) }
    static var consoleDebugVerbose: ActionLogger { ConsoleDebugLogger(filters: [.verbose]) }
    static var consoleDebugOnlyErrors: ActionLogger { ConsoleDebugLogger(filters: [.errorOnly]) }

    static func consoleDebug(extraFilters: [ActionFilter]) -> ActionLogger {
        ConsoleDebugLogger(filters: [.debugOnly] + extraFilters)
    }
}
