//===--- NotificationState.swift ---------------------------------===//
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

/// A state manager for notifications, replacing AlertBuilder.AlertStatus.
///
/// `NotificationState` provides the main interface for managing notification presentation
/// and dismissal across the application. It handles both simple message notifications
/// and complex notifications with custom content and actions.
///
/// ## Usage:
/// ```swift
/// @State private var notification = NotificationState.dismissed
/// 
/// // Simple error notification
/// notification = .init(error: "Something went wrong")
/// 
/// // Complex notification with actions
/// notification = .init(style: .alert) {
///     NotificationContent("Delete Item", message: "This cannot be undone") {
///         NotificationButton.destructive("Delete") { /* action */ }
///         NotificationButton.cancel("Cancel")
///     }
/// }
/// ```
public struct NotificationState: Equatable, Identifiable, Sendable {
    /// Returns a dismissed notification state.
    public static var dismissed: Self { 
        .init(dismissedUUID: "32DA8B0A-5C48-4FBC-8464-E80AD89AE16D") 
    }
    
    /// Unique identifier for this notification state.
    public let id: UUID
    
    /// Current status of the notification.
    public var status: Status
    
    /// Enum representing the status of a notification, either presented or dismissed.
    public enum Status: Equatable, Sendable {
        case presented(NotificationType)
        case dismissed
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case let (.presented(lhsType), .presented(rhsType)):
                return lhsType == rhsType
            case (.dismissed, .dismissed):
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Equatable Implementation
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status
    }
    
    // MARK: - Basic Initializers
    
    /// Initializes a notification state with an error message.
    /// 
    /// Creates an error notification using the specified message and presentation style.
    /// If the message is nil or empty, creates a dismissed state instead.
    ///
    /// - Parameters:
    ///   - error: The error message to display. If nil or empty, creates a dismissed state.
    ///   - style: The notification style for presentation. Defaults to `.alert`.
    ///
    /// ## Example:
    /// ```swift
    /// // Alert-style error
    /// notification = .init(error: "Network connection failed")
    /// 
    /// // Toast-style error
    /// notification = .init(error: "Upload failed", style: .toast())
    /// ```
    public init(error: String?, style: NotificationStyle = .alert) {
        if let error, !error.isEmpty {
            self = .init(notification: .error(error, style: style))
        } else {
            self = .init()
        }
    }
    
    /// Initializes a notification state with a success message.
    /// 
    /// Creates a success notification using the specified message and presentation style.
    /// If the message is nil or empty, creates a dismissed state instead.
    ///
    /// - Parameters:
    ///   - success: The success message to display. If nil or empty, creates a dismissed state.
    ///   - style: The notification style for presentation. Defaults to `.alert`.
    ///
    /// ## Example:
    /// ```swift
    /// // Alert-style success
    /// notification = .init(success: "File saved successfully")
    /// 
    /// // Toast-style success
    /// notification = .init(success: "Done!", style: .toast(.bottom))
    /// ```
    public init(success: String?, style: NotificationStyle = .alert) {
        if let success, !success.isEmpty {
            self = .init(notification: .success(success, style: style))
        } else {
            self = .init()
        }
    }
    
    /// Initializes a notification state with a warning message.
    /// 
    /// Creates a warning notification using the specified message and presentation style.
    /// If the message is nil or empty, creates a dismissed state instead.
    ///
    /// - Parameters:
    ///   - warning: The warning message to display. If nil or empty, creates a dismissed state.
    ///   - style: The notification style for presentation. Defaults to `.alert`.
    ///
    /// ## Example:
    /// ```swift
    /// // Alert-style warning
    /// notification = .init(warning: "Storage space is low")
    /// 
    /// // Toast-style warning
    /// notification = .init(warning: "Unsaved changes", style: .toast(.vibrant))
    /// ```
    public init(warning: String?, style: NotificationStyle = .alert) {
        if let warning, !warning.isEmpty {
            self = .init(notification: .warning(warning, style: style))
        } else {
            self = .init()
        }
    }
    
    /// Initializes a notification state with an info message.
    /// 
    /// Creates an informational notification using the specified message and presentation style.
    /// If the message is nil or empty, creates a dismissed state instead.
    ///
    /// - Parameters:
    ///   - info: The info message to display. If nil or empty, creates a dismissed state.
    ///   - style: The notification style for presentation. Defaults to `.alert`.
    ///
    /// ## Example:
    /// ```swift
    /// // Alert-style info
    /// notification = .init(info: "New features available")
    /// 
    /// // Toast-style info
    /// notification = .init(info: "3 new messages", style: .toast(.subtle))
    /// ```
    public init(info: String?, style: NotificationStyle = .alert) {
        if let info, !info.isEmpty {
            self = .init(notification: .info(info, style: style))
        } else {
            self = .init()
        }
    }
    
