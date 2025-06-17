//===--- DialogContent.swift ----------------------------------===//
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

/// Represents the content of a complex dialog with title, message, actions, and custom views.
///
/// `DialogContent` provides a structured way to define dialogs that require
/// more than a simple message string. It supports titles, optional messages, interactive
/// actions, and completely custom SwiftUI views for maximum flexibility.
///
/// This replaces the need for complex configurations and provides a unified content
/// model that works across all dialog styles while supporting the rich custom
/// content capabilities previously available in toast-specific implementations.
///
/// ## Usage:
/// ```swift
/// // Simple content with just a title
/// let content = DialogContent("Delete Item")
/// 
/// // Content with title and message
/// let content = DialogContent("Delete Item", message: "This cannot be undone")
/// 
/// // Content with title, message, and actions
/// let content = DialogContent("Delete Item", message: "This cannot be undone") {
///     DialogButton.destructive("Delete") {
///         performDelete()
///     }
///     DialogButton.cancel("Cancel")
/// }
/// 
/// // Custom view content for rich toast dialogs
/// let content = DialogContent(customView: AnyView(
///     VStack {
///         ProgressView()
///         Text("Uploading...")
///     }
/// ))
/// ```
public struct DialogContent: Equatable, Sendable {
    /// The title of the dialog content.
    public let title: String
    
    /// An optional message providing additional details.
    public let message: String?
    
    /// The interactive actions available for this content.
    public let actions: [any DialogAction]
    
    /// Custom SwiftUI view content for rich dialogs.
    ///
    /// When provided, this custom view takes precedence over the standard
    /// title/message layout. This enables complex, branded, or interactive
    /// dialog designs that can't be achieved with text and buttons alone.
    ///
    /// ## Examples:
    /// - Progress indicators with real-time updates
    /// - Rich media content with images and custom layouts
    /// - Branded dialog designs with company styling
    /// - Interactive elements beyond simple buttons
    ///
    /// ## Performance Considerations:
    /// - Keep custom views lightweight for smooth animation performance
    /// - Avoid heavy computations or network calls in view content
    /// - Consider the dialog's brief display duration when designing interactions
    ///
    /// ## Accessibility:
    /// - Ensure custom views maintain proper accessibility labels and hints
    /// - Test with VoiceOver and other assistive technologies
    /// - Provide appropriate contrast ratios for text and interactive elements
    public nonisolated(unsafe) let customView: AnyView?
    
    /// The icon to display with this dialog content.
    ///
    /// Supports various icon types including SF Symbols, custom images, and
    /// arbitrary SwiftUI views. When nil, the dialog system will use
    /// semantic defaults based on the dialog category.
    ///
    /// ## Examples:
    /// ```swift
    /// // Custom SF Symbol
    /// DialogContent("Success", icon: .systemImage("party.popper.fill"))
    /// 
    /// // Custom image
    /// DialogContent("Welcome", icon: .image("company-logo"))
    /// 
    /// // Custom view
    /// DialogContent("Loading", icon: .view(AnyView(ProgressView())))
    /// 
    /// // No icon (override semantic default)
    /// DialogContent("Clean message", icon: .none)
    /// ```
    public let icon: ToastIcon?
    
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
    
    /// Whether this content uses a custom view instead of standard layout.
    public var hasCustomView: Bool {
        customView != nil
    }
    
    /// Whether this content has an icon specified.
    public var hasIcon: Bool {
        icon != nil
    }
    
    /// A combined text representation of title and message.
    ///
    /// For custom view content, returns a placeholder description.
    /// For standard content, combines title and message with newline separation.
    public var fullText: String {
        if hasCustomView {
            return "[Custom View Content]"
        }
        
        if let message = message, !message.isEmpty {
            return "\(title)\n\(message)"
        }
        return title
    }
    
    // MARK: - Initializers
    /// Creates dialog content with a title only.
    ///
    /// - Parameter title: The title of the dialog.
    public init(_ title: String) {
        self.title = title
        self.message = nil
        self.actions = []
        self.customView = nil
        self.icon = nil
    }
    
