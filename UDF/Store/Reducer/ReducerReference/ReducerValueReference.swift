//===--- ReducerValueReference.swift ----------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

/// A lightweight wrapper that pairs a read-only value with the ability to dispatch actions
/// and create modified bindings.
///
/// `ReducerValueReference` is obtained through `@dynamicMemberLookup` on a `ReducerReference`
/// when the reducer conforms to `Form`. It provides direct access to a form field's current value
/// while also carrying the dispatch closure, enabling you to read the value and dispatch actions
/// derived from it.
///
/// Additionally, it supports creating `Binding<Value>` instances with dispatch modifiers
/// (animation, delay, silencing) via the `.with(...)` and `.silenced()` methods:
///
/// ```swift
/// // Get a value reference
/// let nameRef: ReducerValueReference<String> = store.$state.profileForm.name
///
/// // Read the current value
/// let currentName = nameRef.value
///
/// // Dispatch actions using the value
/// nameRef.dispatch(Actions.SubmitProfile(name: nameRef.value))
///
/// // Create a Binding with animation
/// let animatedBinding: Binding<String> = store.$state.profileForm.name.with(animation: .linear)
///
/// // Create a Binding with multiple modifiers
/// let customBinding = store.$state.profileForm.name.with(.animation(.easeIn), .delay(0.3))
/// ```
///
/// Swift disambiguates between `Binding<T>`, `WritableKeyPath<Reducer, T>`, and
/// `ReducerValueReference<T>` based on the type annotation at the call site.
public final class ReducerValueReference<Reducer: Form, Value: Equatable & Sendable>: @unchecked Sendable {
    /// The current value of the form field.
    public let keyPath: WritableKeyPath<Reducer, Value>
    
    public let reducer: Reducer

    /// A closure that handles the dispatching of actions.
    private let dispatcher: (any Action) -> Void

    /// Initializes a new `ReducerValueReference` with the specified value, dispatcher, and action factory.
    ///
    /// - Parameters:
    ///   - value: The current value of the form field.
    ///   - dispatcher: A closure to handle action dispatching.
    ///   - makeUpdateAction: A closure that creates the appropriate update action for a given new value.
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
    /// ```swift
    /// TextField("Search", text: store.$state.searchForm.query.with(delay: 0.3))
    /// ```
    ///
    /// - Parameter delay: The time interval to delay the dispatch.
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
    /// ```swift
    /// TextField("Token", text: store.$state.settingsForm.apiToken.silenced())
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
