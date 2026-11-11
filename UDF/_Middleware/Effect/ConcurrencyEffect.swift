//===--- ConcurrencyEffect.swift ------------------------------------------===//
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

/// A protocol that defines an asynchronous effect capable of producing an action for a flow.
///
/// Implement `task(flowId:)` to perform asynchronous work and return an action. Middleware passes the flow identifier when executing
/// the effect and tracks cancellation separately using the identifier supplied to `execute`.
/// To receive compatible middleware dependencies, also conform to `EnvironmentEffect`.
///
/// ## Example of a `ConcurrencyEffect`
///
/// This example demonstrates how to create an asynchronous effect that saves user information using the `SomeMiddleware` environment.
///
/// ```swift
/// private extension SomeMiddleware {
///     struct RevolutInfoSavingEffect: ConcurrencyEffect, EnvironmentEffect {
///         var environment: SomeMiddleware.Environment!
///         let token: String
///         let userId: Int
///         let firstName: String
///         let lastName: String
///         let revolutTag: String
///
///         func task(flowId: AnyHashable) async throws -> any Action {
///             let bankInfo = try await environment.saveRevolutInfo(token, userId, firstName, lastName, revolutTag)
///
///             return ActionGroup {
///                 Actions.DidLoadItem(item: bankInfo, id: flowId)
///                 Actions.LoadPage(id: CashOutMethodsFlow.id)
///             }
///         }
///     }
/// }
/// ```
public protocol ConcurrencyEffect: Sendable {
    /// An asynchronous method that performs a task and returns an action.
    ///
    /// - Parameter flowId: The unique identifier for the flow.
    /// - Returns: An action produced by the asynchronous task.
    func task(flowId: AnyHashable) async throws -> any Action
}

/// A `ConcurrencyEffect` that can read fresh application state through a synchronous closure.
///
/// Implement the inherited `task(flowId:)` method and call `state()` wherever the task needs a fresh snapshot, including after an
/// asynchronous step. Each call synchronously reads the latest committed state without waiting for queued actions to finish.
/// Supply the reader when initializing the effect. Adopt `StateConcurrencyEffectInitializable` to use `init(store:)`.
/// State concurrency effects use the standard concurrency `execute` overloads. To receive compatible middleware dependencies,
/// also conform to `EnvironmentEffect`.
///
/// ## Example of a `StateConcurrencyEffect`
///
/// This example demonstrates how to create an asynchronous effect that loads a user profile using a token stored in the current state.
///
/// ```swift
/// private extension ProfileMiddleware {
///     struct LoadProfileEffect: StateConcurrencyEffectInitializable, EnvironmentEffect {
///         var environment: ProfileMiddleware.Environment!
///         let state: @Sendable () -> AppState
///
///         init(state: @escaping @Sendable () -> AppState) {
///             self.state = state
///         }
///
///         func task(flowId: AnyHashable) async throws -> any Action {
///             guard let token = state().userForm.currentUser?.token else {
///                 throw CancellationError()
///             }
///
///             let profile = try await environment.loadProfile(token: token)
///
///             return Actions.DidLoadItem(item: profile, id: flowId)
///         }
///     }
/// }
/// ```
public protocol StateConcurrencyEffect: ConcurrencyEffect {
    associatedtype State: AppReducer

    /// Reads a fresh state snapshot. Call again after an asynchronous step when updated state is needed.
    var state: @Sendable () -> State { get }
}

/// A state concurrency effect that can be initialized using only a synchronous state reader.
///
/// Implement `init(state:)` to receive the default `init(store:)` initializer, as with `StateEffectInitializable`.
/// To receive middleware dependencies, also conform to `EnvironmentEffect`.
/// Effects with additional required inputs can conform directly to `StateConcurrencyEffect` and provide their own initializer
/// accepting a reader and those inputs.
public protocol StateConcurrencyEffectInitializable: StateConcurrencyEffect {
    /// Creates an effect using the supplied closure as its source of application state.
    ///
    /// Store the reader and call it wherever the task needs current state.
    ///
    /// - Parameter state: The reader used to retrieve fresh state snapshots.
    init(state: @escaping @Sendable () -> State)
}

public extension StateConcurrencyEffectInitializable {
    /// Creates an effect with a synchronous reader backed by the supplied store's `currentState` property.
    ///
    /// Initialization captures the store without reading state, executing the task, or configuring its environment.
    /// For effects that also conform to `EnvironmentEffect`, compatible middleware dependencies are assigned during execution.
    ///
    /// - Parameter store: Any store implementation providing synchronized, synchronous state snapshots.
    init(store: any Store<State>) {
        self.init(state: { [store] in
            store.currentState
        })
    }
}

/// A concrete implementation of `ConcurrencyEffect` that runs an asynchronous block of code to produce an action.
///
/// `ConcurrencyBlockEffect` encapsulates an asynchronous block, allowing you to define custom logic for the effect's task.
/// It conforms to both `ConcurrencyEffect` and `FileFunctionLine`, making it possible to track the source location where the effect was
/// created.
struct ConcurrencyBlockEffect: ConcurrencyEffect, FileFunctionLine {
    /// The asynchronous block to be executed, producing an action.
    let block: @Sendable (AnyHashable) async throws -> any Action

    // Metadata for debugging: file name, function name, and line number.
    var fileName: String
    var functionName: String
    var lineNumber: Int

    /// Executes the asynchronous block with the provided `flowId`.
    ///
    /// - Parameter flowId: The unique identifier for the flow.
    /// - Returns: An action produced by the asynchronous block.
    /// - Throws: An error if the block fails to complete successfully.
    func task(flowId: AnyHashable) async throws -> any Action {
        try await block(flowId)
    }
}