    /// Creates dialog content with a title and message.
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - message: An optional message for additional details.
    public init(_ title: String, message: String?) {
        self.title = title
        self.message = message
        self.actions = []
        self.customView = nil
        self.icon = nil
    }
    
    /// Creates dialog content with a title, message, and custom icon.
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - message: An optional message for additional details.
    ///   - icon: A custom icon to display with the dialog.
    public init(_ title: String, message: String? = nil, icon: ToastIcon) {
        self.title = title
        self.message = message
        self.actions = []
        self.customView = nil
        self.icon = icon
    }
    
    /// Creates dialog content with a title and actions.
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - actions: A closure that builds the dialog actions using `DialogActionsBuilder`.
    public init(
        _ title: String,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) {
        self.title = title
        self.message = nil
        self.actions = actions()
        self.customView = nil
        self.icon = nil
    }
    
    /// Creates dialog content with a title, message, and actions.
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - message: An optional message for additional details.
    ///   - actions: A closure that builds the dialog actions using `DialogActionsBuilder`.
    public init(
        _ title: String,
        message: String?,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) {
        self.title = title
        self.message = message
        self.actions = actions()
        self.customView = nil
        self.icon = nil
    }
    
    /// Creates dialog content with a title, message, icon, and actions.
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - message: An optional message for additional details.
    ///   - icon: A custom icon to display with the dialog.
    ///   - actions: A closure that builds the dialog actions using `DialogActionsBuilder`.
    public init(
        _ title: String,
        message: String? = nil,
        icon: ToastIcon,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) {
        self.title = title
        self.message = message
        self.actions = actions()
        self.customView = nil
        self.icon = icon
    }
    
    /// Creates dialog content with explicit parameters.
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - message: An optional message for additional details.
    ///   - actions: An array of dialog actions.
    public init(
        title: String,
        message: String? = nil,
        icon: ToastIcon? = nil,
        actions: [any DialogAction] = [],
        customView: AnyView? = nil
    ) {
        self.title = title
        self.message = message
        self.actions = actions
        self.customView = customView
        self.icon = icon
    }
    
    /// Creates dialog content with a custom SwiftUI view.
    ///
    /// This initializer is specifically designed for rich toast dialogs
    /// that need custom layouts, animations, or branding that can't be achieved
    /// with the standard title/message/button layout.
    ///
    /// - Parameter customView: The custom SwiftUI view to display.
    ///
    /// ## Example:
    /// ```swift
    /// let content = DialogContent(customView: AnyView(
    ///     HStack {
    ///         ProgressView()
    ///             .progressViewStyle(CircularProgressViewStyle(tint: .white))
    ///         VStack(alignment: .leading) {
    ///             Text("Uploading File")
    ///                 .font(.headline)
    ///                 .foregroundColor(.white)
    ///             Text("Please wait...")
    ///                 .font(.caption)
    ///                 .foregroundColor(.white.opacity(0.8))
    ///         }
    ///     }
    ///     .padding()
    ///     .background(Color.blue)
    ///     .cornerRadius(12)
    /// ))
    /// ```
    public init(customView: AnyView) {
        self.title = ""
        self.message = nil
        self.actions = []
        self.customView = customView
        self.icon = nil
    }
    
    /// Creates dialog content with a custom SwiftUI view using a view builder.
    ///
    /// Convenience initializer that automatically wraps the provided view in `AnyView`,
    /// making it easier to create custom content without explicit type erasure.
    ///
    /// - Parameter content: A closure that returns the custom SwiftUI view.
    ///
    /// ## Example:
    /// ```swift
    /// let content = DialogContent {
    ///     VStack {
    ///         Image(systemName: "checkmark.circle.fill")
    ///             .font(.largeTitle)
    ///             .foregroundColor(.green)
    ///         Text("Success!")
    ///             .font(.headline)
    ///     }
    ///     .padding()
    /// }
    /// ```
    public init<Content: View>(@ViewBuilder content: () -> Content) {
        self.title = ""
        self.message = nil
        self.actions = []
        self.customView = AnyView(content())
        self.icon = nil
    }
    
