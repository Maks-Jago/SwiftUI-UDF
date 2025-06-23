//===--- DialogStatus.swift ---------------------------------===//
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

/// A state manager for dialogs.
///
/// `DialogStatus` provides the main interface for managing dialog presentation
/// and dismissal across the application. It handles both simple message dialogs
/// and complex dialogs with custom content and actions.
///
/// ## Usage:
/// ```swift
/// @State private var dialog = DialogStatus.dismissed
///
/// // Simple error dialog
/// dialog = .init(error: "Something went wrong")
///
/// // Complex dialog with actions
/// dialog = .init(style: .alert) {
///     DialogContent("Delete Item", message: "This cannot be undone") {
///         DialogButton.destructive("Delete") { /* action */ }
///         DialogButton.cancel("Cancel")
///     }
/// }
/// ```
public struct DialogStatus: Equatable, Identifiable, Sendable {
    /// Returns a dismissed dialog state.
    public static var dismissed: Self {
        .init(dismissedUUID: "32DA8B0A-5C48-4FBC-8464-E80AD89AE16D") 
    }
    
    /// Unique identifier for this dialog state.
    public let id: UUID
    
    /// Current status of the dialog.
    public var status: Status
    
    /// Enum representing the status of a dialog, either presented or dismissed.
    public enum Status: Equatable, Sendable {
        case presented(DialogType)
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
    
    /// Initializes a dialog state with an error message.
    ///
    /// Creates an error dialog using the specified message and presentation style.
    /// If the message is nil or empty, creates a dismissed state instead.
    ///
    /// - Parameters:
    ///   - error: The error message to display. If nil or empty, creates a dismissed state.
    ///   - style: The dialog style for presentation. Defaults to `.alert`.
    ///
    /// ## Example:
    /// ```swift
    /// // Alert-style error
    /// dialog = .init(error: "Network connection failed")
    ///
    /// // Toast-style error
    /// dialog = .init(error: "Upload failed", style: .toast())
    /// ```
    public init(error: String?, style: DialogStyle = .alert) {
        if let error, !error.isEmpty {
            self = .init(dialog: .error(message: error, style: style))
        } else {
            self = .init()
        }
    }
    
    /// Initializes a dialog state with a success message.
    ///
    /// Creates a success dialog using the specified message and presentation style.
    /// If the message is nil or empty, creates a dismissed state instead.
    ///
    /// - Parameters:
    ///   - success: The success message to display. If nil or empty, creates a dismissed state.
    ///   - style: The dialog style for presentation. Defaults to `.alert`.
    ///
    /// ## Example:
    /// ```swift
    /// // Alert-style success
    /// dialog = .init(success: "File saved successfully")
    ///
    /// // Toast-style success
    /// dialog = .init(success: "Done!", style: .toast(.bottom))
    /// ```
    public init(success: String?, style: DialogStyle = .alert) {
        if let success, !success.isEmpty {
            self = .init(dialog: .success(message: success, style: style))
        } else {
            self = .init()
        }
    }
    
    /// Initializes a dialog state with a warning message.
    ///
    /// Creates a warning dialog using the specified message and presentation style.
    /// If the message is nil or empty, creates a dismissed state instead.
    ///
    /// - Parameters:
    ///   - warning: The warning message to display. If nil or empty, creates a dismissed state.
    ///   - style: The dialog style for presentation. Defaults to `.alert`.
    ///
    /// ## Example:
    /// ```swift
    /// // Alert-style warning
    /// dialog = .init(warning: "Storage space is low")
    ///
    /// // Toast-style warning
    /// dialog = .init(warning: "Unsaved changes", style: .toast(.vibrant))
    /// ```
    public init(warning: String?, style: DialogStyle = .alert) {
        if let warning, !warning.isEmpty {
            self = .init(dialog: .warning(message: warning, style: style))
        } else {
            self = .init()
        }
    }
    
    /// Initializes a dialog state with an info message.
    ///
    /// Creates an informational dialog using the specified message and presentation style.
    /// If the message is nil or empty, creates a dismissed state instead.
    ///
    /// - Parameters:
    ///   - info: The info message to display. If nil or empty, creates a dismissed state.
    ///   - style: The dialog style for presentation. Defaults to `.alert`.
    ///
    /// ## Example:
    /// ```swift
    /// // Alert-style info
    /// dialog = .init(info: "New features available")
    ///
    /// // Toast-style info
    /// dialog = .init(info: "3 new messages", style: .toast(.subtle))
    /// ```
    public init(info: String?, style: DialogStyle = .alert) {
        if let info, !info.isEmpty {
            self = .init(dialog: .info(message: info, style: style))
        } else {
            self = .init()
        }
    }
    
