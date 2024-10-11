//===--- AppReducer+Runtime.swift --------------------------------===//
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
import Runtime

/// An internal utility used to perform dynamic runtime-based operations on reducers, such as initial setup and state reduction.
///
/// `RuntimeReducing` provides methods for:
/// - Performing initial setup of reducers through reflection.
/// - Reducing actions that affect the application state.
/// - Handling nested reducers by traversing properties using Swift's `Runtime` library.
///
/// **Note:** This utility relies on the Swift `Runtime` library to inspect types and their properties, allowing reducers to be manipulated
/// dynamically.
enum RuntimeReducing {
    // MARK: - Initial Setup

    /// Performs the initial setup of a root reducer by inspecting its properties and calling their initial setup methods.
    ///
    /// - Parameter rootReducer: A mutable reference to the root reducer conforming to `AppReducer`.
    static func initialSetup<R: AppReducer>(reducer rootReducer: inout R) {
        guard let info = try? typeInfo(of: R.self) else {
            return
        }

        for property in info.properties {
            guard let reducer = try? property.get(from: rootReducer) as? Reducing else {
                continue
            }

            var mutableReducer = tryToCallInitialSetup(reducer, rootReducer: rootReducer)

            initialSetup(reducer: &mutableReducer, nestedReducerType: property.type, rootReducer: rootReducer)
            try? property.set(value: mutableReducer, on: &rootReducer)
        }
    }

    /// Attempts to call the `initialSetup` method on a reducer that conforms to `InitialSetup`.
    ///
    /// - Parameters:
    ///   - reducer: The reducer to be initialized.
    ///   - rootReducer: The root reducer containing the state.
    /// - Returns: A `Reducing` instance that has been updated through its initial setup.
    private static func tryToCallInitialSetup(_ reducer: Reducing, rootReducer: some AppReducer) -> Reducing {
        func callInitialSetup<I: InitialSetup>(_ reducer: I, rootReducer: some AppReducer) -> Reducing {
            var mutableReducer = reducer
            mutableReducer.initialSetup(with: rootReducer as! I.AppState)
            return mutableReducer
        }

        var mutableReducer = reducer
        if let initialSetup = mutableReducer as? any InitialSetup {
            mutableReducer = callInitialSetup(initialSetup, rootReducer: rootReducer)
        }

        return mutableReducer
    }

    /// Recursively performs the initial setup for nested reducers within a root reducer.
    ///
    /// - Parameters:
    ///   - reducer: A mutable reference to the nested reducer.
    ///   - nestedReducerType: The type of the nested reducer.
    ///   - rootReducer: A reference to the root reducer containing the state.
    private static func initialSetup(reducer: inout Reducing, nestedReducerType: Any.Type, rootReducer: some AppReducer) {
        guard let info = try? typeInfo(of: nestedReducerType) else {
            return
        }

        for property in info.properties {
            if var mutableReducer = try? property.get(from: reducer) as? Reducing {
                mutableReducer = tryToCallInitialSetup(mutableReducer, rootReducer: rootReducer)

                initialSetup(reducer: &mutableReducer, nestedReducerType: property.type, rootReducer: rootReducer)
                try? property.set(value: mutableReducer, on: &reducer)
            }
        }
    }

    // MARK: - Reducing Actions

    /// Reduces an action within a root reducer and all of its nested reducers.
    ///
    /// - Parameters:
    ///   - action: The action to be reduced.
    ///   - rootReducer: A mutable reference to the root reducer.
    /// - Returns: A Boolean value indicating whether the state was mutated.
    static func bindableReduce<R>(_ action: some Action, reducer rootReducer: inout R) -> Bool {
        if var formable = rootReducer as? any Form {
            formable.reduceBasicFormFields(action)
            rootReducer = formable as! R
        }

        if var reducing = rootReducer as? Reducing {
            reducing.reduce(action)
            _ = reduce(action, reducer: &reducing, type: R.self)
            rootReducer = reducing as! R
        }

        return reduce(action, reducer: &rootReducer)
    }

    /// Recursively reduces an action within the specified reducer and its nested reducers.
    ///
    /// - Parameters:
    ///   - action: The action to be reduced.
    ///   - rootReducer: A mutable reference to the root reducer.
    /// - Returns: A Boolean value indicating whether the state was mutated.
    static func reduce<R>(_ action: some Action, reducer rootReducer: inout R) -> Bool {
        guard let info = try? typeInfo(of: R.self) else {
            return false
        }

        var mutated = false

        for property in info.properties {
            guard let reducer = try? property.get(from: rootReducer) as? Reducing else {
                continue
            }

            var mutableReducer = reducer
            mutableReducer.reduce(action)

            if var formable = mutableReducer as? any Form {
                formable.reduceBasicFormFields(action)
                mutableReducer = formable
            }

            if reduce(action, reducer: &mutableReducer, type: property.type) {
                mutated = true
            }

            if !mutableReducer.isEqual(reducer) {
                try? property.set(value: mutableReducer, on: &rootReducer)
                mutated = true
            }
        }

        return mutated
    }

    /// Reduces an action within a nested reducer of a given type.
    ///
    /// - Parameters:
    ///   - action: The action to be reduced.
    ///   - reducer: A mutable reference to the nested reducer.
    ///   - type: The type of the nested reducer.
    /// - Returns: A Boolean value indicating whether the state was mutated.
    static func reduce(_ action: some Action, reducer: inout Reducing, type: Any.Type) -> Bool {
        guard let info = try? typeInfo(of: type) else {
            return false
        }
        var mutated = false

        for property in info.properties {
            if var nestedReducer = try? property.get(from: reducer) as? Reducing {
                if reduce(action, reducer: &nestedReducer, type: property.type) {
                    if var wrapper = reducer as? WrappedReducer {
                        wrapper.reducer = nestedReducer
                    } else {
                        try? property.set(value: nestedReducer, on: &reducer)
                    }
                    mutated = true
                }

                var mutableReducer = nestedReducer
                mutableReducer.reduce(action)

                if var formable = mutableReducer as? any Form {
                    formable.reduceBasicFormFields(action)
                    mutableReducer = formable
                }

                if !mutableReducer.isEqual(nestedReducer) {
                    try? property.set(value: mutableReducer, on: &reducer)
                    mutated = true
                }
            }
        }

        return mutated
    }
}

public extension Mergeable {
    /// Fills the current instance with values from another instance, and performs a custom mutation on the filled instance.
    ///
    /// - Parameters:
    ///   - value: The instance to fill from.
    ///   - mutate: A closure that allows for additional mutation on the filled instance.
    /// - Returns: A new instance filled with values from the provided `value`.
    func filled(from value: Self, mutate: (_ filledValue: inout Self, _ oldValue: Self) -> Void) -> Self {
        var mutableSelf = self
        do {
            let info = try typeInfo(of: Self.self)

            for property in info.properties {
                let newValue = try property.get(from: value)
                try property.set(value: newValue, on: &mutableSelf)
            }

        } catch {
            return value
        }

        mutate(&mutableSelf, self)
        return mutableSelf
    }
}
