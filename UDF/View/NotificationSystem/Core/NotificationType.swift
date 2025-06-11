//===--- NotificationType.swift ----------------------------------===//
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

/// Defines the type and content of a notification.
///
/// `NotificationType` represents different categories of notifications with their
/// associated content and presentation style. Each type carries semantic meaning
/// and can be styled differently based on the notification style.
///
/// ## Usage:
/// ```swift
/// // Simple message notifications
/// let successNotification = NotificationType.success("File saved!", style: .alert)
/// let errorNotification = NotificationType.error("Upload failed", style: .alert)
/// 
/// // Complex notification with custom content
/// let customNotification = NotificationType.custom(
///     content: NotificationContent("Title", message: "Message") {
///         NotificationButton.default("OK")
///     },
///     style: .alert
/// )
/// ```
public enum NotificationType: Equatable, Sendable {
    /// A success notification with a message.
    case success(String, style: NotificationStyle)
    
    /// An error notification with a message.
    case error(String, style: NotificationStyle)
    
    /// A warning notification with a message.
    case warning(String, style: NotificationStyle)
    
    /// An informational notification with a message.
    case info(String, style: NotificationStyle)
    
    /// A custom notification with complex content and actions.
    case custom(content: NotificationContent, style: NotificationStyle)
    
    // MARK: - Computed Properties
    
    /// The notification style associated with this type.
    public var style: NotificationStyle {
        switch self {
        case .success(_, let style),
                .error(_, let style),
                .warning(_, let style),
                .info(_, let style),
                .custom(_, let style):
            return style
        }
    }
    
    /// The primary message for simple notification types.
    /// Returns nil for custom notifications.
    public var message: String? {
        switch self {
        case .success(let message, _),
                .error(let message, _),
                .warning(let message, _),
                .info(let message, _):
            return message
        case .custom:
            return nil
        }
    }
    
    /// The content for custom notifications.
    /// Returns nil for simple message notifications.
    public var content: NotificationContent? {
        switch self {
        case .custom(let content, _):
            return content
        case .success, .error, .warning, .info:
            return nil
        }
    }
    
    /// The semantic category of this notification.
    public var category: NotificationCategory {
        switch self {
        case .success:
            return .success
        case .error:
            return .error
        case .warning:
            return .warning
        case .info:
            return .info
        case .custom:
            return .custom
        }
    }
    
    // MARK: - Equatable Implementation
    
    public static func == (lhs: NotificationType, rhs: NotificationType) -> Bool {
        switch (lhs, rhs) {
        case let (.success(lhsMessage, lhsStyle), .success(rhsMessage, rhsStyle)):
            return lhsMessage == rhsMessage && lhsStyle == rhsStyle
            
        case let (.error(lhsMessage, lhsStyle), .error(rhsMessage, rhsStyle)):
            return lhsMessage == rhsMessage && lhsStyle == rhsStyle
            
        case let (.warning(lhsMessage, lhsStyle), .warning(rhsMessage, rhsStyle)):
            return lhsMessage == rhsMessage && lhsStyle == rhsStyle
            
        case let (.info(lhsMessage, lhsStyle), .info(rhsMessage, rhsStyle)):
            return lhsMessage == rhsMessage && lhsStyle == rhsStyle
            
        case let (.custom(lhsContent, lhsStyle), .custom(rhsContent, rhsStyle)):
            return lhsContent == rhsContent && lhsStyle == rhsStyle
            
        default:
            return false
        }
    }
}

// MARK: - NotificationCategory
/// Semantic categories for notifications.
public enum NotificationCategory: String, CaseIterable, Sendable {
    case success
    case error  
    case warning
    case info
    case custom
    
    /// Default system image name for each category.
    public var defaultSystemImage: String? {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "xmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        case .custom:
            return nil
        }
    }
    
    /// Default color for each category.
    public var defaultColor: Color {
        switch self {
        case .success:
            return .green
        case .error:
            return .red
        case .warning:
            return .orange
        case .info:
            return .blue
        case .custom:
            return .primary
        }
    }
}

// MARK: - Convenience Factory Methods
public extension NotificationType {
    /// Creates a success notification with alert style.
    /// 
    /// - Parameter message: The success message to display.
    /// - Returns: A success notification configured for alert presentation.
    static func success(_ message: String) -> Self {
        .success(message, style: .alert)
    }
    
    /// Creates an error notification with alert style.
    /// 
    /// - Parameter message: The error message to display.
    /// - Returns: An error notification configured for alert presentation.
    static func error(_ message: String) -> Self {
        .error(message, style: .alert)
    }
    
    /// Creates a warning notification with alert style.
    /// 
    /// - Parameter message: The warning message to display.
    /// - Returns: A warning notification configured for alert presentation.
    static func warning(_ message: String) -> Self {
        .warning(message, style: .alert)
    }
    
    /// Creates an info notification with alert style.
    /// 
    /// - Parameter message: The info message to display.
    /// - Returns: An info notification configured for alert presentation.
    static func info(_ message: String) -> Self {
        .info(message, style: .alert)
    }
    
    /// Creates a custom notification with alert style.
    /// 
    /// - Parameter content: The custom content for the notification.
    /// - Returns: A custom notification configured for alert presentation.
    static func custom(content: NotificationContent) -> Self {
        .custom(content: content, style: .alert)
    }
}
