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
    func merging(_ newValue: Self) -> Self
    
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
