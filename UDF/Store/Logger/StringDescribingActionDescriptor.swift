//
//  StringDescribingActionDescriptor.swift
//  
//
//  Created by Max Kuznetsov on 30.04.2023.
//

import Foundation

open class StringDescribingActionDescriptor: @unchecked Sendable, ActionDescriptor {
    public init() {}

    open func description(for action: LoggingAction) -> String {
        String(describing: action)
    }
}
