//===--- Mergeable+KeyPath.swift -----------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

public extension Mergeable {
    /// Returns a copy of this value in which the property at a key path comes from another value when a
    /// condition is true.
    ///
    /// Call `keeping` on the new value to restore a property of the old value:
    ///
    /// ```swift
    /// let merged = newCustomer.keeping(
    ///     \.biography,
    ///     from: oldCustomer,
    ///     where: newCustomer.biography == nil
    /// )
    /// ```
    ///
    /// Chain several calls to restore several properties. See ``Mergeable/merging(new:old:)``.
    ///
    /// The method doesn't modify the value it's called on. When `condition` is false, the returned copy is
    /// equal to that value.
    ///
    /// - Parameters:
    ///   - keyPath: The property to take from `old`.
    ///   - old: The value that provides the property when `condition` is true.
    ///   - condition: An expression, evaluated once, that determines whether the property is taken from
    ///     `old`.
    /// - Returns: A copy of this value with the property at `keyPath` taken from `old` if `condition` is
    ///   true, or an unchanged copy otherwise.
    func keeping<T>(
        _ keyPath: WritableKeyPath<Self, T>,
        from old: Self,
        where condition: @autoclosure () -> Bool
    ) -> Self {
        var copy = self
        if condition() {
            copy[keyPath: keyPath] = old[keyPath: keyPath]
        }
        return copy
    }
}
