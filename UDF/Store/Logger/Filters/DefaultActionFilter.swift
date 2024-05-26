//
//  DefaultActionFilter.swift
//  
//
//  Created by Max Kuznetsov on 30.04.2023.
//

import Foundation

public struct DefaultActionFilter: ActionFilter {
    public init() {}

    public func include(action: LoggingAction) -> Bool {
        action.internalAction.silent == false
    }
}

public extension ActionFilter where Self == DefaultActionFilter {
    static var `default`: ActionFilter { DefaultActionFilter() }
}
