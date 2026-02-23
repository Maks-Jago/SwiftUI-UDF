//===--- DialogButton.swift ----------------------------------===//
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

/// A customizable button for dialogs, conforming to `DialogAction` and `View`.
///
/// `DialogButton` provides a convenient way to create buttons for dialogs in SwiftUI, with options to
/// configure the title, role, disabled state, and action. It conforms to both `DialogAction` and `View`,
/// allowing it to be used directly in SwiftUI view hierarchies and within dialog action builders.
///
/// This is a direct migration from `AlertButton` with the same API surface, ensuring compatibility
/// with existing code while extending support to all dialog styles.
///
/// ## Properties:
/// - `title`: The title of the button.
/// - `role`: An optional `ButtonRole` (e.g., `.cancel`, `.destructive`) to define the button's role.
/// - `disabled`: A Boolean indicating if the button is disabled.
/// - `action`: A closure to execute when the button is tapped.
///
/// ## Initializers:
/// - `init(title:action:)`: Creates a `DialogButton` with a specified title and an optional action.
///
/// ## Methods:
/// - `role(_:)`: Sets the role of the button and returns a new `DialogButton`.
/// - `disabled(_:)`: Sets the disabled state of the button and returns a new `DialogButton`.
///
/// ## Example:
/// ```swift
/// let okButton = DialogButton.default("OK") {
///    print("OK tapped")
/// }
///
/// let cancelButton = DialogButton.cancel("Cancel")
///
/// let deleteButton = DialogButton.destructive("Delete") {
///     print("Delete tapped")
/// }
/// ```
///
/// ## Conformance:
/// - Conforms to `DialogAction`, making it suitable for use in all dialog styles.
/// - Conforms to `View`, allowing it to be used directly in SwiftUI view hierarchies.
public struct DialogButton: DialogAction, DialogComponent {
    /// The title text displayed on the button.
    public var title: String
    
    /// The semantic role of the button (cancel, destructive, etc.).
    public var role: ButtonRole?
    
    /// Whether the button is disabled and non-interactive.
    public var disabled: Bool = false
    
    /// The action to execute when the button is tapped.
    public nonisolated(unsafe) var action: () -> Void
    
    // MARK: - Equatable Implementation
    /// Checks if two `DialogButton` instances are equal by comparing their title, role, and disabled state.
    /// 
    /// Note: Actions are not compared as closures cannot be compared for equality.
    nonisolated public static func == (lhs: DialogButton, rhs: DialogButton) -> Bool {
        lhs.title == rhs.title && 
        lhs.role == rhs.role && 
        lhs.disabled == rhs.disabled
    }
    
    // MARK: - Hashable Implementation
    /// Hashes the essential properties of the `DialogButton`.
    /// 
    /// Note: Actions are not included in the hash as closures cannot be hashed.
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(disabled)
    }
    
    // MARK: - Initializers
    /// Creates a `DialogButton` with a specified title and an optional action.
    ///
    /// - Parameters:
    ///   - title: The title of the button.
    ///   - role: The button role. Defaults to nil.
    ///   - action: A closure to execute when the button is tapped. Defaults to an empty closure.
    nonisolated public init(
        title: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.role = role
        self.action = action
    }
    
    // MARK: - View Implementation
    /// The view body of the `DialogButton`.
    /// 
    /// This creates a standard SwiftUI Button with the configured properties.
    /// The actual presentation may vary depending on the dialog style.
    public var body: some View {
        Button(title, role: role, action: action)
            .disabled(disabled)
    }
}

// MARK: - View Conformance
extension DialogButton: View {}

// MARK: - Action Classification
extension DialogButton: @preconcurrency DialogActionClassification {
    var actionType: DialogActionType {
        .button
    }
    
    var capabilities: DialogActionCapability {
        var caps: DialogActionCapability = [.requiresInteraction, .canBeDisabled, .dismissesDialog]
        
        if role != nil {
            caps.insert(.hasRole)
        }
        
        return caps
    }
}

// MARK: - Modifiers
public extension DialogButton {
    /// Sets the role of the button and returns a new `DialogButton`.
    ///
    /// - Parameter role: The `ButtonRole` to assign to the button (e.g., `.cancel`, `.destructive`).
    /// - Returns: A modified `DialogButton` with the specified role.
    /// 
    /// ## Example:
    /// ```swift
    /// let deleteButton = DialogButton(title: "Delete")
    ///     .role(.destructive)
    /// ```
    nonisolated func role(_ role: ButtonRole) -> DialogButton {
        mutate { button in
            button.role = role
        }
    }
    
    /// Sets the disabled state of the button and returns a new `DialogButton`.
    ///
    /// - Parameter disabled: A Boolean indicating if the button should be disabled.
    /// - Returns: A modified `DialogButton` with the specified disabled state.
    /// 
    /// ## Example:
    /// ```swift
    /// let conditionalButton = DialogButton(title: "Submit")
    ///     .disabled(!isFormValid)
    /// ```
    nonisolated func disabled(_ disabled: Bool) -> DialogButton {
        mutate { button in
            button.disabled = disabled
        }
    }
}

// MARK: - Factory Methods
public extension DialogAction where Self == DialogButton {
    /// Creates a default dialog button with the specified title and action.
    ///
    /// - Parameters:
    ///   - title: The title of the button.
    ///   - action: A closure to execute when the button is tapped. Defaults to an empty closure.
    /// - Returns: A `DialogButton` with the given title and action.
    /// 
    /// ## Example:
    /// ```swift
    /// DialogButton.default("OK") {
    ///     print("OK tapped")
    /// }
    /// ```
    nonisolated static func `default`(_ title: String, action: @escaping () -> Void = {}) -> Self {
        DialogButton(title: title, action: action)
    }
    
    /// Creates a cancel dialog button with the specified title and action.
    ///
    /// - Parameters:
    ///   - title: The title of the button.
    ///   - action: A closure to execute when the button is tapped. Defaults to an empty closure.
    /// - Returns: A `DialogButton` with the given title and cancel role.
    /// 
    /// ## Example:
    /// ```swift
    /// DialogButton.cancel("Cancel") {
    ///     print("Cancelled")
    /// }
    /// ```
    nonisolated static func cancel(_ title: String, action: @escaping () -> Void = {}) -> Self {
        DialogButton(title: title, action: action)
            .role(.cancel)
    }
    
    /// Creates a destructive dialog button with the specified title and action.
    ///
    /// - Parameters:
    ///   - title: The title of the button.
    ///   - action: A closure to execute when the button is tapped. Defaults to an empty closure.
    /// - Returns: A `DialogButton` with the given title and destructive role.
    /// 
    /// ## Example:
    /// ```swift
    /// DialogButton.destructive("Delete") {
    ///     performDelete()
    /// }
    /// ```
    nonisolated static func destructive(_ title: String, action: @escaping () -> Void = {}) -> Self {
        DialogButton(title: title, action: action)
            .role(.destructive)
    }
}
