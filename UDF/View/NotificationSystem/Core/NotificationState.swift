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
    
    // MARK: - Initializers
    
    /// Initializes a notification state with an error message.
    /// 
    /// - Parameter error: The error message to display. If nil or empty, creates a dismissed state.
    public init(error: String?) {
        if let error, !error.isEmpty {
            self = .init(notification: .error(error, style: .alert))
        } else {
            self = .init()
        }
    }
    
    /// Initializes a notification state with a success message.
    /// 
    /// - Parameter success: The success message to display. If nil or empty, creates a dismissed state.
    public init(success: String?) {
        if let success, !success.isEmpty {
            self = .init(notification: .success(success, style: .alert))
        } else {
            self = .init()
        }
    }
    
    /// Initializes a notification state with a warning message.
    /// 
    /// - Parameter warning: The warning message to display. If nil or empty, creates a dismissed state.
    public init(warning: String?) {
        if let warning, !warning.isEmpty {
            self = .init(notification: .warning(warning, style: .alert))
        } else {
            self = .init()
        }
    }
    
    /// Initializes a notification state with an info message.
    /// 
    /// - Parameter info: The info message to display. If nil or empty, creates a dismissed state.
    public init(info: String?) {
        if let info, !info.isEmpty {
            self = .init(notification: .info(info, style: .alert))
        } else {
            self = .init()
        }
    }
    
    /// Initializes a notification state with a title and an optional message.
    /// 
    /// - Parameters:
    ///   - title: The title of the notification.
    ///   - message: An optional message for the notification.
    public init(title: String, message: String?) {
        let content = NotificationContent(title, message: message)
        self = .init(notification: .custom(content: content, style: .alert))
    }
    
    /// Initializes a notification state with custom content using a result builder.
    /// 
    /// - Parameters:
    ///   - style: The notification style (defaults to .alert).
    ///   - content: A closure that returns NotificationContent with actions.
    public init(
        style: NotificationStyle = .alert,
        @NotificationContentBuilder content: () -> NotificationContent
    ) {
        self = .init(notification: .custom(content: content(), style: style))
    }
    
    /// Initializes a notification state using a registered notification identified by a unique ID.
    /// 
    /// - Parameter id: The identifier of the registered notification.
    public init(id: some Hashable) {
        if let notification = NotificationRegistry.get(id: id) {
            self = .init(notification: notification)
        } else {
            self = .dismissed
        }
    }
    
    /// Initializes a notification state with a specific notification type.
    /// 
    /// - Parameter notification: The notification type to present.
    public init(notification: NotificationType) {
        self.id = UUID()
        self.status = .presented(notification)
    }
    
    /// Initializes a dismissed notification state.
    public init() {
        self.id = UUID()
        self.status = .dismissed
    }
    
    /// Private initializer for creating the standard dismissed state with a fixed UUID.
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
