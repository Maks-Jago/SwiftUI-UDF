//===--- CombinedScope.swift ---------------------------------------===//
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

/// A class that combines two `EquatableScope` instances into a single scope.
/// This is used to aggregate multiple scopes for complex state management
/// where the combination of different scopes is necessary.
final class CombinedScope<S1: EquatableScope, S2: EquatableScope>: EquatableScope {
    
    /// The left-hand scope instance.
    var lhsScope: S1
    
    /// The right-hand scope instance.
    var rhsScope: S2
    
    /// Initializes a new `CombinedScope` with two scopes.
    /// - Parameters:
    ///   - lhs: The left-hand scope to combine.
    ///   - rhs: The right-hand scope to combine.
    init(_ lhs: S1, _ rhs: S2) {
        lhsScope = lhs
        rhsScope = rhs
    }
    
    /// Checks for equality between two `CombinedScope` instances.
    /// - Parameters:
    ///   - lhs: The left-hand side `CombinedScope` to compare.
    ///   - rhs: The right-hand side `CombinedScope` to compare.
    /// - Returns: A Boolean value indicating whether the two combined scopes are equal.
    static func == (lhs: CombinedScope<S1, S2>, rhs: CombinedScope<S1, S2>) -> Bool {
        lhs.lhsScope == rhs.lhsScope && lhs.rhsScope == rhs.rhsScope
    }
}
