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

// MARK: - Middleware Registration

/// Discovering and calling ``MiddlewareRegistering`` conformers mounted in the app state.
///
/// Kept apart from the reducer machinery above: registration is a separate concern that the store
/// performs once at launch, and it reads the reducer graph without ever mutating it.
extension RuntimeReducing {
    /// Registers the middleware of every reducer in the app state that conforms to `MiddlewareRegistering`.
    ///
    /// Only the app state's own properties are inspected. A feature module mounts its state directly in the
    /// app state, so that is the only place a conformer can appear, and walking the whole reducer graph to
    /// confirm it would cost launch time for nothing.
    ///
    /// - Parameters:
    ///   - rootReducer: The root reducer to inspect.
    ///   - store: The store to register middleware with.
    static func registerMiddlewares<R: AppReducer>(reducer rootReducer: R, registrar: FeatureMiddlewareRegistrar<R>) {
        guard let info = try? typeInfo(of: R.self) else {
            return
        }

        for property in info.properties {
            guard let reducer = try? property.get(from: rootReducer) as? Reducing else {
                continue
            }

            tryToRegisterMiddlewares(reducer, registrar: registrar)

            #if DEBUG
                assertNoNestedRegistering(in: reducer, ofType: property.type, mountedAt: property.name)
            #endif
        }
    }

    /// Attempts to register middleware for a reducer that conforms to `MiddlewareRegistering`.
    ///
    /// - Parameters:
    ///   - reducer: The reducer to test for conformance.
    ///   - store: The store to register middleware with.
    private static func tryToRegisterMiddlewares<R: AppReducer>(_ reducer: Reducing, registrar: FeatureMiddlewareRegistrar<R>) {
        func registerMiddlewares<M: MiddlewareRegistering>(_ reducer: M, registrar: FeatureMiddlewareRegistrar<R>) {
            M.registerMiddlewares(in: registrar as! FeatureMiddlewareRegistrar<M.AppState>)
        }

        if let registering = reducer as? any MiddlewareRegistering {
            registerMiddlewares(registering, registrar: registrar)
        }
    }

    #if DEBUG
        /// Traps on a `MiddlewareRegistering` conformer mounted below the app state's own properties.
        ///
        /// Registration visits only the app state's properties, so a nested conformer is never called and its
        /// middleware never subscribed. Nothing about that failure is visible at runtime, which makes it
        /// expensive to diagnose. This walk exists purely to turn that silence into a message while
        /// developing, and is compiled out of release builds.
        ///
        /// - Parameters:
        ///   - reducer: The reducer whose properties are inspected.
        ///   - reducerType: The type of that reducer.
        ///   - path: The property path walked so far, used to point at the offending mount.
        private static func assertNoNestedRegistering(in reducer: Reducing, ofType reducerType: Any.Type, mountedAt path: String) {
            guard let info = try? typeInfo(of: reducerType) else {
                return
            }

            for property in info.properties {
                guard let nested = try? property.get(from: reducer) as? Reducing else {
                    continue
                }

                let nestedPath = "\(path).\(property.name)"

                if nested is any MiddlewareRegistering {
                    assertionFailure(
                        """
                        \(type(of: nested)) conforms to MiddlewareRegistering but is mounted at '\(nestedPath)'.
                        Middleware registration visits only the app state's own properties, so this reducer's \
                        middleware will never be subscribed. Mount it directly in the app state instead.
                        """
                    )
                }

                assertNoNestedRegistering(in: nested, ofType: property.type, mountedAt: nestedPath)
            }
        }
    #endif
}
