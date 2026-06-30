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
    /// Keeps a property from the old value if the condition evaluates to true.
    ///
    /// - Parameters:
    ///   - keyPath: The WritableKeyPath to the property.
    ///   - old: The original instance containing the old value.
    ///   - condition: An autoclosure condition that determines if the old value should be kept.
    /// - Returns: A copy of the instance with the property reverted if the condition is met.
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
