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
/// any types implementing this protocol can be uniquely identified and stored in
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
public protocol DialogAction: Hashable, Sendable {}

@available(*, deprecated, message: "Use `DialogAction` instead.")
public typealias AlertAction = DialogAction

@available(*, deprecated, message: "Use `DialogButton` instead.")
public typealias AlertButton = DialogButton

@available(*, deprecated, message: "Use `DialogTextField` instead.")
public typealias AlertTextField = DialogTextField

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
    /// let button = DialogAction(title: "Save", action: {})
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

// MARK: - Action Type Classification

/// Classifies the type of dialog action for presentation purposes.
public enum DialogActionType: Equatable {
    /// A button action that triggers behavior when tapped.
    case button
    
    /// A text input field that captures user input.
    case textField
    
    /// A custom action type for future extensibility.
    case custom
}

// MARK: - Action Capability

/// Describes the capabilities and requirements of a dialog action.
public struct DialogActionCapability: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// Action requires user interaction (tapping, typing, etc.).
    nonisolated(unsafe) public static let requiresInteraction =  DialogActionCapability(rawValue: 1 << 0)
    
    /// Action can be disabled/enabled.
    nonisolated(unsafe) public static let canBeDisabled = DialogActionCapability(rawValue: 1 << 1)
    
    /// Action has a semantic role (cancel, destructive, etc.).
    nonisolated(unsafe) public static let hasRole = DialogActionCapability(rawValue: 1 << 2)
    
    /// Action captures text input from the user.
    nonisolated(unsafe) public static let capturesTextInput = DialogActionCapability(rawValue: 1 << 3)
    
    /// Action triggers immediate dialog dismissal.
    nonisolated(unsafe) public static let dismissesDialog = DialogActionCapability(rawValue: 1 << 4)
}

// MARK: - Action Classification Protocol

/// Protocol for classifying dialog action types and capabilities.
/// This is used internally for presentation logic.
protocol DialogActionClassification {
    /// The type of this action.
    var actionType: DialogActionType { get }
    
    /// The capabilities of this action.
    var capabilities: DialogActionCapability { get }
}
