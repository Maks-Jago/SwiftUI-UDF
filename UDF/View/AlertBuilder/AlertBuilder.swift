//===--- AlertBuilder.swift ---------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

/// A builder for creating and managing alert states and styles.
///
/// `AlertBuilder` provides mechanisms for constructing alert styles, managing alert status, and registering custom alerts.
/// It contains the nested types `AlertStatus` and `AlertStyle`, which define the properties and behavior of alerts within an application.
@available(*, deprecated, message: "Will be removed in future versions. Use Dialog System instead.")
public enum AlertBuilder {
    /// Represents the current state of an alert.
    ///
    /// **Deprecated**: This is now just a typealias to `DialogStatus`.
    /// Please migrate to using `DialogStatus` directly and use `.dialog(status:)` instead of `.alert(status:)`.
    public typealias AlertStatus = DialogStatus
    
    // MARK: - AlertStyle
    /// Defines the style of an alert, including its type and content.
    public struct AlertStyle: Equatable {
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
        
        public var id: UUID
        var type: AlertType
        
        /// Enum representing the different types of alerts.
        enum AlertType {
            case validationError(text: @Sendable () -> String)
            case success(text: @Sendable () -> String)
            case failure(text: @Sendable () -> String)
            case message(text: @Sendable () -> String)
            case messageTitle(title: @autoclosure @Sendable () -> String, message: @Sendable () -> String)

            case customActions(title: @Sendable () -> String, text: @Sendable () -> String, actions: @Sendable () -> [any AlertAction])
        }
        
        // MARK: Initializers
        /// Initializes a validation error alert style with a specific text.
        public init(validationError text: String) {
            self.init(validationError: { text })
        }
        
        /// Initializes a validation error alert style with a closure providing the text.
        public init(validationError text: @Sendable @escaping () -> String) {
            id = UUID()
            type = .validationError(text: text)
        }
        
        /// Initializes a failure alert style with a specific text.
        public init(failure text: String) {
            self.init(failure: { text })
        }
        
        /// Initializes a failure alert style with a closure providing the text.
        public init(failure text: @Sendable @escaping () -> String) {
            id = UUID()
            type = .failure(text: text)
        }
        
        /// Initializes a success alert style with a specific text.
        public init(success text: String) {
            self.init(success: { text })
        }
        
        /// Initializes a success alert style with a closure providing the text.
        public init(success text: @Sendable @escaping () -> String) {
            id = UUID()
            type = .success(text: text)
        }
        
        /// Initializes a message alert style with a specific text.
        public init(message text: String) {
            self.init(message: { text })
        }
        
        /// Initializes a message alert style with a closure providing the text.
        public init(message text: @Sendable @escaping () -> String) {
            id = UUID()
            type = .message(text: text)
        }
        
        /// Initializes an alert style with a title and message.
        public init(title: String, message: String) {
            self.init(title: { title }(), message: { message }())
        }
        
        /// Initializes an alert style with closures for title and message.
        public init(title: @autoclosure @Sendable @escaping () -> String, message: @Sendable @escaping () -> String) {
            id = UUID()
            type = .messageTitle(title: title(), message: message)
        }
        
        /// Initializes a custom alert style with a title, text, and custom actions.
        public init(title: String, text: String, @DialogActionsBuilder actions: @Sendable @escaping () -> [any AlertAction]) {
            self.init(title: { title }, text: { text }, actions: actions)
        }
        
        /// Initializes a custom alert style with closures for title, text, and actions.
        public init(
            title: @Sendable @escaping () -> String,
            text: @Sendable @escaping () -> String,
            @DialogActionsBuilder actions: @Sendable @escaping () -> [any AlertAction]
        ) {
            id = UUID()
            type = .customActions(title: title, text: text, actions: actions)
        }
    }
    
    // MARK: - Alert Builder Registration
    typealias AlertBuilderBlock = () -> AlertStyle
    
    nonisolated(unsafe) static var alertBuilders: [AnyHashable: AlertBuilderBlock] = [:]
    
    /// Registers a custom alert builder for a given ID.
    ///
    /// **Deprecated**: This now delegates to the new DialogRegistry system.
    /// Please use `DialogRegistry.register(id:builder:)` directly for new code.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the alert builder.
    ///   - builder: A closure that returns an `AlertStyle`.
    @available(*, deprecated, message: "Use DialogRegistry.register(id:builder:) instead")
    public static func registerAlert(by id: some Hashable & Sendable, _ builder: @escaping @Sendable () -> AlertStyle) {
        DialogRegistry.register(id: id) {
            // Convert the AlertStyle to DialogType when accessed
            let alertStyle = builder()
            switch alertStyle.type {
            case .validationError(let text):
                return DialogType.error(message: text(), style: .alert)
            case .success(let text):
                return DialogType.success(message: text(), style: .alert)
            case .failure(let text):
                return DialogType.error(message: text(), style: .alert)
            case .message(let text):
                return DialogType.info(message: text(), style: .alert)
            case .messageTitle(let title, let message):
                let content = DialogContent(title: title(), message: message())
                return DialogCustomType.custom(content: content, style: .alert)
            case .customActions(let title, let text, let actions):
                let content = DialogContent(
                    title: title(),
                    message: text(),
                    actions: actions
                )
                return DialogCustomType.custom(content: content, style: .alert)
            }
        }
    }
}

// MARK: - DialogStatus Extensions for AlertBuilder Compatibility

public extension DialogStatus {
    /// Initializes a dialog status with a specific alert style.
    ///
    /// This extension provides backward compatibility for AlertBuilder.AlertStyle.
    /// 
    init(style: AlertBuilder.AlertStyle) {
        switch style.type {
        case .validationError(let text):
            self = DialogStatus(error: text(), style: .alert)
        case .success(let text):
            self = DialogStatus(success: text(), style: .alert)
        case .failure(let text):
            self = DialogStatus(error: text(), style: .alert)
        case .message(let text):
            self = DialogStatus(info: text(), style: .alert)
        case .messageTitle(let title, let message):
            let content = DialogContent(title: title(), message: message())
            self = DialogStatus(dialog: DialogCustomType.custom(content: content, style: .alert))
        case .customActions(let title, let text, let actions):
            // Convert AlertActions to DialogActions
            let content = DialogContent(title: title(), message: text()) {
                // Convert actions within the builder context
                for action in actions() {
                    if let button = action as? DialogButton {
                        DialogButton(title: button.title, action: button.action)
                    } else if let textField = action as? DialogTextField {
                        DialogTextField(title: textField.title, text: textField.text)
                    }
                }
            }
            self = DialogStatus(dialog: DialogCustomType.custom(content: content, style: .alert))
        }
    }
}
