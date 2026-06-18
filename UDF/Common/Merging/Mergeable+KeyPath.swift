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
    /// Restores a property from the old value if the new value matches a specific value.
    ///
    /// - Parameters:
    ///   - keyPath: The WritableKeyPath to the property.
    ///   - old: The original instance containing the old value.
    ///   - value: The value which triggers restoration of the old value.
    mutating func restore<T: Equatable>(
        _ keyPath: WritableKeyPath<Self, T>,
        from old: Self,
        ifNewIs value: T
    ) {
        if self[keyPath: keyPath] == value {
            self[keyPath: keyPath] = old[keyPath: keyPath]
        }
    }

    /// Restores a collection property from the old value if the new one is empty.
    ///
    /// - Parameters:
    ///   - keyPath: The WritableKeyPath to the collection property.
    ///   - old: The original instance containing the old value.
    ///   - ifNewIsEmpty: If true, restores the old value when the new collection is empty.
    mutating func restore<T: Collection>(
        _ keyPath: WritableKeyPath<Self, T>,
        from old: Self,
        ifNewIsEmpty: Bool
    ) {
        if ifNewIsEmpty && self[keyPath: keyPath].isEmpty {
            self[keyPath: keyPath] = old[keyPath: keyPath]
        }
    }

    /// Restores a property from the old value based on a custom condition closure comparing old and new values.
    ///
    /// - Parameters:
    ///   - keyPath: The WritableKeyPath to the property.
    ///   - old: The original instance containing the old value.
    ///   - condition: A closure taking the old property value and the new property value, returning true if the old value should be restored.
    mutating func restore<T>(
        _ keyPath: WritableKeyPath<Self, T>,
        from old: Self,
        where condition: (_ oldValue: T, _ newValue: T) -> Bool
    ) {
        if condition(old[keyPath: keyPath], self[keyPath: keyPath]) {
            self[keyPath: keyPath] = old[keyPath: keyPath]
        }
    }
}
