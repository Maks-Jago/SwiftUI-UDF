//===--- DialogAction.swift ----------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2025 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

/// A protocol representing an action in a dialog, conforming to `Hashable` and `View`.
///
/// The `DialogAction` protocol defines interactive elements that can be used
/// within dialogs, such as buttons or text fields. Since it conforms to `Hashable`,
/// types implementing this protocol can be compared and stored in
/// collections like sets or used as dictionary keys.
///
/// ## Conforming Types:
/// - `DialogButton` - Interactive buttons with roles and actions
/// - `DialogTextField` - Text input fields with configuration options
///
/// ## Usage:
/// ```swift
/// struct CustomAction: DialogAction {
///     // Implementation
/// }
/// ```
public protocol DialogAction: Hashable, View, Sendable {}

// MARK: - Default Implementation
extension DialogAction {
    /// Creates a mutated copy of the conforming `DialogAction` object by applying the specified block.
    ///
    /// This method is useful when you want to modify properties of a value type (e.g., structs) conforming to
    /// `DialogAction`. It takes a closure that modifies a mutable copy of the object and returns the modified copy.
    ///
    /// - Parameter block: A closure that takes an `inout` reference to the object, allowing properties to be modified.
    /// - Returns: A modified copy of the object after applying the changes in the closure.
    ///
    /// ## Example:
    /// ```swift
    /// let button = DialogButton(title: "Save", action: {})
    /// let disabledButton = button.mutate { button in
    ///     button.disabled = true
    /// }
    /// ```
    nonisolated public func mutate(_ block: (inout Self) -> Void) -> Self {
        var copy = self
        block(&copy)
        return copy
    }
}
