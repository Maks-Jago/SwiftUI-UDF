//===--- NotificationContent.swift ----------------------------------===//
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

/// Represents the content of a complex notification with title, message, and actions.
///
/// `NotificationContent` provides a structured way to define notifications that require
/// more than a simple message string. It supports titles, optional messages, and
/// interactive actions built using the `NotificationActionsBuilder`.
///
/// This replaces the need for complex `AlertStyle` configurations and provides a
/// unified content model that works across all notification styles.
///
/// ## Usage:
/// ```swift
/// // Simple content with just a title
/// let content = NotificationContent("Delete Item")
/// 
/// // Content with title and message
/// let content = NotificationContent("Delete Item", message: "This cannot be undone")
/// 
/// // Content with title, message, and actions
/// let content = NotificationContent("Delete Item", message: "This cannot be undone") {
///     NotificationButton.destructive("Delete") {
///         performDelete()
///     }
///     NotificationButton.cancel("Cancel")
/// }
/// ```
public struct NotificationContent: Equatable, Sendable {
    /// The title of the notification content.
    public let title: String
    
    /// An optional message providing additional details.
    public let message: String?
    
    /// The interactive actions available for this content.
    public let actions: [any NotificationAction]
    
    // MARK: - Computed Properties
    /// Whether this content has any actions.
    public var hasActions: Bool {
        !actions.isEmpty
    }
    
    /// The number of actions in this content.
    public var actionCount: Int {
        actions.count
    }
    
    /// Whether this content has a message.
    public var hasMessage: Bool {
        message != nil && !message!.isEmpty
    }
    
    /// A combined text representation of title and message.
    public var fullText: String {
        if let message = message, !message.isEmpty {
            return "\(title)\n\(message)"
        }
        return title
    }
    
    // MARK: - Initializers
    /// Creates notification content with a title only.
    ///
    /// - Parameter title: The title of the notification.
    public init(_ title: String) {
        self.title = title
        self.message = nil
        self.actions = []
    }
    
    /// Creates notification content with a title and message.
    ///
    /// - Parameters:
    ///   - title: The title of the notification.
    ///   - message: An optional message for additional details.
    public init(_ title: String, message: String?) {
        self.title = title
        self.message = message
        self.actions = []
    }
    
    /// Creates notification content with a title and actions.
    ///
    /// - Parameters:
    ///   - title: The title of the notification.
    ///   - actions: A closure that builds the notification actions using `NotificationActionsBuilder`.
    public init(
        _ title: String,
        @NotificationActionsBuilder actions: () -> [any NotificationAction]
    ) {
        self.title = title
        self.message = nil
        self.actions = actions()
    }
    
    /// Creates notification content with a title, message, and actions.
    ///
    /// - Parameters:
    ///   - title: The title of the notification.
    ///   - message: An optional message for additional details.
    ///   - actions: A closure that builds the notification actions using `NotificationActionsBuilder`.
    public init(
        _ title: String,
        message: String?,
        @NotificationActionsBuilder actions: () -> [any NotificationAction]
    ) {
        self.title = title
        self.message = message
        self.actions = actions()
    }
    
    /// Creates notification content with explicit parameters.
    ///
    /// - Parameters:
    ///   - title: The title of the notification.
    ///   - message: An optional message for additional details.
    ///   - actions: An array of notification actions.
    public init(
        title: String,
        message: String? = nil,
        actions: [any NotificationAction] = []
    ) {
        self.title = title
        self.message = message
        self.actions = actions
    }
    
    // MARK: - Equatable Implementation
    /// Compares two `NotificationContent` instances for equality.
    ///
    /// Note: Actions are compared by their hash values since they may contain closures
    /// that cannot be directly compared.
    public static func == (lhs: NotificationContent, rhs: NotificationContent) -> Bool {
        lhs.title == rhs.title &&
        lhs.message == rhs.message &&
        lhs.actions.count == rhs.actions.count &&
        zip(lhs.actions, rhs.actions).allSatisfy { lhsAction, rhsAction in
            // Compare actions by their hash values and types
            lhsAction.hashValue == rhsAction.hashValue &&
            type(of: lhsAction) == type(of: rhsAction)
        }
    }
}

