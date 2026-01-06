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
    /// Creates dialog content with a title only (plain value).
    ///
    /// Use this overload when passing a literal or plain String expression for the title.
    /// For a computed title, use the closure-based overload.
    /// - Parameter title: The dialog title evaluated via @autoclosure.
    public init(title: @autoclosure @escaping @Sendable () -> String) where Icon == EmptyView, CustomContent == EmptyView {
        self.init(title: title)
    }
    
    /// Creates dialog content with a title only (closure-based).
    ///
    /// Use this overload when the title should be computed lazily at presentation time.
    /// - Parameter title: A closure that returns the dialog title.
    public init(title: @escaping @Sendable () -> String) where Icon == EmptyView, CustomContent == EmptyView {
        self.init(
            title: title,
            message: { nil },
            actions: [],
            iconBuilder: nil,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title and message (plain values).
    ///
    /// Use this overload when passing literal/plain values. For computed values,
    /// use one of the closure-based overloads.
    /// - Parameters:
    ///   - title: The dialog title evaluated via @autoclosure.
    ///   - message: The optional dialog message evaluated via @autoclosure.
    public init(title: @autoclosure @escaping @Sendable () -> String, message: @autoclosure @escaping @Sendable () -> String?) where Icon == EmptyView, CustomContent == EmptyView {
        self.init(title: title, message: message)
    }
    
    /// Creates dialog content with a title (closure-based) and message (plain value).
    ///
    /// - Parameters:
    ///   - title: A closure that returns the dialog title.
    ///   - message: The optional dialog message evaluated via @autoclosure.
    public init(title: @escaping @Sendable () -> String, message: @autoclosure @escaping @Sendable () -> String?) where Icon == EmptyView, CustomContent == EmptyView {
        self.init(
            title: title,
            message: message,
            actions: [],
            iconBuilder: nil,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (plain value) and message (closure-based).
    ///
    /// - Parameters:
    ///   - title: The dialog title evaluated via @autoclosure.
    ///   - message: A closure that returns the optional dialog message.
    public init(title: @autoclosure @escaping @Sendable () -> String, message: @escaping @Sendable () -> String?) where Icon == EmptyView, CustomContent == EmptyView {
        self.init(
            title: title,
            message: message,
            actions: [],
            iconBuilder: nil,
            customContentBuilder: nil
        )
    }

    /// Creates dialog content with a title and message (both closure-based).
    ///
    /// - Parameters:
    ///   - title: A closure that returns the dialog title.
    ///   - message: A closure that returns the optional dialog message.
    public init(title: @escaping @Sendable () -> String, message: @escaping @Sendable () -> String?) where Icon == EmptyView, CustomContent == EmptyView {
        self.init(
            title: title,
            message: message,
            actions: [],
            iconBuilder: nil,
            customContentBuilder: nil
        )
    }

    /// Creates dialog content with just a message (plain value).
    ///
    /// The title is empty by default.
    /// - Parameter message: The dialog message evaluated via @autoclosure.
    public init(_ message: @autoclosure @escaping @Sendable () -> String) where Icon == EmptyView, CustomContent == EmptyView {
        self.init(
            title: { "" },
            message: message,
            actions: [],
            iconBuilder: nil,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with just a message (closure-based).
    ///
    /// The title is empty by default.
    /// - Parameter message: A closure that returns the dialog message.
    public init(_ message: @escaping @Sendable () -> String) where Icon == EmptyView, CustomContent == EmptyView {
        self.init(
            title: { "" },
            message: message,
            actions: [],
            iconBuilder: nil,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a message (plain value) and actions.
    ///
    /// The title is empty by default.
    /// - Parameters:
    ///   - message: The dialog message evaluated via @autoclosure.
    ///   - actions: A builder that produces dialog actions.
    public init(_ message: @autoclosure @escaping @Sendable () -> String, @DialogActionsBuilder actions: () -> [any DialogAction]) where Icon == EmptyView, CustomContent == EmptyView {
        self.init(
            title: { "" },
            message: message,
            actions: actions(),
            iconBuilder: nil,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a message (closure-based) and actions.
    ///
    /// The title is empty by default.
    /// - Parameters:
    ///   - message: A closure that returns the dialog message.
    ///   - actions: A builder that produces dialog actions.
    public init(_ message: @escaping @Sendable () -> String, @DialogActionsBuilder actions: () -> [any DialogAction]) where Icon == EmptyView, CustomContent == EmptyView {
        self.init(
            title: { "" },
            message: message,
            actions: actions(),
            iconBuilder: nil,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (plain value) and a custom icon.
    ///
    /// - Parameters:
    ///   - title: The dialog title evaluated via @autoclosure.
    ///   - icon: A view builder that produces the icon view.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        @ViewBuilder icon: @Sendable @escaping () -> Icon
    ) where CustomContent == EmptyView {
        self.init(
            title: title,
            message: { nil },
            actions: [],
            iconBuilder: icon,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (closure-based) and a custom icon.
    ///
    /// - Parameters:
    ///   - title: A closure that returns the dialog title.
    ///   - icon: A view builder that produces the icon view.
    public init(
        title: @escaping @Sendable () -> String,
        @ViewBuilder icon: @Sendable @escaping () -> Icon
    ) where CustomContent == EmptyView {
        self.init(
            title: title,
            message: { nil },
            actions: [],
            iconBuilder: icon,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (plain value), message (plain value) and custom icon.
    ///
    /// - Parameters:
    ///   - title: The dialog title evaluated via @autoclosure.
    ///   - message: The optional dialog message evaluated via @autoclosure.
    ///   - icon: A view builder that produces the icon view.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        message: @autoclosure @escaping @Sendable () -> String?,
        @ViewBuilder icon: @Sendable @escaping () -> Icon
    ) where CustomContent == EmptyView {
        self.init(
            title: title,
            message: message,
            actions: [],
            iconBuilder: icon,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (closure-based), message (plain value) and custom icon.
    ///
    /// - Parameters:
    ///   - title: A closure that returns the dialog title.
    ///   - message: The optional dialog message evaluated via @autoclosure.
    ///   - icon: A view builder that produces the icon view.
    public init(
        title: @escaping @Sendable () -> String,
        message: @autoclosure @escaping @Sendable () -> String?,
        @ViewBuilder icon: @Sendable @escaping () -> Icon
    ) where CustomContent == EmptyView {
        self.init(
            title: title,
            message: message,
            actions: [],
            iconBuilder: icon,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (plain value), message (closure-based) and custom icon.
    ///
    /// - Parameters:
    ///   - title: The dialog title evaluated via @autoclosure.
    ///   - message: A closure that returns the optional dialog message.
    ///   - icon: A view builder that produces the icon view.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        message: @escaping @Sendable () -> String?,
        @ViewBuilder icon: @Sendable @escaping () -> Icon
    ) where CustomContent == EmptyView {
        self.init(
            title: title,
            message: message,
            actions: [],
            iconBuilder: icon,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title and message (both closure-based) and a custom icon.
    ///
    /// - Parameters:
    ///   - title: A closure that returns the dialog title.
    ///   - message: A closure that returns the optional dialog message.
    ///   - icon: A view builder that produces the icon view.
    public init(
        title: @escaping @Sendable () -> String,
        message: @escaping @Sendable () -> String?,
        @ViewBuilder icon: @Sendable @escaping () -> Icon
    ) where CustomContent == EmptyView {
        self.init(
            title: title,
            message: message,
            actions: [],
            iconBuilder: icon,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (plain value) and actions.
    ///
    /// - Parameters:
    ///   - title: The dialog title evaluated via @autoclosure.
    ///   - actions: A builder that produces dialog actions.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where Icon == EmptyView, CustomContent == EmptyView {
        self.init(
            title: title,
            message: { nil },
            actions: actions(),
            iconBuilder: nil,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (closure-based) and actions.
    ///
    /// - Parameters:
    ///   - title: A closure that returns the dialog title.
    ///   - actions: A builder that produces dialog actions.
    public init(
        title: @escaping @Sendable () -> String,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where Icon == EmptyView, CustomContent == EmptyView {
        self.init(
            title: title,
            message: { nil },
            actions: actions(),
            iconBuilder: nil,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (plain value), message (plain value), and actions.
    ///
    /// - Parameters:
    ///   - title: The dialog title evaluated via @autoclosure.
    ///   - message: The optional dialog message evaluated via @autoclosure.
    ///   - actions: A builder that produces dialog actions.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        message: @autoclosure @escaping @Sendable () -> String?,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where Icon == EmptyView, CustomContent == EmptyView {
        self.init(
            title: title,
            message: message,
            actions: actions(),
            iconBuilder: nil,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (plain value), message (closure-based), and actions.
    ///
    /// - Parameters:
    ///   - title: The dialog title evaluated via @autoclosure.
    ///   - message: A closure that returns the optional dialog message.
    ///   - actions: A builder that produces dialog actions.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        message: @escaping @Sendable () -> String?,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where Icon == EmptyView, CustomContent == EmptyView {
        self.init(
            title: title,
            message: message,
            actions: actions(),
            iconBuilder: nil,
            customContentBuilder: nil
        )
    }

    /// Creates dialog content with a title and message (both closure-based), and actions.
    ///
    /// - Parameters:
    ///   - title: A closure that returns the dialog title.
    ///   - message: A closure that returns the optional dialog message.
    ///   - actions: A builder that produces dialog actions.
    public init(
        title: @escaping @Sendable () -> String,
        message: @escaping @Sendable () -> String?,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where Icon == EmptyView, CustomContent == EmptyView {
        self.init(
            title: title,
            message: message,
            actions: actions(),
            iconBuilder: nil,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (plain value), custom icon, and actions.
    ///
    /// - Parameters:
    ///   - title: The dialog title evaluated via @autoclosure.
    ///   - icon: A view builder that produces the icon view.
    ///   - actions: A builder that produces dialog actions.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        @ViewBuilder icon: @Sendable @escaping () -> Icon,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where CustomContent == EmptyView {
        self.init(
            title: title,
            message: { nil },
            actions: actions(),
            iconBuilder: icon,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (closure-based), custom icon, and actions.
    ///
    /// - Parameters:
    ///   - title: A closure that returns the dialog title.
    ///   - icon: A view builder that produces the icon view.
    ///   - actions: A builder that produces dialog actions.
    public init(
        title: @escaping @Sendable () -> String,
        @ViewBuilder icon: @Sendable @escaping () -> Icon,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where CustomContent == EmptyView {
        self.init(
            title: title,
            message: { nil },
            actions: actions(),
            iconBuilder: icon,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (plain value), message (plain value), custom icon, and actions.
    ///
    /// - Parameters:
    ///   - title: The dialog title evaluated via @autoclosure.
    ///   - message: The optional dialog message evaluated via @autoclosure.
    ///   - icon: A view builder that produces the icon view.
    ///   - actions: A builder that produces dialog actions.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        message: @autoclosure @escaping @Sendable () -> String?,
        @ViewBuilder icon: @Sendable @escaping () -> Icon,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where CustomContent == EmptyView {
        self.init(
            title: title,
            message: message,
            actions: actions(),
            iconBuilder: icon,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (closure-based), message (plain value), custom icon, and actions.
    ///
    /// - Parameters:
    ///   - title: A closure that returns the dialog title.
    ///   - message: The optional dialog message evaluated via @autoclosure.
    ///   - icon: A view builder that produces the icon view.
    ///   - actions: A builder that produces dialog actions.
    public init(
        title: @escaping @Sendable () -> String,
        message: @autoclosure @escaping @Sendable () -> String?,
        @ViewBuilder icon: @Sendable @escaping () -> Icon,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where CustomContent == EmptyView {
        self.init(
            title: title,
            message: message,
            actions: actions(),
            iconBuilder: icon,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (plain value), message (closure-based), custom icon, and actions.
    ///
    /// - Parameters:
    ///   - title: The dialog title evaluated via @autoclosure.
    ///   - message: A closure that returns the optional dialog message.
    ///   - icon: A view builder that produces the icon view.
    ///   - actions: A builder that produces dialog actions.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        message: @escaping @Sendable () -> String?,
        @ViewBuilder icon: @Sendable @escaping () -> Icon,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where CustomContent == EmptyView {
        self.init(
            title: title,
            message: message,
            actions: actions(),
            iconBuilder: icon,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title and message (both closure-based), custom icon, and actions.
    ///
    /// - Parameters:
    ///   - title: A closure that returns the dialog title.
    ///   - message: A closure that returns the optional dialog message.
    ///   - icon: A view builder that produces the icon view.
    ///   - actions: A builder that produces dialog actions.
    public init(
        title: @escaping @Sendable () -> String,
        message: @escaping @Sendable () -> String?,
        @ViewBuilder icon: @Sendable @escaping () -> Icon,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where CustomContent == EmptyView {
        self.init(
            title: title,
            message: message,
            actions: actions(),
            iconBuilder: icon,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (plain value), message (plain value), image icon, and actions.
    ///
    /// - Parameters:
    ///   - title: The dialog title evaluated via @autoclosure.
    ///   - message: The optional dialog message evaluated via @autoclosure.
    ///   - iconImage: An Image builder evaluated via @autoclosure.
    ///   - actions: A builder that produces dialog actions.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        message: @autoclosure @escaping @Sendable () -> String?,
        iconImage: @autoclosure @escaping @Sendable () -> Image,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where CustomContent == EmptyView, Icon == Image {
        self.init(
            title: title,
            message: message,
            actions: actions(),
            iconBuilder: iconImage,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (closure-based), message (plain value), image icon, and actions.
    ///
    /// - Parameters:
    ///   - title: A closure that returns the dialog title.
    ///   - message: The optional dialog message evaluated via @autoclosure.
    ///   - iconImage: An Image builder evaluated via @autoclosure.
    ///   - actions: A builder that produces dialog actions.
    public init(
        title: @escaping @Sendable () -> String,
        message: @autoclosure @escaping @Sendable () -> String?,
        iconImage: @autoclosure @escaping @Sendable () -> Image,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where CustomContent == EmptyView, Icon == Image {
        self.init(
            title: title,
            message: message,
            actions: actions(),
            iconBuilder: iconImage,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (plain value), image icon, and actions.
    ///
    /// - Parameters:
    ///   - title: The dialog title evaluated via @autoclosure.
    ///   - iconImage: An Image builder evaluated via @autoclosure.
    ///   - actions: A builder that produces dialog actions.
    public init(
        title: @autoclosure @escaping @Sendable () -> String,
        iconImage: @autoclosure @escaping @Sendable () -> Image,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where CustomContent == EmptyView, Icon == Image {
        self.init(
            title: title,
            message: { nil },
            actions: actions(),
            iconBuilder: iconImage,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with a title (closure-based), image icon, and actions.
    ///
    /// - Parameters:
    ///   - title: A closure that returns the dialog title.
    ///   - iconImage: An Image builder evaluated via @autoclosure.
    ///   - actions: A builder that produces dialog actions.
    public init(
        title: @escaping @Sendable () -> String,
        iconImage: @autoclosure @escaping @Sendable () -> Image,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) where CustomContent == EmptyView, Icon == Image {
        self.init(
            title: title,
            message: { nil },
            actions: actions(),
            iconBuilder: iconImage,
            customContentBuilder: nil
        )
    }
    
    /// Creates dialog content with custom SwiftUI content.
    ///
    /// When provided, the custom content replaces the standard title/message layout.
    /// The title is used primarily for accessibility.
    /// - Parameters:
    ///   - title: The dialog title evaluated via @autoclosure. Defaults to an empty string.
    ///   - customContent: A view builder that produces the custom content.
    public init(
        title: @autoclosure @escaping @Sendable () -> String = "",
        @ViewBuilder customContent: @Sendable @escaping () -> CustomContent
    ) where Icon == EmptyView {
        self.init(
            title: title,
            message: { nil },
            actions: [],
            iconBuilder: nil,
            customContentBuilder: customContent
        )
    }
    
    /// Creates dialog content with custom SwiftUI content (closure-based title).
    ///
    /// When provided, the custom content replaces the standard title/message layout.
    /// The title is used primarily for accessibility.
    /// - Parameters:
    ///   - title: A closure that returns the dialog title.
    ///   - customContent: A view builder that produces the custom content.
    public init(
        title: @escaping @Sendable () -> String,
        @ViewBuilder customContent: @Sendable @escaping () -> CustomContent
    ) where Icon == EmptyView {
        self.init(
            title: title,
            message: { nil },
            actions: [],
            iconBuilder: nil,
            customContentBuilder: customContent
        )
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

