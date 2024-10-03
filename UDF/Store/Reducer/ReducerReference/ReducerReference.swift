//===--- ReducerReference.swift -----------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

/// A class that provides a reference to a reducer, allowing dynamic access and modification of its properties.
///
/// `ReducerReference` is designed to enable dynamic access to nested reducers and bind properties to SwiftUI views.
/// It uses `@dynamicMemberLookup` to provide a convenient syntax for accessing and modifying nested state in the reducer hierarchy.
@dynamicMemberLookup
public class ReducerReference<AppState: AppReducer, Reducer: Reducible> {
    
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
    public subscript<C: BindableContainer, R: Reducible>(dynamicMember keyPath: WritableKeyPath<Reducer, BindableReducer<C, R>>) -> BindableReducerReference<AppState, C, R> {
        BindableReducerReference(reducer: reducer[keyPath: keyPath], dispatcher: dispatcher)
    }
    
    /// Provides dynamic access to the `Scope` of a nested reducer.
    ///
    /// - Parameter keyPath: A key path to a nested reducer within the referenced reducer.
    /// - Returns: A `Scope` representing the state of the nested reducer.
    public subscript<R: Reducible>(dynamicMember keyPath: KeyPath<Reducer, R>) -> Scope {
        ReducerScope(reducer: reducer[keyPath: keyPath])
    }
}

// MARK: - Extensions for Forms

extension ReducerReference where Reducer: Form {
    
    /// Binds a property of the referenced reducer to a SwiftUI view using a key path.
    ///
    /// This allows direct binding of form fields to SwiftUI views. When the bound property is updated, an `UpdateFormField` action is dispatched.
    ///
    /// - Parameter keyPath: A writable key path to a property of the reducer.
    /// - Returns: A `Binding` that allows the property to be directly modified in SwiftUI.
    public subscript<T: Equatable>(dynamicMember keyPath: WritableKeyPath<Reducer, T>) -> Binding<T> {
        Binding(
            get: { self.reducer[keyPath: keyPath] },
            set: { value in
                self.dispatcher(Actions.UpdateFormField(keyPath: keyPath, value: value))
            }
        )
    }
}
