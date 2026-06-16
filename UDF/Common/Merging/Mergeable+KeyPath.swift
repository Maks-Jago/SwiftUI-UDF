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
    /// Merges an optional property, preserving the old value if the new one is nil.
    ///
    /// - Parameters:
    ///   - old: The original instance containing the old value.
    ///   - keyPath: The WritableKeyPath to the optional property.
    mutating func merge<T>(_ old: Self, _ keyPath: WritableKeyPath<Self, T?>) {
        if self[keyPath: keyPath] == nil {
            self[keyPath: keyPath] = old[keyPath: keyPath]
        }
    }

    /// Merges a collection property, preserving the old value if the new one is empty.
    ///
    /// - Parameters:
    ///   - old: The original instance containing the old value.
    ///   - keyPath: The WritableKeyPath to the collection property.
    mutating func merge<T: Collection>(_ old: Self, _ keyPath: WritableKeyPath<Self, T>) {
        if self[keyPath: keyPath].isEmpty {
            self[keyPath: keyPath] = old[keyPath: keyPath]
        }
    }

    /// Merges a property, preserving the old value if the new one matches a specific "default" value.
    ///
    /// - Parameters:
    ///   - old: The original instance containing the old value.
    ///   - keyPath: The WritableKeyPath to the property.
    ///   - defaultValue: The default value which triggers preservation of the old value.
    mutating func merge<T: Equatable>(_ old: Self, _ keyPath: WritableKeyPath<Self, T>, preserving defaultValue: T) {
        if self[keyPath: keyPath] == defaultValue {
            self[keyPath: keyPath] = old[keyPath: keyPath]
        }
    }
}
