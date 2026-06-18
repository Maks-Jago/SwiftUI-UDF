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
    /// Keeps a property from the old value if the new value matches a specific value.
    ///
    /// - Parameters:
    ///   - keyPath: The WritableKeyPath to the property.
    ///   - old: The original instance containing the old value.
    ///   - value: The value which triggers keeping of the old value.
    mutating func keep<T: Equatable>(
        _ keyPath: WritableKeyPath<Self, T>,
        from old: Self,
        ifNewIs value: T
    ) {
        if self[keyPath: keyPath] == value {
            self[keyPath: keyPath] = old[keyPath: keyPath]
        }
    }

    /// Keeps a collection property from the old value if the new one is empty.
    ///
    /// - Parameters:
    ///   - keyPath: The WritableKeyPath to the collection property.
    ///   - old: The original instance containing the old value.
    ///   - ifNewIsEmpty: If true, keeps the old value when the new collection is empty.
    mutating func keep<T: Collection>(
        _ keyPath: WritableKeyPath<Self, T>,
        from old: Self,
        ifNewIsEmpty: Bool
    ) {
        if ifNewIsEmpty && self[keyPath: keyPath].isEmpty {
            self[keyPath: keyPath] = old[keyPath: keyPath]
        }
    }

    /// Keeps a property from the old value based on a custom condition closure comparing old and new values.
    ///
    /// - Parameters:
    ///   - keyPath: The WritableKeyPath to the property.
    ///   - old: The original instance containing the old value.
    ///   - condition: A closure taking the old property value and the new property value, returning true if the old value should be kept.
    mutating func keep<T>(
        _ keyPath: WritableKeyPath<Self, T>,
        from old: Self,
        where condition: (_ oldValue: T, _ newValue: T) -> Bool
    ) {
        if condition(old[keyPath: keyPath], self[keyPath: keyPath]) {
            self[keyPath: keyPath] = old[keyPath: keyPath]
        }
    }
}
