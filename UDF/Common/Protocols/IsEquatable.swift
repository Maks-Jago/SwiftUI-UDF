//===--- IsEquatable.swift ----------------------------------------===//
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

/// A protocol that defines an `isEqual` method for checking equality between two instances of `IsEquatable`.
///
/// `IsEquatable` allows objects of different types that conform to it to be compared for equality in a type-safe manner.
/// This protocol is particularly useful in cases where you need to compare objects for equality without knowing their exact type at
/// compile-time.
///
/// ## Example
/// ```swift
/// struct ExampleStruct: IsEquatable, Equatable {
///     let id: Int
/// }
///
/// let item1 = ExampleStruct(id: 1)
/// let item2 = ExampleStruct(id: 2)
///
/// let areEqual = item1.isEqual(item2) // Returns `false` since `id` values are different
/// ```
public protocol IsEquatable {
    /// Checks if the current instance is equal to another instance of `IsEquatable`.
    ///
    /// - Parameter rhs: Another instance of `IsEquatable` to compare with.
    /// - Returns: A Boolean value indicating whether the current instance is equal to `rhs`.
    func isEqual(_ rhs: IsEquatable) -> Bool
}

public extension IsEquatable where Self: Equatable {
    /// Default implementation of `isEqual` for types that conform to both `IsEquatable` and `Equatable`.
    ///
    /// This method attempts to cast the provided `rhs` instance to the same type as `self`. If the cast is successful,
    /// it uses the `==` operator to compare the two instances. If the cast fails, it returns `false`.
    ///
    /// - Parameter rhs: Another instance of `IsEquatable` to compare with.
    /// - Returns: A Boolean value indicating whether the current instance is equal to `rhs`.
    func isEqual(_ rhs: IsEquatable) -> Bool {
        guard let rhs = rhs as? Self else {
            return false
        }
        return self == rhs
    }
}
