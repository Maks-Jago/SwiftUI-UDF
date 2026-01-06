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
/// The `title` and `message` are modeled as closures to allow dynamic resolution
/// at presentation time (for example, for localization or state-dependent content).
/// Convenience initializers using `@autoclosure` are provided so you can still
/// pass plain strings ergonomically.
///
/// ## Usage:
/// ```swift
/// // Simple content with just a title
/// let content = DialogContent(title: "Delete Item")
///
/// // Content with title and message
/// let content = DialogContent(title: "Delete Item", message: "This cannot be undone")
///
/// // Content with title, message, and actions
/// let content = DialogContent(title: "Delete Item", message: "This cannot be undone") {
///     DialogButton.destructive("Delete") {
///         performDelete()
///     }
///     DialogButton.cancel("Cancel")
/// }
///
/// // Custom view content for rich toast dialogs
/// let content = DialogContent(customContent: {
///     VStack {
///         ProgressView()
///         Text("Uploading...")
///     }
/// })
/// ```
public struct DialogContent<Icon: View, CustomContent: View>: Equatable, Sendable {
    /// The title provider of the dialog content.
    public let title: @Sendable () -> String
    
    /// An optional message provider providing additional details.
    public let message: @Sendable () -> String?
    
    /// The interactive actions available for this content.
    public let actions: [any DialogAction]
    
    /// Custom SwiftUI view content builder for rich dialogs.
    ///
    /// When provided, this custom view takes precedence over the standard
    /// title/message layout. This enables complex, branded, or interactive
    /// dialog designs that can't be achieved with text and buttons alone.
    public let customContentView: (@Sendable () -> CustomContent)?
    
