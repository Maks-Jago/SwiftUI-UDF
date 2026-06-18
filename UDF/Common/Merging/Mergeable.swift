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
    @available(*, deprecated, message: "Use the static merging(_:old:) method instead.")
    func merging(_ newValue: Self) -> Self

    /// Merges a new value with an old value into a pre-populated mutable instance.
    @available(*, deprecated, message: "Use the static merging(_:old:) method instead.")
    static func merging(_ filledValue: inout Self, new newValue: Self, old oldValue: Self)

    /// Merges a new value with an old value in-place, allowing properties from the old value to be selectively restored.
    ///
    /// - Parameters:
    ///   - newValue: The mutating incoming instance containing updated values.
    ///   - oldValue: The existing old instance containing previous values.
    static func merging(_ newValue: inout Self, old oldValue: Self)

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
    /// Default implementation of the legacy instance method forwards to the new static method.
    @available(*, deprecated, message: "Use the static merging(_:old:) method instead.")
    func merging(_ newValue: Self) -> Self {
        var mutableNewValue = newValue
        Self.merging(&mutableNewValue, old: self)
        return mutableNewValue
    }

    /// Default implementation of the deprecated static method forwards to the legacy instance method.
    @available(*, deprecated, message: "Use the static merging(_:old:) method instead.")
    static func merging(_ filledValue: inout Self, new newValue: Self, old oldValue: Self) {
        filledValue = oldValue.merging(newValue)
    }

    /// Default implementation of the new static method forwards to the legacy 3-argument static method.
    static func merging(_ newValue: inout Self, old oldValue: Self) {
        var mutableNew = newValue
        Self.merging(&mutableNew, new: newValue, old: oldValue)
        newValue = mutableNew
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
