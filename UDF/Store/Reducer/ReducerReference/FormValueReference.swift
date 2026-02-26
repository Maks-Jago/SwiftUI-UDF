//===--- FormValueReference.swift --------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

/// A reference that pairs a form field's key path and its containing reducer with a dispatch closure,
/// enabling both value access and modified binding creation.
///
/// `FormValueReference` is obtained through `@dynamicMemberLookup` on a `ReducerReference`
/// when the reducer conforms to `Form`. It allows you to:
/// - Read the current value of a form field via the stored `reducer` and `keyPath`.
/// - Dispatch arbitrary actions through the associated store.
/// - Create `Binding<Value>` instances with dispatch modifiers (`.with(animation:)`, `.with(delay:)`, `.silent()`).
///
/// Swift disambiguates between `Binding<T>` and `FormValueReference<Reducer, T>` based on the
/// expected type at the call site.
///
/// ## Usage
///
/// ```swift
/// // Obtain a FormValueReference to a specific form field
/// let nameRef: FormValueReference<ProfileForm, String> = store.$state.profileForm.name
///
/// // Read the current value
/// let currentName = nameRef.reducer[keyPath: nameRef.keyPath]
///
/// // Dispatch actions
/// nameRef.dispatch(Actions.SubmitProfile(name: currentName))
///
/// // Create a Binding with animation
/// TextField("Name", text: store.$state.profileForm.name.with(animation: .linear))
///
/// // Create a Binding with delay
/// TextField("Search", text: store.$state.searchForm.query.with(delay: 0.3))
///
/// // Create a silent Binding
/// TextField("Token", text: store.$state.settingsForm.apiToken.silent())
/// ```
public final class FormValueReference<Reducer: Form, Value: Equatable & Sendable>: @unchecked Sendable {
    /// The key path to the form field within the reducer.
    public let keyPath: WritableKeyPath<Reducer, Value>

    /// The reducer instance that contains the form field.
    public let reducer: Reducer

    /// A closure that handles the dispatching of actions.
    private let dispatcher: (any Action) -> Void

    /// Initializes a new `FormValueReference` with the specified key path, reducer, and dispatcher.
    ///
    /// - Parameters:
    ///   - keyPath: The key path to the form field within the reducer.
    ///   - reducer: The reducer instance that contains the form field.
    ///   - dispatcher: A closure to handle action dispatching.
    init(
        keyPath: WritableKeyPath<Reducer, Value>,
        reducer: Reducer,
        dispatcher: @escaping (any Action) -> Void
    ) {
        self.keyPath = keyPath
        self.reducer = reducer
        self.dispatcher = dispatcher
    }

    /// Dispatches an action through the associated store.
    ///
    /// - Parameter action: The action to dispatch.
    public func dispatch(_ action: some Action) {
        dispatcher(action)
    }

    // MARK: - Binding with Modifiers

    /// Creates a `Binding` with the specified animation applied to the dispatched update action.
    ///
    /// When the binding's value changes, an `UpdateFormField` action is dispatched with the specified
    /// animation modifier.
    ///
    /// ```swift
    /// TextField("Name", text: store.$state.profileForm.name.with(animation: .linear))
    /// ```
    ///
    /// - Parameter animation: The animation to apply when the binding value changes.
    /// - Returns: A `Binding` whose setter dispatches the update action wrapped with the specified animation.
    public func with(animation: Animation?) -> Binding<Value> {
        Binding {
            self.reducer[keyPath: self.keyPath]
        } set: { value in
            self.dispatcher(Actions.UpdateFormField(keyPath: self.keyPath, value: value).with(animation: animation))
        }
    }

    /// Creates a `Binding` with the specified delay applied to the dispatched update action.
    ///
    /// When the binding's value changes, an `UpdateFormField` action is dispatched after the specified
    /// time interval.
    ///
    /// ```swift
    /// TextField("Search", text: store.$state.searchForm.query.with(delay: 0.3))
    /// ```
    ///
    /// - Parameter interval: The time interval to delay the dispatch.
    /// - Returns: A `Binding` whose setter dispatches the update action after the specified delay.
    public func with(delay interval: TimeInterval) -> Binding<Value> {
        Binding {
            self.reducer[keyPath: self.keyPath]
        } set: { value in
            self.dispatcher(Actions.UpdateFormField(keyPath: self.keyPath, value: value).with(delay: interval))
        }
    }

    /// Creates a `Binding` whose dispatched update action is silenced (suppresses logging).
    ///
    /// When the binding's value changes, an `UpdateFormField` action is dispatched silently,
    /// meaning it will not appear in action logs.
    ///
    /// ```swift
    /// TextField("Token", text: store.$state.settingsForm.apiToken.silent())
    /// ```
    ///
    /// - Returns: A `Binding` whose setter dispatches the update action silently.
    public func silent() -> Binding<Value> {
        Binding {
            self.reducer[keyPath: self.keyPath]
        } set: { value in
            self.dispatcher(Actions.UpdateFormField(keyPath: self.keyPath, value: value).silent())
        }
    }
}
