//===--- NotificationActionsBuilder.swift ----------------------------------===//
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

/// A result builder that constructs an array of `NotificationAction` elements.
///
/// `NotificationActionsBuilder` allows for building an array of `NotificationAction` elements in a declarative way,
/// using Swift's result builder syntax. It enables the creation of notification actions in a more readable and
/// flexible manner, similar to how SwiftUI uses result builders for view construction.
///
/// This is a direct migration from `AlertActionsBuilder` with identical functionality, ensuring compatibility
/// with existing code while extending support to all notification styles.
///
/// This result builder provides various methods for building notification actions based on different input types,
/// including conditionals, optionals, and expressions.
///
/// ## Usage:
/// ```swift
/// @NotificationActionsBuilder
/// func buildActions() -> [any NotificationAction] {
///     NotificationButton.default("OK") {
///         print("OK tapped")
///     }
///     
///     if showCancel {
///         NotificationButton.cancel("Cancel")
///     }
///     
///     NotificationTextField(title: "Input", text: $inputText)
/// }
/// ```
@resultBuilder
public enum NotificationActionsBuilder {
    /// Chooses the first component in an `if-else` conditional block.
    ///
    /// - Parameter component: An array of `NotificationAction` elements to include if the condition is true.
    /// - Returns: The array of `NotificationAction` elements.
    public static func buildEither(first component: [any NotificationAction]) -> [any NotificationAction] {
        component
    }
    
    /// Chooses the second component in an `if-else` conditional block.
    ///
    /// - Parameter component: An array of `NotificationAction` elements to include if the condition is false.
    /// - Returns: The array of `NotificationAction` elements.
    public static func buildEither(second component: [any NotificationAction]) -> [any NotificationAction] {
        component
    }
    
    /// Builds an optional component.
    ///
    /// - Parameter component: An optional array of `NotificationAction` elements.
    /// - Returns: The array of `NotificationAction` elements, or an empty array if the component is `nil`.
    public static func buildOptional(_ component: [any NotificationAction]?) -> [any NotificationAction] {
        component ?? []
    }
    
    /// Builds a single `NotificationAction` expression into an array.
    ///
    /// - Parameter expression: A `NotificationAction` element.
    /// - Returns: An array containing the single `NotificationAction` element.
    public static func buildExpression(_ expression: some NotificationAction) -> [any NotificationAction] {
        [expression]
    }
    
    /// Builds an empty array when an expression is of type `Void`.
    ///
    /// - Parameter expression: A `Void` type expression.
    /// - Returns: An empty array of `NotificationAction` elements.
    public static func buildExpression(_ expression: ()) -> [any NotificationAction] {
        []
    }
    
    /// Builds an array of `NotificationAction` elements with limited availability.
    ///
    /// - Parameter components: An array of `NotificationAction` elements with limited availability.
    /// - Returns: The array of `NotificationAction` elements.
    public static func buildLimitedAvailability(_ components: [any NotificationAction]) -> [any NotificationAction] {
        components
    }
    
    /// Combines multiple arrays of `NotificationAction` elements into a single array.
    ///
    /// - Parameter components: A variadic list of arrays containing `NotificationAction` elements.
    /// - Returns: A flattened array of all `NotificationAction` elements.
    public static func buildBlock(_ components: [any NotificationAction]...) -> [any NotificationAction] {
        components.flatMap { $0 }
    }
    
    /// Combines an array of `NotificationAction` arrays into a single array.
    ///
    /// - Parameter components: An array of arrays, each containing `NotificationAction` elements.
    /// - Returns: A flattened array of all `NotificationAction` elements.
    public static func buildArray(_ components: [[any NotificationAction]]) -> [any NotificationAction] {
        components.flatMap { $0 }
    }
}

