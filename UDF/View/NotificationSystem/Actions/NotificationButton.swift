//===--- NotificationButton.swift ----------------------------------===//
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

/// A customizable button for notifications, conforming to `NotificationAction` and `View`.
///
/// `NotificationButton` provides a convenient way to create buttons for notifications in SwiftUI, with options to
/// configure the title, role, disabled state, and action. It conforms to both `NotificationAction` and `View`,
/// allowing it to be used directly in SwiftUI view hierarchies and within notification action builders.
///
/// This is a direct migration from `AlertButton` with the same API surface, ensuring compatibility
/// with existing code while extending support to all notification styles.
///
/// ## Properties:
/// - `title`: The title of the button.
/// - `role`: An optional `ButtonRole` (e.g., `.cancel`, `.destructive`) to define the button's role.
/// - `disabled`: A Boolean indicating if the button is disabled.
/// - `action`: A closure to execute when the button is tapped.
///
/// ## Initializers:
/// - `init(title:action:)`: Creates a `NotificationButton` with a specified title and an optional action.
///
/// ## Methods:
/// - `role(_:)`: Sets the role of the button and returns a new `NotificationButton`.
/// - `disabled(_:)`: Sets the disabled state of the button and returns a new `NotificationButton`.
///
/// ## Example:
/// ```swift
/// let okButton = NotificationButton.default("OK") {
///    print("OK tapped")
/// }
///
/// let cancelButton = NotificationButton.cancel("Cancel")
///
/// let deleteButton = NotificationButton.destructive("Delete") {
///     print("Delete tapped")
/// }
/// ```
///
/// ## Conformance:
/// - Conforms to `NotificationAction`, making it suitable for use in all notification styles.
/// - Conforms to `View`, allowing it to be used directly in SwiftUI view hierarchies.
public struct NotificationButton: NotificationAction {
    /// The title text displayed on the button.
    public var title: String
    
    /// The semantic role of the button (cancel, destructive, etc.).
    public var role: ButtonRole?
    
    /// Whether the button is disabled and non-interactive.
    public var disabled: Bool = false
    
    /// The action to execute when the button is tapped.
    public nonisolated(unsafe) var action: () -> Void
    
    // MARK: - Equatable Implementation
    /// Checks if two `NotificationButton` instances are equal by comparing their title, role, and disabled state.
    /// 
    /// Note: Actions are not compared as closures cannot be compared for equality.
    nonisolated public static func == (lhs: NotificationButton, rhs: NotificationButton) -> Bool {
        lhs.title == rhs.title && 
        lhs.role == rhs.role && 
        lhs.disabled == rhs.disabled
    }
    
    // MARK: - Hashable Implementation
    /// Hashes the essential properties of the `NotificationButton`.
    /// 
    /// Note: Actions are not included in the hash as closures cannot be hashed.
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(disabled)
    }
    
    // MARK: - Initializers
    /// Creates a `NotificationButton` with a specified title and an optional action.
    ///
    /// - Parameters:
    ///   - title: The title of the button.
    ///   - action: A closure to execute when the button is tapped. Defaults to an empty closure.
    nonisolated public init(
        title: String,
        action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.action = action
    }
    
    // MARK: - View Implementation
    /// The view body of the `NotificationButton`.
    /// 
    /// This creates a standard SwiftUI Button with the configured properties.
    /// The actual presentation may vary depending on the notification style.
    public var body: some View {
        Button(title, role: role, action: action)
            .disabled(disabled)
    }
}

// MARK: - View Conformance
extension NotificationButton: View {}

// MARK: - Action Classification
extension NotificationButton: @preconcurrency NotificationActionClassification {
    var actionType: NotificationActionType {
        .button
    }
    
    var capabilities: NotificationActionCapability {
        var caps: NotificationActionCapability = [.requiresInteraction, .canBeDisabled, .dismissesNotification]
        
        if role != nil {
            caps.insert(.hasRole)
        }
        
        return caps
    }
}

// MARK: - Modifiers
public extension NotificationButton {
    /// Sets the role of the button and returns a new `NotificationButton`.
    ///
    /// - Parameter role: The `ButtonRole` to assign to the button (e.g., `.cancel`, `.destructive`).
    /// - Returns: A modified `NotificationButton` with the specified role.
    /// 
    /// ## Example:
    /// ```swift
    /// let deleteButton = NotificationButton(title: "Delete")
    ///     .role(.destructive)
    /// ```
    nonisolated func role(_ role: ButtonRole) -> NotificationButton {
        mutate { button in
            button.role = role
        }
    }
    
    /// Sets the disabled state of the button and returns a new `NotificationButton`.
    ///
    /// - Parameter disabled: A Boolean indicating if the button should be disabled.
    /// - Returns: A modified `NotificationButton` with the specified disabled state.
    /// 
    /// ## Example:
    /// ```swift
    /// let conditionalButton = NotificationButton(title: "Submit")
    ///     .disabled(!isFormValid)
    /// ```
    nonisolated func disabled(_ disabled: Bool) -> NotificationButton {
        mutate { button in
            button.disabled = disabled
        }
    }
}

// MARK: - Factory Methods
public extension NotificationAction where Self == NotificationButton {
    /// Creates a default notification button with the specified title and action.
    ///
    /// - Parameters:
    ///   - title: The title of the button.
    ///   - action: A closure to execute when the button is tapped. Defaults to an empty closure.
    /// - Returns: A `NotificationButton` with the given title and action.
    /// 
    /// ## Example:
    /// ```swift
    /// NotificationButton.default("OK") {
    ///     print("OK tapped")
    /// }
    /// ```
    nonisolated static func `default`(_ title: String, action: @escaping () -> Void = {}) -> Self {
        NotificationButton(title: title, action: action)
    }
    
    /// Creates a cancel notification button with the specified title and action.
    ///
    /// - Parameters:
    ///   - title: The title of the button.
    ///   - action: A closure to execute when the button is tapped. Defaults to an empty closure.
    /// - Returns: A `NotificationButton` with the given title and cancel role.
    /// 
    /// ## Example:
    /// ```swift
    /// NotificationButton.cancel("Cancel") {
    ///     print("Cancelled")
    /// }
    /// ```
    nonisolated static func cancel(_ title: String, action: @escaping () -> Void = {}) -> Self {
        NotificationButton(title: title, action: action)
            .role(.cancel)
    }
    
    /// Creates a destructive notification button with the specified title and action.
    ///
    /// - Parameters:
    ///   - title: The title of the button.
    ///   - action: A closure to execute when the button is tapped. Defaults to an empty closure.
    /// - Returns: A `NotificationButton` with the given title and destructive role.
    /// 
    /// ## Example:
    /// ```swift
    /// NotificationButton.destructive("Delete") {
    ///     performDelete()
    /// }
    /// ```
    nonisolated static func destructive(_ title: String, action: @escaping () -> Void = {}) -> Self {
        NotificationButton(title: title, action: action)
            .role(.destructive)
    }
}
