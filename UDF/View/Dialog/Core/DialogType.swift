//===--- DialogType.swift ----------------------------------===//
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

public protocol DialogTypeProtocol: Sendable, IsEquatable, Hashable {
    var style: DialogStyle { get }
    var category: DialogCategory { get }

    var title: String { get }
    var message: String? { get }
    var actions: [any DialogAction] { get }
    
    /// Returns the icon for this dialog as a type-erased AnyView
    func getIconView(theme: ToastTheme) -> AnyView?
    
    /// Returns the custom content view for this dialog as a type-erased AnyView
    func getCustomContentView() -> AnyView?
}

extension DialogTypeProtocol {
    /// The toast configuration if this dialog uses toast style.
    /// Returns nil for non-toast dialogs.
    public var toastConfiguration: ToastConfiguration? {
        if case .toast(let configuration) = style {
            return configuration
        }
        return nil
    }

}

enum DialogCustomType<Icon: View, Content: View>: DialogTypeProtocol {
    case custom(content: DialogContent<Icon, Content>, style: DialogStyle)

    var style: DialogStyle {
        switch self {
        case .custom(_, style: let style):
            return style
        }
    }

    var title: String {
        switch self {
        case let .custom(content, _):
            return content.title
        }
    }

    var message: String? {
        switch self {
        case let .custom(content, _):
            return content.message
        }
    }

    var actions: [any DialogAction] {
        switch self {
        case let .custom(content, _):
            return content.actions
        }
    }

    var category: DialogCategory {
        .custom
    }
    
    func getIconView(theme: ToastTheme) -> AnyView? {
        switch self {
        case let .custom(content, _):
            return content.renderIcon()
        }
    }
    
    func getCustomContentView() -> AnyView? {
        switch self {
        case let .custom(content, _):
            if let customContentView = content.customContentView {
                return AnyView(customContentView())
            }
            return nil
        }
    }
}

/// Defines the type and content of a dialog.
///
/// `DialogType` represents different categories of dialogs with their
/// associated content and presentation style. Each type carries semantic meaning
/// and can be styled differently based on the dialog style.
///
/// ## Usage:
/// ```swift
/// // Simple message dialogs
/// let successDialog = DialogType.success("File saved!", style: .alert)
/// let errorDialog = DialogType.error("Upload failed", style: .alert)
///
/// // Complex dialog with custom content
/// let customDialog = DialogType.custom(
///     content: DialogContent("Title", message: "Message") {
///         DialogButton.default("OK")
///     },
///     style: .alert
/// )
/// ```
public enum DialogType: Sendable, DialogTypeProtocol {
    /// A success dialog with a message.
    case success(message: String, style: DialogStyle)
    
    /// An error dialog with a message.
    case error(message: String, style: DialogStyle)
    
    /// A warning dialog with a message.
    case warning(message: String, style: DialogStyle)
    
    /// An informational dialog with a message.
    case info(message: String, style: DialogStyle)

    // MARK: - Computed Properties
    
    /// The dialog style associated with this type.
    public var style: DialogStyle {
        switch self {
        case .success(_, let style),
                .error(_, let style),
                .warning(_, let style),
                .info(_, let style):
            return style
        }
    }
    
    /// The primary message for simple dialog types.
    /// Returns nil for custom dialogs.
    public var message: String? {
        switch self {
        case .success(let message, _),
                .error(let message, _),
                .warning(let message, _),
                .info(let message, _):
            return message
        }
    }

    public var title: String {
        ""
    }

    public var actions: [any DialogAction] {
        []
    }

    /// The semantic category of this dialog.
    public var category: DialogCategory {
        switch self {
        case .success:
            return .success
        case .error:
            return .error
        case .warning:
            return .warning
        case .info:
            return .info
        }
    }
    
    public func getIconView(theme: ToastTheme) -> AnyView? {
        let systemName = switch self {
        case .success: "checkmark.circle.fill"
        case .error: "exclamationmark.triangle.fill" 
        case .warning: "exclamationmark.triangle.fill"
        case .info: "info.circle.fill"
        }
        
        return AnyView(
            Image(systemName: systemName)
                .foregroundStyle(theme.colorStyle(for: category).foregroundColor)
                .font(.system(size: theme.iconSize))
        )
    }
    
    public func getCustomContentView() -> AnyView? {
        // Semantic dialog types don't have custom content
        return nil
    }

    // MARK: - Equatable Implementation
    public static func == (lhs: DialogType, rhs: DialogType) -> Bool {
        switch (lhs, rhs) {
        case let (.success(lhsMessage, lhsStyle), .success(rhsMessage, rhsStyle)):
            return lhsMessage == rhsMessage && lhsStyle == rhsStyle
            
        case let (.error(lhsMessage, lhsStyle), .error(rhsMessage, rhsStyle)):
            return lhsMessage == rhsMessage && lhsStyle == rhsStyle
            
        case let (.warning(lhsMessage, lhsStyle), .warning(rhsMessage, rhsStyle)):
            return lhsMessage == rhsMessage && lhsStyle == rhsStyle
            
        case let (.info(lhsMessage, lhsStyle), .info(rhsMessage, rhsStyle)):
            return lhsMessage == rhsMessage && lhsStyle == rhsStyle

        default:
            return false
        }
    }
    
    // MARK: - Hashable Implementation
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .success(let message, let style):
            hasher.combine("success")
            hasher.combine(message)
            hasher.combine(style)
        case .error(let message, let style):
            hasher.combine("error")
            hasher.combine(message)
            hasher.combine(style)
        case .warning(let message, let style):
            hasher.combine("warning")
            hasher.combine(message)
            hasher.combine(style)
        case .info(let message, let style):
            hasher.combine("info")
            hasher.combine(message)
            hasher.combine(style)
        }
    }
}

// MARK: - DialogCategory
/// Semantic categories for dialogs.
public enum DialogCategory: String, CaseIterable, Sendable {
    case success
    case error  
    case warning
    case info
    case custom
    
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
