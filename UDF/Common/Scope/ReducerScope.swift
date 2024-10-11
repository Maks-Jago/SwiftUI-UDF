//===--- ReducerScope.swift ---------------------------------------===//
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

/// A class representing a scope that contains a `Reducible` reducer.
/// This is used to encapsulate a reducer within a specific scope, providing
/// methods for equality checks and management of the reducer instance.
final class ReducerScope<R: Reducible>: EquatableScope {
    /// The reducer instance that this scope manages.
    var reducer: R?

    /// Initializes a new `ReducerScope` with the provided reducer.
    /// - Parameter reducer: An optional `Reducible` instance to be managed by this scope.
    init(reducer: R?) {
        self.reducer = reducer
    }

    /// Checks for equality between two `ReducerScope` instances.
    /// - Parameters:
    ///   - lhs: The left-hand side `ReducerScope` to compare.
    ///   - rhs: The right-hand side `ReducerScope` to compare.
    /// - Returns: A Boolean value indicating whether the two scopes are equal.
    static func == (lhs: ReducerScope<R>, rhs: ReducerScope<R>) -> Bool {
        lhs.reducer == rhs.reducer
    }
}
