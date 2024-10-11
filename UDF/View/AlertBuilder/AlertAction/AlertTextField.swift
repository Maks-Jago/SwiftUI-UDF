//===--- AlertTextField.swift ------------------------------------===//
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

/// A customizable text field for alerts, conforming to `AlertAction` and `View`.
///
/// `AlertTextField` allows for user text input within an alert context. It includes options to configure the title,
/// text binding, text input autocapitalization, and the submit label. This component uses a debouncer to manage
/// the input, ensuring efficient updates to the bound text.
///
/// ## Properties:
/// - `title`: The placeholder text for the text field.
/// - `text`: A binding to the string input value.
/// - `textInputAutocapitalization`: An optional `TextInputAutocapitalization` to control capitalization behavior.
/// - `submitLabel`: The `SubmitLabel` used when the keyboard's return key is pressed.
/// - `debouncer`: An internal state object to manage debounced input.
///
/// ## Initializer:
/// - `init(title:text:)`: Creates an `AlertTextField` with the specified title and binding text.
///
/// ## Modifiers:
/// - `textInputAutocapitalization(_:)`: Sets the autocapitalization behavior for the text field.
/// - `submitLabel(_:)`: Sets the submit label for the text field's return key.
///
/// ## Example usage:
/// ```swift
/// AlertBuilder.AlertStyle(
///     title: "Title",
///     text: "Body"
/// ) {
///     AlertButton.default("Reset", action: action)
///     AlertButton.cancel("Cancel")
///     AlertTextField(title: "Input", text: $inputText)
/// }
/// ```
public struct AlertTextField: AlertAction {
    public var title: String
    public var text: Binding<String>
    public var textInputAutocapitalization: TextInputAutocapitalization? = nil
    public var submitLabel: SubmitLabel = .done

    @StateObject private var debouncer: UserInputDebouncer<String>

    public static func == (lhs: AlertTextField, rhs: AlertTextField) -> Bool {
        lhs.title == rhs.title
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }

    /// Creates an `AlertTextField` with a specified title and binding to the input text.
    ///
    /// - Parameters:
    ///   - title: The placeholder text for the text field.
    ///   - text: A binding to the text input value.
    public init(title: String, text: Binding<String>) {
        self.title = title
        self.text = text
        self._debouncer = .init(wrappedValue: .init(defaultValue: text.wrappedValue))
    }

    /// The view body of the `AlertTextField`.
    public var body: some View {
        TextField(title, text: $debouncer.value)
            .textInputAutocapitalization(textInputAutocapitalization)
            .submitLabel(submitLabel)
            .onReceive(debouncer.$debouncedValue.dropFirst()) { value in
                self.text.wrappedValue = value
            }
            .onChange(of: text.wrappedValue) { newValue in
                if debouncer.value.isEmpty, !newValue.isEmpty {
                    debouncer.value = newValue
                }
            }
    }
}

extension AlertTextField: View {}

// MARK: - Modifiers
public extension AlertTextField {
    /// Sets the autocapitalization behavior for the text field and returns a new `AlertTextField`.
    ///
    /// - Parameter textInputAutocapitalization: The autocapitalization behavior for the text input.
    /// - Returns: A modified `AlertTextField` with the specified autocapitalization.
    func textInputAutocapitalization(_ textInputAutocapitalization: TextInputAutocapitalization?) -> AlertTextField {
        mutate { field in
            field.textInputAutocapitalization = textInputAutocapitalization
        }
    }

    /// Sets the submit label for the text field's return key and returns a new `AlertTextField`.
    ///
    /// - Parameter submitLabel: The `SubmitLabel` to use for the keyboard's return key.
    /// - Returns: A modified `AlertTextField` with the specified submit label.
    func submitLabel(_ submitLabel: SubmitLabel) -> AlertTextField {
        mutate { field in
            field.submitLabel = submitLabel
        }
    }
}