    // MARK: - Advanced Initializers
    
    /// Initializes a notification state with a title and an optional message.
    /// 
    /// Creates a custom notification with the specified title and message using the
    /// provided presentation style. This is useful for notifications that need more
    /// structure than simple message strings.
    ///
    /// - Parameters:
    ///   - title: The title of the notification.
    ///   - message: An optional message providing additional details.
    ///   - style: The notification style for presentation. Defaults to `.alert`.
    ///
    /// ## Example:
    /// ```swift
    /// notification = .init(
    ///     title: "Download Complete", 
    ///     message: "Your file has been saved to Downloads",
    ///     style: .toast(.bottom)
    /// )
    /// ```
    public init(title: String, message: String? = nil, style: NotificationStyle = .alert) {
        let content = NotificationContent(title, message: message)
        self = .init(notification: .custom(content: content, style: style))
    }
    
    /// Initializes a notification state with custom content using a result builder.
    /// 
    /// Creates a notification with complex content including actions, using the
    /// `NotificationContentBuilder` for a declarative API. This enables rich
    /// notifications with buttons and other interactive elements.
    ///
    /// - Parameters:
    ///   - style: The notification style for presentation. Defaults to `.alert`.
    ///   - content: A closure that returns `NotificationContent` with actions.
    ///
    /// ## Example:
    /// ```swift
    /// notification = .init(style: .alert) {
    ///     NotificationContent("Delete Item", message: "This cannot be undone") {
    ///         NotificationButton.destructive("Delete") { performDelete() }
    ///         NotificationButton.cancel("Cancel")
    ///     }
    /// }
    /// ```
    public init(
        style: NotificationStyle = .alert,
        @NotificationContentBuilder content: () -> NotificationContent
    ) {
        self = .init(notification: .custom(content: content(), style: style))
    }
    
    /// Initializes a notification state using a registered notification identified by a unique ID.
    /// 
    /// Looks up a pre-registered notification by its identifier and creates a state
    /// for presentation. If no notification is registered for the given ID, creates
    /// a dismissed state instead.
    ///
    /// - Parameter id: The identifier of the registered notification.
    ///
    /// ## Example:
    /// ```swift
    /// // First, register a notification
    /// NotificationRegistry.register(id: "networkError") {
    ///     .error("No internet connection", style: .toast(.center))
    /// }
    /// 
    /// // Later, use the registered notification
    /// notification = .init(id: "networkError")
    /// ```
    public init(id: some Hashable) {
        if let notification = NotificationRegistry.get(id: id) {
            self = .init(notification: notification)
        } else {
            self = .dismissed
        }
    }
    
    /// Initializes a notification state with a specific notification type.
    /// 
    /// Creates a notification state for presenting the specified notification type.
    /// This is the most direct way to create notifications with full control over
    /// content and presentation style.
    ///
    /// - Parameter notification: The notification type to present.
    ///
    /// ## Example:
    /// ```swift
    /// let notificationType = NotificationType.success("Done!", style: .toast(.vibrant))
    /// notification = .init(notification: notificationType)
    /// ```
    public init(notification: NotificationType) {
        self.id = UUID()
        self.status = .presented(notification)
    }
    
    /// Initializes a dismissed notification state.
    ///
    /// Creates a notification state that represents no active notification.
    /// This is equivalent to using the static `.dismissed` property.
    ///
    /// ## Example:
    /// ```swift
    /// let notification = NotificationState() // Dismissed state
    /// ```
    public init() {
        self.id = UUID()
        self.status = .dismissed
    }
    
    /// Private initializer for creating the standard dismissed state with a fixed UUID.
    ///
    /// This initializer is used internally to create the static `.dismissed` property
    /// with a consistent identifier for testing and debugging purposes.
    private init(dismissedUUID: String) {
        self.id = UUID(uuidString: dismissedUUID)!
        self.status = .dismissed
    }
}

// MARK: - NotificationContentBuilder

/// A result builder for creating NotificationContent in a declarative way.
@resultBuilder
public enum NotificationContentBuilder {
    public static func buildBlock(_ content: NotificationContent) -> NotificationContent {
        content
    }
}
