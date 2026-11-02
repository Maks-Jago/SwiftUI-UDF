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

/// Describes the shape of a dialog's content and presentation.
///
/// Conforming types (such as `DialogType` and `DialogCustomType`) define what a dialog displays —
/// its style, semantic category, title, message and actions — and how it renders its icon and any
/// custom content. This is the core protocol every dialog type in the Dialog subsystem conforms to.
public protocol DialogTypeProtocol: Sendable, IsEquatable, Hashable {
    /// The presentation style of the dialog (e.g. alert, toast, confirmation).
    var style: DialogStyle { get }
    /// The semantic category of the dialog (success, error, warning, info, or custom).
    var category: DialogCategory { get }

    /// The dialog's title. Returns an empty string for types that have no title.
    var title: String { get }
    /// The dialog's message, if any.
    var message: String? { get }
    /// The actions the dialog offers to the user.
    var actions: [any DialogAction] { get }
    
    /// Returns the icon for this dialog as a type-erased AnyView
    @MainActor
    func getIconView(theme: ToastTheme) -> AnyView?
    
    /// Returns the custom content view for this dialog as a type-erased AnyView
    @MainActor
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

public enum DialogCustomType<Icon: View, Content: View>: DialogTypeProtocol {
    case custom(content: DialogContent<Icon, Content>, style: DialogStyle)
    
    public var style: DialogStyle {
        switch self {
        case .custom(_, style: let style):
            return style
        }
    }
    
    public var title: String {
        switch self {
        case let .custom(content, _):
            return content.title()
        }
    }
    
    public var message: String? {
        switch self {
        case let .custom(content, _):
            return content.message()
        }
    }
    
    public var actions: [any DialogAction] {
        switch self {
        case let .custom(content, _):
            return content.actions
        }
    }
    
    public var category: DialogCategory {
        .custom
    }
    
    public func getIconView(theme: ToastTheme) -> AnyView? {
        switch self {
        case let .custom(content, _):
            return content.renderIcon()
        }
    }
    
    public func getCustomContentView() -> AnyView? {
        switch self {
        case let .custom(content, _):
            if let customContentView = content.customContentView {
                return AnyView(customContentView())
            }
            return nil
        }
    }
}

extension DialogCustomType: DialogProtocol {
    public var payload: DialogPayload {
        let icon: @MainActor () -> AnyView = {
            getIconView(theme: .default) ?? AnyView(EmptyView())
        }
        let content: @MainActor () -> AnyView = {
            getCustomContentView() ?? AnyView(EmptyView())
        }
        let title: @Sendable () -> String = { [title] in title }
        let message: @Sendable () -> String? = { [message] in message }
        
        return DialogPayload(
            title: title,
            message: message,
            actions: actions,
            icon: icon,
            customContentView: content
        )
    }
    
    public var dialogStyle: DialogStyle {
        style
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
