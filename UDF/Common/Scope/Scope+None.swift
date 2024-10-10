//===--- Scope+None.swift -----------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

public extension Scope where Self == NoneScope {
    /// A static property that returns an instance of `NoneScope`.
    /// This is useful for cases where no specific scope is needed.
    static var none: NoneScope {
        NoneScope()
    }
}

/// A `Scope` that represents a "none" or empty state.
/// It conforms to `EquatableScope` and is used when no specific scope is required.
public struct NoneScope: EquatableScope {
    
    /// Method to compare equality with another `IsEquatable` instance.
    /// Always returns `true` since `NoneScope` is a placeholder scope.
    /// - Parameter rhs: The right-hand side `IsEquatable` instance to compare.
    /// - Returns: A Boolean value indicating if the instances are considered equal.
    public func isEqual(_ rhs: IsEquatable) -> Bool { true }
}
