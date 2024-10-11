//===--- SourceOfTruth.swift -----------------------------------------===//
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

/// A property wrapper used to represent the central source of truth for the application state.
/// It allows for dynamic member lookup to access reducers and bindable containers within the `AppState`.
///
/// The `SourceOfTruth` maintains a reference to the store and allows interaction with the reducers through subscripts.
@propertyWrapper
@dynamicMemberLookup
public final class SourceOfTruth<AppState: AppReducer> {
    /// The current value of the application state.
    public var wrappedValue: AppState

    /// A reference to the store that holds and manages the application state.
    private unowned var store: Optional<any Store<AppState>>

    /// Initializes the `SourceOfTruth` with the given state and store.
    /// - Parameters:
    ///   - wrappedValue: The initial state of the application.
    ///   - store: An optional reference to the store managing the application state.
    init(wrappedValue: AppState, store: (any Store<AppState>)?) {
        self.wrappedValue = wrappedValue
        self.store = store
    }

    /// Provides a reference to the `SourceOfTruth`.
    public var projectedValue: SourceOfTruth<AppState> { self }

    /// Provides dynamic member lookup for `BindableReducer` properties within the `AppState`.
    /// - Parameter keyPath: A key path to a `BindableReducer` in the application state.
    /// - Returns: A `BindableReducerReference` to the specified `BindableReducer`.
    public subscript<
        C: BindableContainer,
        R: Reducible
    >(dynamicMember keyPath: WritableKeyPath<AppState, BindableReducer<C, R>>) -> BindableReducerReference<AppState, C, R> {
        BindableReducerReference(reducer: wrappedValue[keyPath: keyPath]) { [unowned store] action in
            store?.dispatch(action, priority: .userInteractive)
        }
    }

    /// Provides dynamic member lookup for `Reducer` properties within the `AppState`.
    /// - Parameter keyPath: A key path to a `Reducer` in the application state.
    /// - Returns: A `ReducerReference` to the specified `Reducer`.
    public subscript<R: Reducible>(dynamicMember keyPath: KeyPath<AppState, R>) -> ReducerReference<AppState, R> {
        ReducerReference(reducer: wrappedValue[keyPath: keyPath]) { [unowned store] action in
            store?.dispatch(action, priority: .userInteractive)
        }
    }

    /// Provides dynamic member lookup for `Scope` properties within the `AppState`.
    /// - Parameter keyPath: A key path to a `Reducer` in the application state.
    /// - Returns: A `Scope` representing the specified `Reducer`.
    public subscript(dynamicMember keyPath: KeyPath<AppState, some Reducible>) -> Scope {
        ReducerScope(reducer: wrappedValue[keyPath: keyPath])
    }
}

extension SourceOfTruth: Equatable {
    /// Compares two `SourceOfTruth` instances for equality.
    /// - Parameters:
    ///   - lhs: The left-hand side `SourceOfTruth` instance.
    ///   - rhs: The right-hand side `SourceOfTruth` instance.
    /// - Returns: A Boolean value indicating whether the two instances are equal.
    public static func == (lhs: SourceOfTruth<AppState>, rhs: SourceOfTruth<AppState>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}
