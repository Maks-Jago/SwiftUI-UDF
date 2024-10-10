//===--- VerboseActionFilter.swift ---------------------------------------===//
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

/// An action filter that includes all actions, regardless of their type or properties.
public struct VerboseActionFilter: ActionFilter {
    
    /// Creates a new instance of `VerboseActionFilter`.
    public init() {}
    
    /// Determines whether a given action should be included.
    ///
    /// - Parameter action: The action to be evaluated.
    /// - Returns: Always returns `true` to include all actions.
    public func include(action: LoggingAction) -> Bool {
        true
    }
}

public extension ActionFilter where Self == VerboseActionFilter {
    /// A static property that provides a `VerboseActionFilter` for including all actions.
    static var verbose: ActionFilter { VerboseActionFilter() }
}
