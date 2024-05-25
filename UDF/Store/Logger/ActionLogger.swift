//
//  ActionLogging.swift
//  
//
//  Created by Max Kuznetsov on 25.08.2021.
//

import Foundation

public protocol ActionFilter: Sendable {
    func include(action: LoggingAction) -> Bool
}

public protocol ActionDescriptor: Sendable {
    func description(for action: LoggingAction) -> String
}

public protocol ActionLogger: Sendable {
    var actionFilters: [ActionFilter] { get }
    var actionDescriptor: ActionDescriptor { get }

    func log(_ action: LoggingAction, description: String)
}