    /// The icon to display with this dialog content.
    ///
    /// Supports various icon types including SF Symbols, custom images, and
    /// arbitrary SwiftUI views. When nil, the dialog system will use
    /// semantic defaults based on the dialog category.
    public let iconView: (@Sendable () -> Icon)?
    
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
        if let msg = message() {
            return !msg.isEmpty
        }
        return false
    }
    
    /// Whether this content uses a custom view instead of standard layout.
    public var hasCustomView: Bool {
        customContentView != nil
    }
    
    /// Whether this content has an icon specified.
    public var hasIcon: Bool {
        iconView != nil
    }
    
    // MARK: - Initializers
    /// Creates dialog content with a title only.
    ///
    /// - Parameter title: The title of the dialog.
    public init(title: @autoclosure @escaping @Sendable () -> String) where Icon == EmptyView, CustomContent == EmptyView {
        self.title = title
        self.message = { nil }
        self.actions = []
        self.customContentView = nil
        self.iconView = nil
    }
    
    /// Creates dialog content with a title and message.
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - message: An optional message for additional details.
    public init(title: @autoclosure @escaping @Sendable () -> String, message: @autoclosure @escaping @Sendable () -> String?) where Icon == EmptyView, CustomContent == EmptyView {
        self.title = title
        self.message = message
        self.actions = []
        self.customContentView = nil
        self.iconView = nil
    }
    
    /// Creates dialog content with just a message.
    ///
    /// This is a convenience initializer for simple dialogs that only need
    /// to display a message without additional content or actions.
    ///
    /// - Parameter message: The message to display.
    public init(_ message: @autoclosure @escaping @Sendable () -> String) where Icon == EmptyView, CustomContent == EmptyView {
        self.title = { "" }
        self.message = message
        self.actions = []
        self.customContentView = nil
        self.iconView = nil
    }
    
    public init(_ message: @autoclosure @escaping @Sendable () -> String, @DialogActionsBuilder actions: () -> [any DialogAction]) where Icon == EmptyView, CustomContent == EmptyView {
        self.title = { "" }
        self.message = message
        self.actions = actions()
        self.customContentView = nil
        self.iconView = nil
    }
    
    /// Creates dialog content with a title and a custom icon.
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - icon: A custom icon to display with the dialog.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        @ViewBuilder icon: @Sendable @escaping () -> Icon
    ) where CustomContent == EmptyView {
        self.title = title
        self.message = { nil }
        self.actions = []
        self.customContentView = nil
        self.iconView = icon
    }
    
    /// Creates dialog content with a title, message and custom icon.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        message: @autoclosure @escaping @Sendable () -> String?,
        @ViewBuilder icon: @Sendable @escaping () -> Icon
    ) where CustomContent == EmptyView {
        self.title = title
        self.message = message
        self.actions = []
        self.customContentView = nil
        self.iconView = icon
    }
    
    /// Creates dialog content with a title and actions.
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - actions: A closure that builds the dialog actions using `DialogActionsBuilder`.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where Icon == EmptyView, CustomContent == EmptyView {
        self.title = title
        self.message = { nil }
        self.actions = actions()
        self.customContentView = nil
        self.iconView = nil
    }
    
    /// Creates dialog content with a title, message, and actions.
    ///
    /// - Parameters:
    ///   - title: The title of the dialog.
    ///   - message: An optional message for additional details.
    ///   - actions: A closure that builds the dialog actions using `DialogActionsBuilder`.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        message: @autoclosure @escaping @Sendable () -> String?,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where Icon == EmptyView, CustomContent == EmptyView {
        self.title = title
        self.message = message
        self.actions = actions()
        self.customContentView = nil
        self.iconView = nil
    }
    
    /// Creates dialog content with a title, custom icon, and actions.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        @ViewBuilder icon: @Sendable @escaping () -> Icon,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where CustomContent == EmptyView {
        self.title = title
        self.message = { nil }
        self.actions = actions()
        self.customContentView = nil
        self.iconView = icon
    }
    
    /// Creates dialog content with a title, message, icon, and actions.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        message: @autoclosure @escaping @Sendable () -> String?,
        @ViewBuilder icon: @Sendable @escaping () -> Icon,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where CustomContent == EmptyView {
        self.title = title
        self.message = message
        self.actions = actions()
        self.customContentView = nil
        self.iconView = icon
    }
    
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        message: @autoclosure @escaping @Sendable () -> String?,
        iconImage: @autoclosure @escaping @Sendable () -> Image,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where CustomContent == EmptyView, Icon == Image {
        self.title = title
        self.message = message
        self.actions = actions()
        self.customContentView = nil
        self.iconView = iconImage
    }
    
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        iconImage: @autoclosure @escaping @Sendable () -> Image,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where CustomContent == EmptyView, Icon == Image {
        self.title = title
        self.message = { nil }
        self.actions = actions()
        self.customContentView = nil
        self.iconView = iconImage
    }
    
    /// Creates dialog content with custom view using generic type.
    ///
    /// - Parameters:
    ///   - title: Optional title for accessibility
    ///   - customContent: A view builder that creates the custom content
    /// - Returns: DialogContent with generic custom view type
    public init(
        title: @autoclosure @escaping @Sendable () -> String = "",
        @ViewBuilder customContent: @Sendable @escaping () -> CustomContent
    ) where Icon == EmptyView {
        self.title = title
        self.message = { nil }
        self.actions = []
        self.customContentView = customContent
        self.iconView = nil
    }
    
    // MARK: - Internal Initializers for Type Erasure
    
    /// Internal initializer for type erasure - handles all combinations with optional builders.
    ///
    /// This initializer is designed specifically for the `eraseToAnyDialogContent()` method
    /// and handles all possible combinations of icon and custom content.
    internal init(
        title: @Sendable @escaping () -> String,
        message: @Sendable @escaping () -> String? = { nil },
        actions: [any DialogAction] = [],
        iconBuilder: (@Sendable () -> Icon)? = nil,
        customContentBuilder: (@Sendable () -> CustomContent)? = nil
    ) {
        self.title = title
        self.message = message
        self.actions = actions
        self.iconView = iconBuilder
        self.customContentView = customContentBuilder
    }
    
    // MARK: - Equatable Implementation
    /// Compares two `DialogContent` instances for equality.
    ///
    /// Note: Actions are compared by their hash values since they may contain closures
    /// that cannot be directly compared.
    public static func == (lhs: DialogContent, rhs: DialogContent) -> Bool {
        lhs.title() == rhs.title() &&
        lhs.message() == rhs.message() &&
        lhs.actions.count == rhs.actions.count &&
        zip(lhs.actions, rhs.actions).allSatisfy { lhsAction, rhsAction in
            // Compare actions by their hash values
            lhsAction.hashValue == rhsAction.hashValue
        }
    }
}

// MARK: - Hashable Support
extension DialogContent: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(title())
        hasher.combine(message())
        hasher.combine(actions.count)
        hasher.combine(hasCustomView)
        hasher.combine(hasIcon)
        
        // Hash the types and hash values of actions
        for action in actions {
            hasher.combine(String(describing: type(of: action)))
            hasher.combine(action.hashValue)
        }
    }
}

extension DialogContent {
    /// Whether this content is suitable for confirmation dialog presentation.
    var isValidForConfirmationDialog: Bool {
        // Must have at least one action
        guard hasActions else { return false }
        
        // Cannot have text fields
        let hasTextFields = actions.contains { $0 is DialogTextField }
        return !hasTextFields
    }
    
    /// Returns the icon as an AnyView for type-erased access.
    /// This allows ToastView to access the icon regardless of the generic type.
    func renderIcon() -> AnyView? {
        guard let iconView = iconView else { return nil }
        return AnyView(iconView())
    }
}