    // MARK: - Advanced Initializers
    
    /// Creates a confirmation dialog with message and actions.
    ///
    /// - Parameters:
    ///   - message: The message to display in the dialog.
    ///   - configuration: Dialog configuration. Defaults to .default.
    ///   - actions: Action buttons for the dialog.
    public init(
        confirmationDialog message: String,
        configuration: ConfirmationDialogConfiguration = .default,
        @DialogContentBuilder actions: () -> [any DialogAction]
    ) {
        let content = DialogContent<EmptyView>(title: "", message: message, actions: actions())
        self = .init(dialog: .custom(content: content.eraseToAnyDialogContent(), style: .confirmationDialog(configuration)))
    }
    
    /// Creates a simple confirmation dialog with just message and actions.
    ///
    /// - Parameters:
    ///   - message: The message to display.
    ///   - configuration: Dialog configuration.
    ///   - actions: Action buttons for the dialog.
    public init(
        confirmationDialog message: String,
        @DialogActionsBuilder actions: () -> [any DialogAction]
    ) {
        self.init(confirmationDialog: message, configuration: .default, actions: actions)
    }
    
    /// Initializes a dialog state with custom content using a result builder.
    ///
    /// Creates a dialog with complex content including actions, using the
    /// `DialogContentBuilder` for a declarative API. This enables rich
    /// dialogs with buttons and other interactive elements.
    ///
    /// - Parameters:
    ///   - style: The dialog style for presentation. Defaults to `.alert`.
    ///   - content: A closure that returns `DialogContent` with actions.
    ///
    /// ## Example:
    /// ```swift
    /// dialog = .init(style: .alert) {
    ///     DialogContent("Delete Item", message: "This cannot be undone") {
    ///         DialogButton.destructive("Delete") { performDelete() }
    ///         DialogButton.cancel("Cancel")
    ///     }
    /// }
    /// ```
    public init(
        style: DialogStyle,
        @DialogContentBuilder content: () -> DialogContent<AnyView>
    ) {
        self = .init(dialog: .custom(content: content(), style: style))
    }
    
    /// Initializes a dialog state using a registered dialog identified by a unique ID.
    ///
    /// Looks up a pre-registered dialog by its identifier and creates a state
    /// for presentation. If no dialog is registered for the given ID, creates
    /// a dismissed state instead.
    ///
    /// - Parameter id: The identifier of the registered dialog.
    ///
    /// ## Example:
    /// ```swift
    /// // First, register a dialog
    /// DialogRegistry.register(id: "networkError") {
    ///     .error("No internet connection", style: .toast(.center))
    /// }
    /// 
    /// // Later, use the registered dialog
    /// dialog = .init(id: "networkError")
    /// ```
    public init(id: some Hashable) {
        if let dialog = DialogRegistry.get(id: id) {
            self = .init(dialog: dialog)
        } else {
            self = .dismissed
        }
    }
    
    /// Initializes a dialog state with a specific dialog type.
    ///
    /// Creates a dialog state for presenting the specified dialog type.
    /// This is the most direct way to create dialogs with full control over
    /// content and presentation style.
    ///
    /// - Parameter dialog: The dialog type to present.
    ///
    /// ## Example:
    /// ```swift
    /// let dialogType = DialogType.success("Done!", style: .toast(.vibrant))
    /// dialog = .init(dialog: dialogType)
    /// ```
    internal init(dialog: DialogType) {
        self.id = UUID()
        self.status = .presented(dialog)
    }
    
    /// Initializes a dismissed dialog status.
    ///
    /// Creates a dialog state that represents no active dialog.
    /// This is equivalent to using the static `.dismissed` property.
    ///
    /// ## Example:
    /// ```swift
    /// let dialog = DialogStatus() // Dismissed state
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

// MARK: - DialogContentBuilder

/// A result builder for creating DialogContent in a declarative way.
@resultBuilder
public enum DialogContentBuilder {
    public static func buildBlock(_ content: DialogContent<AnyView>) -> DialogContent<AnyView> {
        content
    }
    
    public static func buildBlock<Icon: View>(_ content: DialogContent<Icon>) -> DialogContent<AnyView> {
        content.eraseToAnyDialogContent()
    }
}
