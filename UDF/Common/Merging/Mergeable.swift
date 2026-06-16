//===--- Mergeable.swift -------------------------------------===//
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

/// A protocol that allows types to define merging and filling behavior.
/// Types conforming to `Mergeable` can combine instances and modify themselves based on other instances.
public protocol Mergeable {
    /// Merges the current instance with a new value and returns the result.
    ///
    /// - Parameter newValue: The new value to merge with the current instance.
    /// - Returns: A new instance of the same type, containing the merged values of both instances.
    @available(*, deprecated, message: "Use the static merging(_:new:old:) method instead.")
    func merging(_ newValue: Self) -> Self

    /// Merges a new value with an old value into a pre-populated mutable instance.
    ///
    /// - Parameters:
    ///   - filledValue: The mutable instance where the merged result is constructed.
    ///                  It is pre-populated with `newValue` before this method is called.
    ///   - newValue: The incoming new instance containing updated values.
    ///   - oldValue: The existing old instance containing previous values.
    static func merging(_ filledValue: inout Self, new newValue: Self, old oldValue: Self)

    /// Fills the current instance using values from another instance, allowing for further mutation.
    ///
    /// - Parameters:
    ///   - value: The instance from which values will be filled into the current instance.
    ///   - mutate: A closure that provides the ability to mutate the filled instance with additional logic.
    ///             - `filled`: An `inout` parameter representing the instance being filled.
    ///             - `old`: The original instance before filling.
    /// - Returns: A new instance of the same type, filled with values from the provided instance and modified as needed.
    func filled(from value: Self, mutate: (_ filled: inout Self, _ old: Self) -> Void) -> Self
}

public extension Mergeable {
    /// Default implementation of the legacy instance method forwards to the static method.
    @available(*, deprecated, message: "Use the static merging(_:new:old:) method instead.")
    func merging(_ newValue: Self) -> Self {
        var filledValue = newValue
        Self.merging(&filledValue, new: newValue, old: self)
        return filledValue
    }

    /// Default implementation of the modern static method forwards to the legacy instance method.
    static func merging(_ filledValue: inout Self, new newValue: Self, old oldValue: Self) {
        filledValue = oldValue.merging(newValue)
    }
    /// Fills the current instance with values from another instance, and performs a custom mutation on the filled instance.
    ///
    /// - Parameters:
    ///   - value: The instance to fill from.
    ///   - mutate: A closure that allows for additional mutation on the filled instance.
    /// - Returns: A new instance filled with values from the provided `value`.
    func filled(from value: Self, mutate: (_ filled: inout Self, _ old: Self) -> Void) -> Self {
        var mutableSelf = value
        mutate(&mutableSelf, self)
        return mutableSelf
    }
}
