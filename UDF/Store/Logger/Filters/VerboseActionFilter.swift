//
//  VerboseActionFilter.swift
//  
//
//  Created by Max Kuznetsov on 30.04.2023.
//

import Foundation

public struct VerboseActionFilter: ActionFilter {
    public init() {}

    public func include(action: LoggingAction) -> Bool {
        true
    }
}

public extension ActionFilter where Self == VerboseActionFilter {
    static var verbose: ActionFilter { VerboseActionFilter() }
}
