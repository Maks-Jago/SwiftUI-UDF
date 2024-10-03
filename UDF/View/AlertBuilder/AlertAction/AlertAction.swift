//===--- AlertAction.swift ---------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

/// A protocol representing an action in an alert, conforming to `Hashable`.
///
/// The `AlertAction` protocol is intended to define alert actions, such as buttons or text fields, that can be used
/// within SwiftUI alerts. Since it conforms to `Hashable`, any types implementing this protocol can be uniquely
/// identified and stored in collections like sets or used as dictionary keys.
public protocol AlertAction: Hashable {}

extension AlertAction {
    /// Creates a mutated copy of the conforming `AlertAction` object by applying the specified block.
    ///
    /// This method is useful when you want to modify properties of a value type (e.g., structs) conforming to
    /// `AlertAction`. It takes a closure that modifies a mutable copy of the object and returns the modified copy.
    ///
    /// - Parameter block: A closure that takes an `inout` reference to the object, allowing properties to be modified.
    /// - Returns: A modified copy of the object after applying the changes in the closure.
    ///
    func mutate(_ block: (inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }
}
