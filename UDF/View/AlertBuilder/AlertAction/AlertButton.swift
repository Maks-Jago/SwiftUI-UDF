//===--- AlertButton.swift --------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

/// A customizable button for alerts, conforming to `AlertAction` and `View`.
///
/// `AlertButton` provides a convenient way to create buttons for alerts in SwiftUI, with options to
/// configure the title, role, disabled state, and action. It conforms to both `AlertAction` and `View`,
/// allowing it to be used directly in SwiftUI view hierarchies.
///
/// ## Properties:
/// - `title`: The title of the button.
/// - `role`: An optional `ButtonRole` (e.g., `.cancel`, `.destructive`) to define the button's role.
/// - `disabled`: A Boolean indicating if the button is disabled.
/// - `action`: A closure to execute when the button is tapped.
///
/// ## Initializers:
/// - `init(title:action:)`: Creates an `AlertButton` with a specified title and an optional action.
///
/// ## Methods:
/// - `role(_:)`: Sets the role of the button and returns a new `AlertButton`.
/// - `disabled(_:)`: Sets the disabled state of the button and returns a new `AlertButton`.
///
/// ## Example:
/// ```swift
/// let okButton = AlertButton.default("OK") {
///    print("OK tapped")
/// }
///
/// let cancelButton = AlertButton.cancel("Cancel")
///
/// let deleteButton = AlertButton.destructive("Delete") {
///     print("Delete tapped")
/// }
/// ```
///
/// ## Conformance:
/// - Conforms to `AlertAction`, making it suitable for use in SwiftUI alerts.
/// - Conforms to `View`, allowing it to be used directly in SwiftUI view hierarchies.
public struct AlertButton: AlertAction {
    public var title: String
    public var role: ButtonRole?
    public var disabled: Bool = false
    public var action: () -> ()
    
    /// Checks if two `AlertButton` instances are equal by comparing their title, role, and disabled state.
    public static func == (lhs: AlertButton, rhs: AlertButton) -> Bool {
        lhs.title == rhs.title && lhs.role == rhs.role && lhs.disabled == rhs.disabled
    }
    
    /// Hashes the essential properties of the `AlertButton`.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(disabled)
    }
    
    /// Creates an `AlertButton` with a specified title and an optional action.
    ///
    /// - Parameters:
    ///   - title: The title of the button.
    ///   - action: A closure to execute when the button is tapped. Defaults to an empty closure.
    public init(
        title: String,
        action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.action = action
    }
    
    /// The view body of the `AlertButton`.
    public var body: some View {
        Button(title, role: role, action: action)
            .disabled(disabled)
    }
}

extension AlertButton: View {}

// MARK: - Modifiers
public extension AlertButton {
    /// Sets the role of the button and returns a new `AlertButton`.
    ///
    /// - Parameter role: The `ButtonRole` to assign to the button (e.g., `.cancel`, `.destructive`).
    /// - Returns: A modified `AlertButton` with the specified role.
    func role(_ role: ButtonRole) -> AlertButton {
        mutate { button in
            button.role = role
        }
    }
    
    /// Sets the disabled state of the button and returns a new `AlertButton`.
    ///
    /// - Parameter disabled: A Boolean indicating if the button should be disabled.
    /// - Returns: A modified `AlertButton` with the specified disabled state.
    func disabled(_ disabled: Bool) -> AlertButton {
        mutate { button in
            button.disabled = disabled
        }
    }
}

// MARK: - Predefined Buttons
public extension AlertAction where Self == AlertButton {
    /// Creates a default alert button with the specified title and action.
    ///
    /// - Parameters:
    ///   - title: The title of the button.
    ///   - action: A closure to execute when the button is tapped. Defaults to an empty closure.
    /// - Returns: An `AlertButton` with the given title and action.
    static func `default`(_ title: String, action: @escaping () -> Void = {}) -> Self {
        AlertButton(title: title, action: action)
    }
    
    /// Creates a default alert button with the specified text and action.
    ///
    /// - Warning: This method is deprecated. Use the `default` method with a `String` instead of `Text`.
    /// - Parameters:
    ///   - text: A `Text` object representing the title of the button.
    ///   - action: A closure to execute when the button is tapped. Defaults to an empty closure.
    /// - Returns: An `AlertButton` with the given text and action.
    @available(*, deprecated, message: "use `default` with String instead of Text")
    static func `default`(_ text: Text, action: @escaping () -> Void = {}) -> Self {
        AlertButton(title: text.content ?? "", action: action)
    }
    
    /// Creates a cancel alert button with the specified title and action.
    ///
    /// - Parameters:
    ///   - title: The title of the button.
    ///   - action: A closure to execute when the button is tapped. Defaults to an empty closure.
    /// - Returns: An `AlertButton` with the given title and cancel role.
    static func cancel(_ title: String, action: @escaping () -> Void = {}) -> Self {
        AlertButton(title: title, action: action)
            .role(.cancel)
    }
    
    /// Creates a cancel alert button with the specified text and action.
    ///
    /// - Warning: This method is deprecated. Use the `cancel` method with a `String` instead of `Text`.
    /// - Parameters:
    ///   - text: A `Text` object representing the title of the button.
    ///   - action: A closure to execute when the button is tapped. Defaults to an empty closure.
    /// - Returns: An `AlertButton` with the given text and cancel role.
    @available(*, deprecated, message: "use `cancel` with String instead of Text")
    static func cancel(_ text: Text, action: @escaping () -> Void = {}) -> Self {
        AlertButton(title: text.content ?? "", action: action)
            .role(.cancel)
    }
    
    /// Creates a destructive alert button with the specified title and action.
    ///
    /// - Parameters:
    ///   - title: The title of the button.
    ///   - action: A closure to execute when the button is tapped. Defaults to an empty closure.
    /// - Returns: An `AlertButton` with the given title and destructive role.
    static func destructive(_ title: String, action: @escaping () -> Void = {}) -> Self {
        AlertButton(title: title, action: action)
            .role(.destructive)
    }
    
    /// Creates a destructive alert button with the specified text and action.
    ///
    /// - Warning: This method is deprecated. Use the `destructive` method with a `String` instead of `Text`.
    /// - Parameters:
    ///   - text: A `Text` object representing the title of the button.
    ///   - action: A closure to execute when the button is tapped. Defaults to an empty closure.
    /// - Returns: An `AlertButton` with the given text and destructive role.
    @available(*, deprecated, message: "use `destructive` with String instead of Text")
    static func destructive(_ text: Text, action: @escaping () -> Void = {}) -> Self {
        AlertButton(title: text.content ?? "", action: action)
            .role(.destructive)
    }
}
