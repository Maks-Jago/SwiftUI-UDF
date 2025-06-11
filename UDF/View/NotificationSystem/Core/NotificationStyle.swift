//===--- NotificationStyle.swift ---------------------------------===//
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

/// Defines how a notification should be presented to the user.
///
/// `NotificationStyle` determines the presentation method and visual treatment
/// of notifications. Each style has different capabilities and behavior patterns.
public enum NotificationStyle: Equatable, Sendable {
    case alert
    
    // MARK: - Properties
    /// Whether this style supports custom theming.
    public var supportsTheming: Bool {
        switch self {
        case .alert:
            return false // System alerts cannot be themed
        }
    }
    
    /// Whether this style is modal (blocks user interaction with underlying content).
    public var isModal: Bool {
        switch self {
        case .alert:
            return true // System alerts are always modal
        }
    }
    
    /// Whether this style supports text input fields.
    public var supportsTextFields: Bool {
        switch self {
        case .alert:
            return true // System alerts support text fields
        }
    }
    
    /// Whether this style supports action buttons.
    public var supportsButtons: Bool {
        switch self {
        case .alert:
            return true // System alerts support buttons
        }
    }
    
    /// The presentation context for this style.
    public var presentationContext: PresentationContext {
        switch self {
        case .alert:
            return .modal
        }
    }
    
    // MARK: - Equatable Implementation
    public static func == (lhs: NotificationStyle, rhs: NotificationStyle) -> Bool {
        switch (lhs, rhs) {
        case (.alert, .alert):
            return true
        default:
            return false
        }
    }
}

// MARK: - PresentationContext
/// Describes how a notification style is presented to the user.
public enum PresentationContext: Equatable {
    /// Modal presentation that blocks interaction with underlying content.
    case modal
    
    /// Overlay presentation that appears on top but allows interaction underneath.
    case overlay
    
    /// Inline presentation that appears within the content flow.
    case inline
    
    /// Custom presentation with specific positioning and behavior.
    case custom
}

// MARK: - Style Validation
public extension NotificationStyle {
    /// Validates whether this style can present the given notification type.
    /// 
    /// - Parameter type: The notification type to validate.
    /// - Returns: True if this style can present the notification type.
    func canPresent(_ type: NotificationType) -> Bool {
        switch (self, type) {
        case (.alert, _):
            // System alerts can present all notification types
            return true
            // Future styles may have restrictions
        }
    }
    
    /// Validates whether this style supports the given actions.
    /// 
    /// - Parameter actions: The actions to validate.
    /// - Returns: True if this style can present all the given actions.
    func canPresentActions(_ actions: [any NotificationAction]) -> Bool {
        switch self {
        case .alert:
            return actions.allSatisfy { action in
                action is NotificationButton || action is NotificationTextField
            }
        }
    }
}

// MARK: - Convenience Properties
public extension NotificationStyle {
    static var `default`: NotificationStyle {
        .alert
    }
}

// MARK: - Debug Support
extension NotificationStyle: CustomStringConvertible {
    public var description: String {
        switch self {
        case .alert:
            return "NotificationStyle.alert"
        }
    }
}

extension NotificationStyle: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .alert:
            return "NotificationStyle.alert(modal: true, theming: false)"
        }
    }
}
