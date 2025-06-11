//===--- NotificationTextField.swift ----------------------------------===//
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

/// A customizable text field for notifications, conforming to `NotificationAction` and `View`.
///
/// `NotificationTextField` allows for user text input within a notification context. It includes options to configure the title,
/// text binding, text input autocapitalization, and the submit label. This component uses a debouncer to manage
/// the input, ensuring efficient updates to the bound text.
///
/// This is a direct migration from `AlertTextField` with the same API surface, ensuring compatibility
/// with existing code while extending support to all notification styles.
///
/// ## Properties:
/// - `title`: The placeholder text for the text field.
/// - `text`: A binding to the string input value.
/// - `textInputAutocapitalization`: An optional `TextInputAutocapitalization` to control capitalization behavior.
/// - `submitLabel`: The `SubmitLabel` used when the keyboard's return key is pressed.
///
/// ## Initializer:
/// - `init(title:text:)`: Creates a `NotificationTextField` with the specified title and binding text.
///
/// ## Modifiers:
/// - `textInputAutocapitalization(_:)`: Sets the autocapitalization behavior for the text field.
/// - `submitLabel(_:)`: Sets the submit label for the text field's return key.
///
/// ## Example usage:
/// ```swift
/// @State private var inputText = ""
/// 
/// NotificationTextField(title: "Enter name", text: $inputText)
///     .textInputAutocapitalization(.words)
///     .submitLabel(.done)
/// ```
public struct NotificationTextField: NotificationAction {
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
    private let initialValue: String
    
    // MARK: - Equatable Implementation
    /// Checks if two `NotificationTextField` instances are equal by comparing their titles.
    /// 
    /// Note: Text bindings cannot be compared directly, so only the title is used for equality.
    nonisolated public static func == (lhs: NotificationTextField, rhs: NotificationTextField) -> Bool {
        lhs.title == rhs.title
    }
    
    // MARK: - Hashable Implementation
    /// Hashes the essential properties of the `NotificationTextField`.
    /// 
    /// Note: Text bindings cannot be hashed, so only the title is used.
    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }
    
    // MARK: - Initializers
    /// Creates a `NotificationTextField` with a specified title and binding to the input text.
    ///
    /// - Parameters:
    ///   - title: The placeholder text for the text field.
    ///   - text: A binding to the text input value.
    public init(title: String, text: Binding<String>) {
        self.title = title
        self.text = text
        self.initialValue = text.wrappedValue
    }
    
    // MARK: - View Implementation
    /// The view body of the `NotificationTextField`.
    /// 
    /// This creates an internal text field implementation that handles debouncing
    /// and proper integration with the notification system.
    public var body: some View {
        NotificationTextFieldInternal(
            title: title,
            text: text,
            textInputAutocapitalization: textInputAutocapitalization,
            submitLabel: submitLabel,
            initialValue: initialValue
        )
    }
}

// MARK: - Internal Implementation
/// Internal implementation of the text field with debouncing support.
private struct NotificationTextFieldInternal: View {
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
extension NotificationTextField: View {}

// MARK: - Action Classification
extension NotificationTextField: @preconcurrency NotificationActionClassification {
    var actionType: NotificationActionType {
        .textField
    }
    
    var capabilities: NotificationActionCapability {
        [.requiresInteraction, .capturesTextInput]
    }
}

// MARK: - Modifiers
public extension NotificationTextField {
    /// Sets the autocapitalization behavior for the text field and returns a new `NotificationTextField`.
    ///
    /// - Parameter textInputAutocapitalization: The autocapitalization behavior for the text input.
    /// - Returns: A modified `NotificationTextField` with the specified autocapitalization.
    /// 
    /// ## Example:
    /// ```swift
    /// NotificationTextField(title: "Name", text: $name)
    ///     .textInputAutocapitalization(.words)
    /// ```
    #if os(iOS)
    func textInputAutocapitalization(_ textInputAutocapitalization: TextInputAutocapitalization?) -> NotificationTextField {
        mutate { field in
            field.textInputAutocapitalization = textInputAutocapitalization
        }
    }
    #endif
    
    /// Sets the submit label for the text field's return key and returns a new `NotificationTextField`.
    ///
    /// - Parameter submitLabel: The `SubmitLabel` to use for the keyboard's return key.
    /// - Returns: A modified `NotificationTextField` with the specified submit label.
    /// 
    /// ## Example:
    /// ```swift
    /// NotificationTextField(title: "Search", text: $query)
    ///     .submitLabel(.search)
    /// ```
    func submitLabel(_ submitLabel: SubmitLabel) -> NotificationTextField {
        mutate { field in
            field.submitLabel = submitLabel
        }
    }
}

// MARK: - Validation
public extension NotificationTextField {
    /// Validates that the text field has a valid configuration.
    /// 
    /// - Returns: True if the text field is properly configured.
    nonisolated var isValid: Bool {
        !title.isEmpty
    }
    
    /// Returns a description of any validation issues with this text field.
    /// 
    /// - Returns: An array of validation error messages, empty if valid.
    nonisolated var validationErrors: [String] {
        var errors: [String] = []
        
        if title.isEmpty {
            errors.append("Text field title cannot be empty")
        }
        
        return errors
    }
}
