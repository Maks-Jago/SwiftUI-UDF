//===--- ErrorOnlyActionFilter.swift -------------------------------------===//
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

/// An action filter that includes only error actions of type `Actions.Error`.
public struct ErrorOnlyActionFilter: ActionFilter {
    /// Determines whether a given action should be included.
    ///
    /// - Parameter action: The action to be evaluated.
    /// - Returns: `true` if the action is of type `Actions.Error`; `false` otherwise.
    public func include(action: LoggingAction) -> Bool {
        action.value is Actions.Error
    }
}

public extension ActionFilter where Self == ErrorOnlyActionFilter {
    /// A static property that provides an `ErrorOnlyActionFilter` for filtering only error actions.
    static var errorOnly: ActionFilter { ErrorOnlyActionFilter() }
}