// MARK: - Builder Validation
/// Validates the output of a `NotificationActionsBuilder` for a specific notification style.
public enum NotificationActionsBuilderValidator {
    /// Validates the actions produced by a builder for compatibility with a notification style.
    ///
    /// - Parameters:
    ///   - actions: The actions to validate.
    ///   - style: The notification style to validate against.
    /// - Returns: A validation result indicating success or failure with details.
    public static func validate(
        actions: [any NotificationAction],
        for style: NotificationStyle
    ) -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Check if the style can present these actions
        if !style.canPresentActions(actions) {
            errors.append("Notification style \(style) cannot present all provided actions")
        }
        
        // Validate individual action configurations
        for (index, action) in actions.enumerated() {
            if let button = action as? NotificationButton {
                if !button.isValid {
                    errors.append("Button at index \(index) is invalid: \(button.validationErrors.joined(separator: ", "))")
                }
            } else if let textField = action as? NotificationTextField {
                if !textField.isValid {
                    errors.append("Text field at index \(index) is invalid: \(textField.validationErrors.joined(separator: ", "))")
                }
            }
        }
        
        // Check for potential issues
        let buttonCount = actions.compactMap { $0 as? NotificationButton }.count
        let textFieldCount = actions.compactMap { $0 as? NotificationTextField }.count
        
        // Warn about too many actions for certain styles
        if case .alert = style, buttonCount > 3 {
            warnings.append("Alerts with more than 3 buttons may not display properly")
        }
        
        // Warn about multiple text fields
        if textFieldCount > 2 {
            warnings.append("Multiple text fields may create a poor user experience")
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    /// Result of validating notification actions.
    public struct ValidationResult {
        /// Whether the validation passed without errors.
        public let isValid: Bool
        
        /// Critical errors that prevent the actions from being used.
        public let errors: [String]
        
        /// Non-critical warnings about potential issues.
        public let warnings: [String]
        
        /// A human-readable description of all validation issues.
        public var description: String {
            var parts: [String] = []
            
            if !errors.isEmpty {
                parts.append("Errors: \(errors.joined(separator: "; "))")
            }
            
            if !warnings.isEmpty {
                parts.append("Warnings: \(warnings.joined(separator: "; "))")
            }
            
            return parts.isEmpty ? "Validation passed" : parts.joined(separator: " | ")
        }
    }
}

// MARK: - Builder Helpers
/// Helper functions for working with `NotificationActionsBuilder` results.
public enum NotificationActionsBuilderHelpers {
    /// Counts the actions of a specific type in the builder result.
    ///
    /// - Parameters:
    ///   - actions: The actions to analyze.
    ///   - type: The type of action to count.
    /// - Returns: The number of actions of the specified type.
    public static func count<T: NotificationAction>(
        actions: [any NotificationAction],
        ofType type: T.Type
    ) -> Int {
        actions.compactMap { $0 as? T }.count
    }
    
    /// Filters actions to only include those of a specific type.
    ///
    /// - Parameters:
    ///   - actions: The actions to filter.
    ///   - type: The type of action to include.
    /// - Returns: An array containing only actions of the specified type.
    public static func filter<T: NotificationAction>(
        actions: [any NotificationAction],
        toType type: T.Type
    ) -> [T] {
        actions.compactMap { $0 as? T }
    }
    
    /// Checks if the actions contain any of a specific type.
    ///
    /// - Parameters:
    ///   - actions: The actions to check.
    ///   - type: The type of action to look for.
    /// - Returns: True if at least one action of the specified type is found.
    public static func contains<T: NotificationAction>(
        actions: [any NotificationAction],
        actionOfType type: T.Type
    ) -> Bool {
        actions.contains { $0 is T }
    }
    
    /// Groups actions by their type for analysis.
    ///
    /// - Parameter actions: The actions to group.
    /// - Returns: A dictionary mapping action types to their counts.
    public static func groupByType(actions: [any NotificationAction]) -> [String: Int] {
        var groups: [String: Int] = [:]
        
        for action in actions {
            let typeName = String(describing: type(of: action))
            groups[typeName, default: 0] += 1
        }
        
        return groups
    }
}
