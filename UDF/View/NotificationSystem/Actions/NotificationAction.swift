//===--- NotificationAction.swift ----------------------------------===//
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

/// A protocol representing an action in a notification, conforming to `Hashable` and `View`.
///
/// The `NotificationAction` protocol defines interactive elements that can be used
/// within notifications, such as buttons or text fields. Since it conforms to `Hashable`,
/// any types implementing this protocol can be uniquely identified and stored in
/// collections like sets or used as dictionary keys.
///
/// This protocol replaces the previous `AlertAction` protocol and extends support
/// across all notification styles (alerts, toasts, etc.).
///
/// ## Conforming Types:
/// - `NotificationButton` - Interactive buttons with roles and actions
/// - `NotificationTextField` - Text input fields with configuration options
///
/// ## Usage:
/// ```swift
/// struct CustomAction: NotificationAction {
///     // Implementation
/// }
/// ```
public protocol NotificationAction: Hashable, View, Sendable {
    // No additional requirements beyond Hashable and View
}

// MARK: - Default Implementation
extension NotificationAction {
    /// Creates a mutated copy of the conforming `NotificationAction` object by applying the specified block.
    ///
    /// This method is useful when you want to modify properties of a value type (e.g., structs) conforming to
    /// `NotificationAction`. It takes a closure that modifies a mutable copy of the object and returns the modified copy.
    ///
    /// This is a direct migration from the `AlertAction.mutate()` method, providing the same functionality
    /// for notification actions.
    ///
    /// - Parameter block: A closure that takes an `inout` reference to the object, allowing properties to be modified.
    /// - Returns: A modified copy of the object after applying the changes in the closure.
    ///
    /// ## Example:
    /// ```swift
    /// let button = NotificationButton(title: "Save", action: {})
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

/// Classifies the type of notification action for validation and presentation purposes.
public enum NotificationActionType: Equatable {
    /// A button action that triggers behavior when tapped.
    case button
    
    /// A text input field that captures user input.
    case textField
    
    /// A custom action type for future extensibility.
    case custom
}

// MARK: - Action Capability

/// Describes the capabilities and requirements of a notification action.
public struct NotificationActionCapability: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// Action requires user interaction (tapping, typing, etc.).
    nonisolated(unsafe) public static let requiresInteraction = NotificationActionCapability(rawValue: 1 << 0)
    
    /// Action can be disabled/enabled.
    nonisolated(unsafe) public static let canBeDisabled = NotificationActionCapability(rawValue: 1 << 1)
    
    /// Action has a semantic role (cancel, destructive, etc.).
    nonisolated(unsafe) public static let hasRole = NotificationActionCapability(rawValue: 1 << 2)
    
    /// Action captures text input from the user.
    nonisolated(unsafe) public static let capturesTextInput = NotificationActionCapability(rawValue: 1 << 3)
    
    /// Action triggers immediate notification dismissal.
    nonisolated(unsafe) public static let dismissesNotification = NotificationActionCapability(rawValue: 1 << 4)
}

// MARK: - Action Classification Protocol

/// Protocol for classifying notification action types and capabilities.
/// This is used internally for validation and presentation logic.
internal protocol NotificationActionClassification {
    /// The type of this action.
    var actionType: NotificationActionType { get }
    
    /// The capabilities of this action.
    var capabilities: NotificationActionCapability { get }
}

// MARK: - Action Validation
/// Validates notification actions for compatibility with different notification styles.
public enum NotificationActionValidator {
    /// Validates whether the given actions are compatible with the specified notification style.
    ///
    /// - Parameters:
    ///   - actions: The actions to validate.
    ///   - style: The notification style to validate against.
    /// - Returns: True if all actions are compatible with the style.
    public static func validate(actions: [any NotificationAction], for style: NotificationStyle) -> Bool {
        return style.canPresentActions(actions)
    }
    
    /// Validates whether the given actions have valid configurations.
    ///
    /// - Parameter actions: The actions to validate.
    /// - Returns: True if all actions have valid configurations.
    public static func validateConfiguration(actions: [any NotificationAction]) -> Bool {
        return actions.allSatisfy { action in
            if let button = action as? NotificationButton {
                return !button.title.isEmpty
            }
            if let textField = action as? NotificationTextField {
                return !textField.title.isEmpty
            }
            return true
        }
    }
    
    /// Returns the maximum number of actions supported by the given notification style.
    ///
    /// - Parameter style: The notification style.
    /// - Returns: The maximum number of actions, or nil if unlimited.
    public static func maximumActionCount(for style: NotificationStyle) -> Int? {
        switch style {
        case .alert:
            return nil
        }
    }
}