    // MARK: - Equatable Implementation
    /// Compares two `DialogContent` instances for equality.
    ///
    /// Note: Actions are compared by their hash values since they may contain closures
    /// that cannot be directly compared.
    public static func == (lhs: DialogContent, rhs: DialogContent) -> Bool {
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

// MARK: - Content Transformation
public extension DialogContent {
    /// Creates a copy of this content with modified actions.
    ///
    /// - Parameter actions: A closure that builds new actions.
    /// - Returns: A new `DialogContent` with the updated actions.
    func withActions(@DialogActionsBuilder actions: () -> [any DialogAction]) -> DialogContent {
        DialogContent(
            title: title,
            message: message,
            actions: actions(),
            customView: customView
        )
    }
    
    /// Creates a copy of this content with a modified message.
    ///
    /// - Parameter message: The new message.
    /// - Returns: A new `DialogContent` with the updated message.
    func withMessage(_ message: String?) -> DialogContent {
        DialogContent(
            title: title,
            message: message,
            actions: actions,
            customView: customView
        )
    }
    
    /// Creates a copy of this content with a modified title.
    ///
    /// - Parameter title: The new title.
    /// - Returns: A new `DialogContent` with the updated title.
    func withTitle(_ title: String) -> DialogContent {
        DialogContent(
            title: title,
            message: message,
            actions: actions,
            customView: customView
        )
    }
    
    /// Creates a copy of this content with a custom view.
    ///
    /// - Parameter customView: The custom view to add.
    /// - Returns: A new `DialogContent` with the custom view.
    func withCustomView(_ customView: AnyView) -> DialogContent {
        DialogContent(
            title: title,
            message: message,
            actions: actions,
            customView: customView
        )
    }
    
    /// Creates a copy of this content with a custom view using a view builder.
    ///
    /// - Parameter content: A closure that builds the custom view.
    /// - Returns: A new `DialogContent` with the custom view.
    func withCustomView<Content: View>(@ViewBuilder content: () -> Content) -> DialogContent {
        withCustomView(AnyView(content()))
    }
    
    /// Creates a copy of this content with a different icon.
    ///
    /// - Parameter icon: The new icon to use.
    /// - Returns: A new `DialogContent` with the updated icon.
    func withIcon(_ icon: ToastIcon?) -> DialogContent {
        DialogContent(
            title: title,
            message: message,
            icon: icon,
            actions: actions,
            customView: customView
        )
    }
}

// MARK: - Hashable Support
extension DialogContent: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(message)
        hasher.combine(actions.count)
        hasher.combine(hasCustomView)
        hasher.combine(icon)
        
        // Hash the types and hash values of actions
        for action in actions {
            hasher.combine(String(describing: type(of: action)))
            hasher.combine(action.hashValue)
        }
    }
}

extension DialogContent {
    /// Extracts buttons with specific roles for confirmation dialog presentation.
    ///
    /// Confirmation dialogs handle cancel buttons separately from other actions,
    /// so there is a need to identify and group them properly.
    func buttonsByRole() -> (cancel: DialogButton?, destructive: [DialogButton], regular: [DialogButton]) {
        let buttons = actions.compactMap { $0 as? DialogButton }
        
        // iOS only supports one cancel button in confirmation dialogs
        let cancelButton = buttons.first { $0.role == .cancel }
        
        // Separate destructive and regular actions
        let destructiveButtons = buttons.filter { $0.role == .destructive }
        let regularButtons = buttons.filter { $0.role == nil && $0 != cancelButton }
        
        return (cancelButton, destructiveButtons, regularButtons)
    }
    
    /// Whether this content is suitable for confirmation dialog presentation.
    var isValidForConfirmationDialog: Bool {
        // Must have at least one action
        guard hasActions else { return false }
        
        // Cannot have text fields
        let hasTextFields = actions.contains { $0 is DialogTextField }
        return !hasTextFields
    }
}
