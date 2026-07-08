//===--- DialogTextField.swift ----------------------------------===//
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

/// A customizable text field for dialogs, conforming to `DialogAction` and `View`.
///
/// `DialogTextField` allows for user text input within a dialog context. It includes options to configure the title,
/// text binding, text input autocapitalization, and the submit label. This component uses a debouncer to manage
/// the input, ensuring efficient updates to the bound text.
///
///
/// ## Properties:
/// - `title`: The placeholder text for the text field.
/// - `text`: A binding to the string input value.
/// - `textInputAutocapitalization`: An optional `TextInputAutocapitalization` to control capitalization behavior.
/// - `submitLabel`: The `SubmitLabel` used when the keyboard's return key is pressed.
///
/// ## Initializer:
/// - `init(title:text:)`: Creates a `DialogTextField` with the specified title and binding text.
///
/// ## Modifiers:
/// - `textInputAutocapitalization(_:)`: Sets the autocapitalization behavior for the text field.
/// - `submitLabel(_:)`: Sets the submit label for the text field's return key.
///
/// ## Example usage:
/// ```swift
/// @State private var inputText = ""
/// 
/// DialogTextField(title: "Enter name", text: $inputText)
///     .textInputAutocapitalization(.words)
///     .submitLabel(.done)
/// ```
public struct DialogTextField: DialogAction, AlertDialogComponent {
    /// The placeholder text for the text field.
    public var title: String
    
    /// A binding to the text input value.
    public var text: Binding<String>
    
    /// The autocapitalization behavior for text input (iOS only).
    #if os(iOS)
    public var textInputAutocapitalization: TextInputAutocapitalization?
    #endif
    
    /// The submit label for the keyboard's return key.
    public var submitLabel: SubmitLabel = .done
    
    /// The initial value of the text field (stored for internal use).
    let initialValue: String
    
    // MARK: - Equatable Implementation
    /// Checks if two `DialogTextField` instances are equal by comparing their titles and initial values.
    ///
    /// Note: Text bindings cannot be compared directly, so the title and initial value are used for equality.
    nonisolated public static func == (lhs: DialogTextField, rhs: DialogTextField) -> Bool {
        lhs.title == rhs.title &&
        lhs.initialValue == rhs.initialValue
    }
    
    // MARK: - Hashable Implementation
    /// Hashes the essential properties of the `DialogTextField`.
    ///
    /// Note: Text bindings cannot be hashed, so the title and initial value are used.
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(initialValue)
    }
    
    // MARK: - Initializers
    /// Creates a `DialogTextField` with a specified title and binding to the input text.
    ///
    /// - Parameters:
    ///   - title: The placeholder text for the text field.
    ///   - text: A binding to the text input value.
    nonisolated public init(title: String, text: Binding<String>) {
        self.title = title
        self.text = text
        self.initialValue = text.wrappedValue
    }
    
    // MARK: - View Implementation
    /// The view body of the `DialogTextField`.
    ///
    /// This creates an internal text field implementation that handles debouncing
    /// and proper integration with the dialog system.
    public var body: some View {
    #if os(iOS)
        DialogTextFieldInternal(
            title: title,
            text: text,
            textInputAutocapitalization: textInputAutocapitalization,
            submitLabel: submitLabel,
            initialValue: initialValue
        )
    #else
        DialogTextFieldInternal(
            title: title,
            text: text,
            submitLabel: submitLabel,
            initialValue: initialValue
        )
    #endif
    }
}

// MARK: - Internal Implementation
/// Internal implementation of the text field with debouncing support.
private struct DialogTextFieldInternal: View {
    let title: String
    let text: Binding<String>
    #if os(iOS)
    let textInputAutocapitalization: TextInputAutocapitalization?
    #endif
    let submitLabel: SubmitLabel
    let initialValue: String
    
    @StateObject private var debouncer = UserInputDebouncer<String>(defaultValue: "")
    
    var body: some View {
        TextField(title, text: $debouncer.value)
            #if os(iOS)
            .textInputAutocapitalization(textInputAutocapitalization)
            #endif
            .submitLabel(submitLabel)
            .onAppear {
                if debouncer.value.isEmpty {
                    debouncer.value = initialValue
                }
            }
            .onReceive(debouncer.$debouncedValue.dropFirst()) { value in
                text.wrappedValue = value
            }
            .onChange(of: text.wrappedValue) { newValue in
                if debouncer.value.isEmpty, !newValue.isEmpty {
                    debouncer.value = newValue
                }
            }
    }
}

// MARK: - View Conformance
extension DialogTextField: View {}

// MARK: - Action Classification
extension DialogTextField: @preconcurrency DialogActionClassification {
    var actionType: DialogActionType {
        .textField
    }
    
    var capabilities: DialogActionCapability {
        [.requiresInteraction, .capturesTextInput]
    }
}

// MARK: - Modifiers
public extension DialogTextField {
    /// Sets the autocapitalization behavior for the text field and returns a new `DialogTextField`.
    ///
    /// - Parameter textInputAutocapitalization: The autocapitalization behavior for the text input.
    /// - Returns: A modified `DialogTextField` with the specified autocapitalization.
    ///
    /// ## Example:
    /// ```swift
    /// DialogTextField(title: "Name", text: $name)
    ///     .textInputAutocapitalization(.words)
    /// ```
    #if os(iOS)
    func textInputAutocapitalization(_ textInputAutocapitalization: TextInputAutocapitalization?) -> DialogTextField {
        mutate { field in
            field.textInputAutocapitalization = textInputAutocapitalization
        }
    }
    #endif
    
    /// Sets the submit label for the text field's return key and returns a new `DialogTextField`.
    ///
    /// - Parameter submitLabel: The `SubmitLabel` to use for the keyboard's return key.
    /// - Returns: A modified `DialogTextField` with the specified submit label.
    ///
    /// ## Example:
    /// ```swift
    /// DialogTextField(title: "Search", text: $query)
    ///     .submitLabel(.search)
    /// ```
    func submitLabel(_ submitLabel: SubmitLabel) -> DialogTextField {
        mutate { field in
            field.submitLabel = submitLabel
        }
    }
}
