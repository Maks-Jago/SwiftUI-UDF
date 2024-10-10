//===--- Form.swift ----------------------------------------------===//
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

/// A protocol for defining forms that can automatically handle `UpdateFormField` actions.
///
/// Any type conforming to `Form` inherits the ability to handle form field updates without needing to
/// manually define reducers for each field. This is accomplished through the default implementation
/// of the `reduceBasicFormFields` method.
///
/// ## Example
/// When you conform a type to the `Form` protocol, it automatically gains the capability to handle
/// `UpdateFormField` actions:
///
/// ```swift
/// struct ExampleForm: Form {
///     var name: String = ""
///     var age: Int = 0
/// }
///
/// // Somewhere in Container of Middleware:
/// store.dispatch(Actions.UpdateFormField<ExampleForm>(keyPath: \.name, value: "John Doe"))
/// // The `name` property of `form` is now updated to "John Doe"
/// ```
public protocol Form: Reducible {}

extension Form {
    /// Automatically reduces `UpdateFormField` actions and assigns the new value to the form field.
    ///
    /// This method handles all actions of type `Actions.UpdateFormField<Self>` and updates the corresponding
    /// field in the conforming form type. If the action is not of type `UpdateFormField`, it does nothing.
    ///
    /// - Parameter action: An action that may or may not be an `UpdateFormField`.
    mutating func reduceBasicFormFields(_ action: some Action) {
        switch action {
        case let action as Actions.UpdateFormField<Self>:
            // Assigns the new value to the form field using the action's keyPath
            action.assignToForm(&self)
            
        default:
            break
        }
    }
}