// MARK: - Content Analysis
public extension NotificationContent {
    /// Analyzes the content and returns information about its structure.
    var analysis: ContentAnalysis {
        ContentAnalysis(
            hasTitle: !title.isEmpty,
            hasMessage: hasMessage,
            hasActions: hasActions,
            buttonCount: actions.compactMap { $0 as? NotificationButton }.count,
            textFieldCount: actions.compactMap { $0 as? NotificationTextField }.count,
            totalActionCount: actionCount
        )
    }
    
    /// Information about the structure and content of a notification.
    struct ContentAnalysis {
        public let hasTitle: Bool
        public let hasMessage: Bool
        public let hasActions: Bool
        public let buttonCount: Int
        public let textFieldCount: Int
        public let totalActionCount: Int
        
        /// Whether this content represents a simple notification (title/message only).
        public var isSimple: Bool {
            !hasActions
        }
        
        /// Whether this content represents a complex notification (has actions).
        public var isComplex: Bool {
            hasActions
        }
        
        /// Whether this content is suitable for alert presentation.
        public var isSuitableForAlert: Bool {
            // Alerts work well with any combination of content
            true
        }
        
        /// Whether this content is suitable for toast presentation.
        public var isSuitableForToast: Bool {
            // Toasts work better with simpler content
            // Future implementation when toasts are added
            buttonCount <= 2 && textFieldCount == 0
        }
    }
}

// MARK: - Content Validation
public extension NotificationContent {
    /// Validates the content for a specific notification style.
    ///
    /// - Parameter style: The notification style to validate against.
    /// - Returns: A validation result indicating success or failure.
    func validate(for style: NotificationStyle) -> ValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Validate title
        if title.isEmpty {
            errors.append("Notification title cannot be empty")
        }
        
        // Validate actions for the style
        let actionValidation = NotificationActionsBuilderValidator.validate(actions: actions, for: style)
        errors.append(contentsOf: actionValidation.errors)
        warnings.append(contentsOf: actionValidation.warnings)
        
        // Style-specific validation
        switch style {
        case .alert:
            // Alerts can handle most content types
            if title.count > 200 {
                warnings.append("Very long titles may not display well in alerts")
            }
            if let message = message, message.count > 500 {
                warnings.append("Very long messages may not display well in alerts")
            }
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    /// Result of validating notification content.
    struct ValidationResult {
        /// Whether the validation passed without errors.
        public let isValid: Bool
        
        /// Critical errors that prevent the content from being used.
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

// MARK: - Content Transformation
public extension NotificationContent {
    /// Creates a copy of this content with modified actions.
    ///
    /// - Parameter actions: A closure that builds new actions.
    /// - Returns: A new `NotificationContent` with the updated actions.
    func withActions(@NotificationActionsBuilder actions: () -> [any NotificationAction]) -> NotificationContent {
        NotificationContent(
            title: title,
            message: message,
            actions: actions()
        )
    }
    
    /// Creates a copy of this content with a modified message.
    ///
    /// - Parameter message: The new message.
    /// - Returns: A new `NotificationContent` with the updated message.
    func withMessage(_ message: String?) -> NotificationContent {
        NotificationContent(
            title: title,
            message: message,
            actions: actions
        )
    }
    
    /// Creates a copy of this content with a modified title.
    ///
    /// - Parameter title: The new title.
    /// - Returns: A new `NotificationContent` with the updated title.
    func withTitle(_ title: String) -> NotificationContent {
        NotificationContent(
            title: title,
            message: message,
            actions: actions
        )
    }
}

// MARK: - Hashable Support
extension NotificationContent: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(message)
        hasher.combine(actions.count)
        
        // Hash the types and hash values of actions
        for action in actions {
            hasher.combine(String(describing: type(of: action)))
            hasher.combine(action.hashValue)
        }
    }
}
