//===--- ReducerReference.swift -----------------------------------===//
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

/// A class that provides a reference to a reducer, allowing dynamic access and modification of its properties.
///
/// `ReducerReference` is designed to enable dynamic access to nested reducers and bind properties to SwiftUI views.
/// It uses `@dynamicMemberLookup` to provide a convenient syntax for accessing and modifying nested state in the reducer hierarchy.
@dynamicMemberLookup
public class ReducerReference<AppState: AppReducer, Reducer: Reducible>: @unchecked Sendable {
    /// The underlying reducer that this reference points to.
    private(set) var reducer: Reducer

    /// A closure that handles the dispatching of actions.
    var dispatcher: (any Action) -> Void

    /// Provides a projected value, allowing access to the reducer.
    public var projectedValue: Reducer {
        get { self.reducer }
        set { self.reducer = newValue }
    }

    /// Initializes a new `ReducerReference` with the specified reducer and dispatcher.
    ///
    /// - Parameters:
    ///   - reducer: The reducer to be referenced.
    ///   - dispatcher: A closure to handle action dispatching.
    init(reducer: Reducer, dispatcher: @escaping (any Action) -> Void) {
        self.reducer = reducer
        self.dispatcher = dispatcher
    }

    /// Provides dynamic access to nested reducers within the referenced reducer.
    ///
    /// - Parameter keyPath: A key path to a nested reducer within the referenced reducer.
    /// - Returns: A new `ReducerReference` pointing to the nested reducer.
    public subscript<R: Reducible>(dynamicMember keyPath: KeyPath<Reducer, R>) -> ReducerReference<AppState, R> {
        .init(reducer: reducer[keyPath: keyPath], dispatcher: dispatcher)
    }

    /// Provides dynamic access to a `BindableReducer` within the referenced reducer.
    ///
    /// - Parameter keyPath: A writable key path to a `BindableReducer` within the referenced reducer.
    /// - Returns: A `BindableReducerReference` for the specified nested `BindableReducer`.
    public subscript<
        ID: Hashable & Sendable,
        R: Reducible
    >(dynamicMember keyPath: WritableKeyPath<Reducer, BindableReducer<ID, R>>) -> BindableReducerReference<AppState, ID, R> {
        BindableReducerReference(reducer: reducer[keyPath: keyPath], dispatcher: dispatcher)
    }

    /// Provides dynamic access to the `Scope` of a nested reducer.
    ///
    /// - Parameter keyPath: A key path to a nested reducer within the referenced reducer.
    /// - Returns: A `Scope` representing the state of the nested reducer.
    public subscript(dynamicMember keyPath: KeyPath<Reducer, some Reducible>) -> Scope {
        ReducerScope(reducer: reducer[keyPath: keyPath])
    }
}

// MARK: - Extensions for Forms

public extension ReducerReference where Reducer: Form {
    private struct SendableWritableKeyPath<Root, Value>: @unchecked Sendable {
        let value: WritableKeyPath<Root, Value>
    }

    /// Binds a property of the referenced reducer to a SwiftUI view using a key path.
    ///
    /// This allows direct binding of form fields to SwiftUI views. When the bound property is updated, an `UpdateFormField` action is
    /// dispatched.
    ///
    /// - Parameter keyPath: A writable key path to a property of the reducer.
    /// - Returns: A `Binding` that allows the property to be directly modified in SwiftUI.
    subscript<T: Equatable & Sendable>(dynamicMember keyPath: WritableKeyPath<Reducer, T>) -> Binding<T> {
        Binding(
            get: { self.reducer[keyPath: keyPath] },
            set: { value in
                self.dispatcher(Actions.UpdateFormField(keyPath: keyPath, value: value))
            }
        )
    }
    
    /// Provides dynamic access to a form field as a ``FormValueReference``, combining the field's
    /// key path and reducer with the dispatch closure.
    ///
    /// Swift disambiguates this subscript from `Binding<T>` based on the expected type at the call site.
    /// Use ``FormValueReference`` when you need both access to the value and the ability to dispatch
    /// actions, or when you want to create a `Binding` with modifiers (animation, delay, silencing).
    ///
    /// ```swift
    /// // As a typed variable
    /// let nameRef: FormValueReference<ProfileForm, String> = store.$state.profileForm.name
    /// nameRef.dispatch(Actions.SubmitProfile(name: nameRef.reducer[keyPath: nameRef.keyPath]))
    ///
    /// // Chained to create a modified Binding
    /// TextField("Name", text: store.$state.profileForm.name.with(animation: .linear))
    /// ```
    ///
    /// - Parameter keyPath: A writable key path to a property of the form.
    /// - Returns: A ``FormValueReference`` wrapping the field's key path, reducer, and dispatcher.
    subscript<T: Equatable & Sendable>(dynamicMember keyPath: WritableKeyPath<Reducer, T>) -> FormValueReference<Reducer, T> {
        FormValueReference(
            keyPath: keyPath,
            reducer: reducer,
            dispatcher: dispatcher
        )
    }
}
