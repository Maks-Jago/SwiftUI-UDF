//===--- AppReducer.swift ----------------------------------------===//
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

/// A protocol that defines the base structure for application reducers.
///
/// `AppReducer` combines `Equatable` and `Scope` to represent a unit of state in the application that can be modified
/// through actions. Conforming types must be equatable, allowing changes to the state to be tracked efficiently.
///
/// ## Example
/// ```swift
/// struct MyAppState: AppReducer {
///     // MARK: - Root
///     var rootForm = RootForm()
///     var rootFlow = RootFlow()
///
///     // MARK: - Storage
///     var allUsers = AllUsers()
/// }
/// ```
///
/// By conforming to `AppReducer`, the `MyAppState` structure can now participate in state management, allowing
/// it to handle actions and perform initial setups.
public protocol AppReducer: Equatable, Scope {}

// MARK: - AppReducer Extension
extension AppReducer {
    /// Reduces the current state by applying the provided action.
    ///
    /// This method uses `RuntimeReducing` to perform the reduction process, updating the state based on the given action.
    /// Conforming types do not need to manually implement this method, as it is handled dynamically at runtime.
    ///
    /// - Parameter action: An action that will potentially modify the state.
    /// - Returns: A Boolean value indicating whether the state was changed.
    mutating func reduce(_ action: some Action) -> Bool {
        RuntimeReducing.reduce(action, reducer: &self)
    }

    /// Performs the initial setup for the reducer.
    ///
    /// This method leverages `RuntimeReducing` to initialize the reducer's state. It is automatically called when
    /// setting up the application state, ensuring that the reducer is ready to handle actions.
    mutating func initialSetup() {
        RuntimeReducing.initialSetup(reducer: &self)
    }
}
