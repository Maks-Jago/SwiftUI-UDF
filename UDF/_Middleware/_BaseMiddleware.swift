//===--- BaseMiddleware.swift --------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Combine
import Foundation
import os

/// `_BaseMiddleware` is an open class that serves as the base for creating middleware components
/// in the UDF architecture. Middleware is responsible for handling side effects and can process actions
/// and perform asynchronous operations.
///
/// This class is generic over a `State` type that conforms to `AppReducer`.
open class _BaseMiddleware<State: AppReducer>: _Middleware, @unchecked Sendable {
    /// The store that this middleware interacts with. It holds the state of the application.
    public var store: any Store<State>

    /// The dispatch queue used to execute asynchronous operations.
    public var queue: DispatchQueue

    // MARK: - Initialization

    /// Initializes the middleware with a store and a queue.
    ///
    /// - Parameters:
    ///   - store: The store that holds the state of the application.
    ///   - queue: The dispatch queue for running asynchronous tasks.
    public required init(store: some Store<State>, queue: DispatchQueue) {
        self.store = store
        self.queue = queue
    }

    // MARK: - Middleware Status

    /// Returns the current status of the middleware. The default implementation always returns `.active`.
    ///
    /// - Parameter state: The current application state.
    /// - Returns: A `MiddlewareStatus` indicating whether the middleware is active or suspended.
    open func status(for state: State) -> MiddlewareStatus { .active }

    // MARK: - Type Aliases

    /// A closure type used for filtering dispatch actions based on the state and action output.
    ///
    /// - Parameters:
    ///   - state: The current application state.
    ///   - output: The output generated from the action.
    /// - Returns: A Boolean indicating whether the action should be dispatched.
    public typealias DispatchFilter<Output> = (_ state: State, _ output: Output) -> Bool

    /// A closure type used for mapping errors to actions.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for the effect.
    ///   - error: The error that occurred.
    /// - Returns: An action representing the error.
    public typealias ErrorMapper<Id> = @Sendable (_ id: Id, _ error: Error) -> any Action

    /// A dictionary to track ongoing tasks by their unique identifiers, allowing for cancellation.
    public var cancellations: [AnyHashable: CancellableTask] {
        cancellationsBox.withLockUnchecked { box in
            box.cancellations
        }
    }
    
    /// Synchronizes access to the middleware's mutable state.
    ///
    /// This property ensures that operations on the internal data such as reading/writing—are
    /// atomic across different physical threads, preventing data races and memory corruption.
    private let cancellationsBox = OSAllocatedUnfairLock(initialState: CancellationsBox())

    // MARK: - Cancellation

    /// Cancels an ongoing task identified by the specified cancellation ID.
    ///
    /// - Parameter cancellation: The unique identifier for the task to be canceled.
    /// - Returns: A Boolean indicating whether the task was successfully canceled.
    @discardableResult
    open func cancel(by cancellation: some Hashable) -> Bool {
        let anyId = AnyHashable(cancellation)

        guard let cancellableTask = cancellations[anyId] else {
            return false
        }

        cancellableTask.cancel()
        cancellationsBox.withLockUnchecked { box in
            box.removeCancellation(forKey: anyId)
        }
        return true
    }

    /// Cancels all ongoing tasks tracked in the `cancellations` dictionary.
    open func cancelAll() {
        let keys = Array(cancellations.keys)
        for key in keys {
            cancel(by: key)
        }
    }

    // MARK: - Combine

    /// Executes a pure effect and dispatches actions to the store, allowing for cancellation and mapping of actions.
    ///
    /// This method listens to a given `PureEffect` and dispatches actions to the store. It manages the effect lifecycle by allowing
    /// cancellation using an identifier. The effect is subscribed to on the specified `queue`, and upon completion, success, or
    /// cancellation,
    /// the appropriate actions are dispatched to the store.
    ///
    /// This method:
    /// - Subscribes to the effect on the specified `queue`.
    /// - Handles cancellation using the `cancellation` identifier.
    /// - Dispatches actions to the store based on the effect's output.
    ///
    ///
    /// - Parameters:
    ///   - effect: The effect to execute.
    ///   - cancellation: The identifier used to deduplicate and cancel the subscription.
    ///   - mapAction: Transforms emitted actions and cancellation actions before dispatch. Defaults to `{ $0 }`.
    ///   - fileName: The calling file recorded with dispatched actions. Defaults to `#file`.
    ///   - functionName: The calling function recorded with dispatched actions. Defaults to `#function`.
    ///   - lineNumber: The calling line recorded with dispatched actions. Defaults to `#line`.
    ///
    /// - Note: This method uses Combine's `sink` and `handleEvents` to manage the effect's lifecycle, including cancellation and
    /// completion.
    /// - Important: An active subscription with the same cancellation identifier prevents a second subscription.
    open func execute<E>(
        _ effect: E,
        cancellation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect, E.Output == any Action, E.Failure == Never {
        execute(
            effect,
            cancellation: cancellation,
            waitBehavior: .onStart,
            mapAction: mapAction,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    /// Executes a pure effect after assigning compatible middleware dependencies.
    ///
    /// The effect opts into dependency injection by also conforming to `EnvironmentEffect`. If the middleware has no compatible
    /// environment, the effect retains its existing environment. Action mapping, cancellation, and source metadata behave as in
    /// the pure-effect overload of `execute`.
    open func execute<E: PureEffect & EnvironmentEffect>(
        _ effect: E,
        cancellation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E.Output == any Action, E.Failure == Never {
        execute(
            effect.withEnvironment(from: self),
            cancellation: cancellation,
            waitBehavior: .onStart,
            mapAction: mapAction,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    /// Executes an effect that conforms to both `PureEffect` and `ErasableToEffect` and dispatches actions to the store.
    ///
    /// This method serves as an overload of the `execute` method for effects that can be erased to a more generic effect type. It converts
    /// the given effect to an `Effectable` using the `asEffectable` method before executing it.
    ///
    /// This method:
    /// - Obtains the action publisher from the effect's `asEffectable` property.
    /// - Subscribes to the converted publisher on the specified `queue`.
    /// - Maps emitted actions before dispatching them to the store.
    /// - Handles cancellation using the `cancellation` identifier.
    ///
    /// - Parameters:
    ///   - effect: The effect to execute, which conforms to both `PureEffect` and `ErasableToEffect`.
    ///   - cancellation: The identifier used to deduplicate and cancel the subscription.
    ///   - mapAction: Transforms emitted actions and cancellation actions before dispatch. Defaults to `{ $0 }`.
    ///   - fileName: The calling file recorded with dispatched actions. Defaults to `#file`.
    ///   - functionName: The calling function recorded with dispatched actions. Defaults to `#function`.
    ///   - lineNumber: The calling line recorded with dispatched actions. Defaults to `#line`.
    ///
    /// - Note: This method uses Combine's `sink` and `handleEvents` to manage the effect's lifecycle, including cancellation and
    /// completion.
    /// - Important: An active subscription with the same cancellation identifier prevents a second subscription.
    open func execute(
        _ effect: some PureEffect & ErasableToEffect,
        cancellation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        execute(
            effect.asEffectable,
            cancellation: cancellation,
            mapAction: mapAction,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    /// Assigns compatible middleware dependencies before converting an effect to its action publisher.
    ///
    /// The effect opts into dependency injection by also conforming to `EnvironmentEffect`. If the middleware has no compatible
    /// environment, the effect retains its existing environment. Dependencies are configured before evaluating `asEffectable`.
    open func execute(
        _ effect: some PureEffect & ErasableToEffect & EnvironmentEffect,
        cancellation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        execute(
            effect.withEnvironment(from: self).asEffectable,
            cancellation: cancellation,
            mapAction: mapAction,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    /// Executes a state effect using compatible middleware dependencies and dispatches its actions to the store.
    ///
    /// This method assigns a compatible middleware environment before subscribing to the effect. The effect chooses when to read
    /// application state by subscribing to `statePublisher` within `upstream`. If the environments are incompatible, the effect retains
    /// its existing environment.
    ///
    /// This method:
    /// - Assigns compatible middleware dependencies to the effect.
    /// - Allows the effect to read fresh state snapshots at the required points in its publisher pipeline.
    /// - Subscribes to the effect on the specified `queue`.
    /// - Maps emitted actions and handles cancellation using the `cancellation` identifier.
    ///
    /// - Parameters:
    ///   - effect: The effect to execute.
    ///   - cancellation: The identifier used to deduplicate and cancel the subscription.
    ///   - mapAction: Transforms emitted actions and cancellation actions before dispatch. Defaults to `{ $0 }`.
    ///   - fileName: The calling file recorded with dispatched actions. Defaults to `#file`.
    ///   - functionName: The calling function recorded with dispatched actions. Defaults to `#function`.
    ///   - lineNumber: The calling line recorded with dispatched actions. Defaults to `#line`.
    ///
    /// - Note: This method uses Combine's `sink` and `handleEvents` to manage the effect's lifecycle, including cancellation and
    /// completion.
    /// - Important: An active subscription with the same cancellation identifier prevents a second subscription.
    open func execute<Effect: StateEffectable>(
        _ effect: Effect,
        cancellation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where Effect.Output == any Action, Effect.Failure == Never {
        execute(
            effect.withEnvironment(from: self),
            cancellation: cancellation,
            waitBehavior: .onStart,
            mapAction: mapAction,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    /// Runs a pure effect and dispatches the actions accepted by a state-based filter, allowing for cancellation and action mapping.
    ///
    /// This method checks each output against a fresh application state snapshot before dispatch. The required `dispatchFilter`
    /// receives the state and original action, and returns whether that action should proceed to `mapAction` and the store.
    /// The subscription remains active until the publisher completes or is cancelled.
    ///
    /// This method:
    /// - Subscribes to the effect on the specified `queue`.
    /// - Reads a fresh state snapshot for each output and evaluates `dispatchFilter` before mapping the action.
    /// - Maps accepted actions before dispatching them to the store.
    /// - Handles cancellation using the `cancellation` identifier.
    /// - Maps cancellation actions before dispatching them, bypassing `dispatchFilter`.
    ///
    /// - Parameters:
    ///   - effect: The effect whose output is `any Action` and whose failure type is `Never`.
    ///   - cancellation: The identifier used to deduplicate and cancel the subscription.
    ///   - mapAction: Transforms accepted outputs and cancellation actions before dispatch. Defaults to `{ $0 }`.
    ///   - dispatchFilter: A required predicate receiving a fresh state snapshot and the original output action.
    ///     Return `true` to map and dispatch the action, or `false` to discard it.
    ///   - fileName: The calling file recorded with dispatched actions. Defaults to `#file`.
    ///   - functionName: The calling function recorded with dispatched actions. Defaults to `#function`.
    ///   - lineNumber: The calling line recorded with dispatched actions. Defaults to `#line`.
    ///
    /// - Note: A trailing closure with `(state, action)` parameters supplies `dispatchFilter`. When supplying both closures,
    ///   use the explicit `mapAction:` and `dispatchFilter:` argument labels.
    /// - Important: An active subscription with the same cancellation identifier prevents a second subscription.
    open func run<E>(
        _ effect: E,
        cancellation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        dispatchFilter: @escaping DispatchFilter<any Action>,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect, E.Output == any Action, E.Failure == Never {
        execute(
            effect,
            cancellation: cancellation,
            waitBehavior: .onDispatchAction,
            mapAction: mapAction,
            dispatchFilter: dispatchFilter,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    /// Runs a pure effect with compatible middleware dependencies and a state-based dispatch filter.
    ///
    /// The effect opts into dependency injection by also conforming to `EnvironmentEffect`. If the middleware has no compatible
    /// environment, the effect retains its existing environment. The filter receives each original action and a fresh state
    /// snapshot before action mapping, as in the pure-effect overload of `run`.
    open func run<E>(
        _ effect: E,
        cancellation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        dispatchFilter: @escaping DispatchFilter<any Action>,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect & EnvironmentEffect, E.Output == any Action, E.Failure == Never {
        execute(
            effect.withEnvironment(from: self),
            cancellation: cancellation,
            waitBehavior: .onDispatchAction,
            mapAction: mapAction,
            dispatchFilter: dispatchFilter,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    /// Runs a pure effect and dispatches its emitted actions to the store, allowing for cancellation and action mapping.
    ///
    /// This method forwards each output through `mapAction`.
    ///
    /// This method:
    /// - Subscribes to the effect on the specified `queue`.
    /// - Maps each emitted action before dispatching it to the store.
    /// - Handles cancellation using the `cancellation` identifier.
    /// - Maps cancellation actions before dispatching them to the store.
    ///
    /// - Parameters:
    ///   - effect: The effect whose output is `any Action` and whose failure type is `Never`.
    ///   - cancellation: The identifier used to deduplicate and cancel the subscription.
    ///   - mapAction: Transforms emitted actions and cancellation actions before dispatch. Defaults to `{ $0 }`.
    ///   - fileName: The calling file recorded with dispatched actions. Defaults to `#file`.
    ///   - functionName: The calling function recorded with dispatched actions. Defaults to `#function`.
    ///   - lineNumber: The calling line recorded with dispatched actions. Defaults to `#line`.
    ///
    /// - Note: A trailing closure receiving one action supplies `mapAction` and must return the action to dispatch.
    /// - Important: An active subscription with the same cancellation identifier prevents a second subscription.
    open func run<E>(
        _ effect: E,
        cancellation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect, E.Output == any Action, E.Failure == Never {
        execute(
            effect,
            cancellation: cancellation,
            waitBehavior: .onDispatchAction,
            mapAction: mapAction,
            dispatchFilter: nil,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }
    
    /// Runs a pure effect after assigning compatible middleware dependencies.
    ///
    /// The effect opts into dependency injection by also conforming to `EnvironmentEffect`. If the middleware has no compatible
    /// environment, the effect retains its existing environment. Action mapping, cancellation, and source metadata behave as in
    /// the pure-effect overload of `run`.
    open func run<E>(
        _ effect: E,
        cancellation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect & EnvironmentEffect, E.Output == any Action, E.Failure == Never {
        execute(
            effect.withEnvironment(from: self),
            cancellation: cancellation,
            waitBehavior: .onDispatchAction,
            mapAction: mapAction,
            dispatchFilter: nil,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    // MARK: - Concurrency
    /// Executes an asynchronous task with support for cancellation and error handling.
    ///
    /// This method allows for the execution of an asynchronous task. It wraps the task in a `ConcurrencyBlockEffect` to support
    /// cancellation, error mapping, and action mapping.
    ///
    /// This method:
    /// - Starts the asynchronous task with the supplied `flowId`.
    /// - Maps the task's result and cancellation actions using `mapAction`.
    /// - Converts task errors into actions using `mapError`.
    /// - Handles cancellation using the `cancellation` identifier.
    ///
    /// - Parameters:
    ///   - flowId: The flow identifier passed to the task and used when mapping errors.
    ///   - cancellation: The identifier used to deduplicate and cancel the task.
    ///   - mapAction: Transforms result actions and cancellation actions before dispatch. Defaults to `{ $0 }`.
    ///   - mapError: Converts an error and the flow identifier into an action. Defaults to `Actions.Error` using the error's
    ///     localized description and the flow identifier.
    ///   - fileName: The calling file recorded with dispatched actions. Defaults to `#file`.
    ///   - functionName: The calling function recorded with dispatched actions. Defaults to `#function`.
    ///   - lineNumber: The calling line recorded with dispatched actions. Defaults to `#line`.
    ///   - task: The asynchronous closure that receives the flow identifier and returns an action.
    ///
    /// - Note: This method makes use of the `execute` method that handles `ConcurrencyBlockEffect` objects.
    /// - Important: An active task with the same cancellation identifier prevents a second task.
    open func execute(
        flowId: AnyHashable,
        cancellation: some Hashable & Sendable,
        mapAction: @escaping @Sendable (any Action) -> any Action = { $0 },
        mapError: @escaping ErrorMapper<AnyHashable> = { flowId, error in Actions.Error(error: error.localizedDescription, id: flowId) },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line,
        _ task: @escaping @Sendable (AnyHashable) async throws -> any Action
    ) {
        execute(
            effect: ConcurrencyBlockEffect(
                block: task,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            ),
            flowId: flowId,
            cancellation: cancellation,
            mapAction: mapAction,
            mapError: mapError,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    /// Executes a `ConcurrencyEffect` with support for cancellation and error handling.
    ///
    /// This method starts a new asynchronous task, invoking the provided `ConcurrencyEffect`'s `task()` method. It supports cancellation,
    /// mapping of the resulting action, and error handling.
    ///
    /// This method:
    /// - Executes the `ConcurrencyEffect`'s asynchronous `task()` method.
    /// - Maps the task's result and cancellation actions before dispatch.
    /// - Converts task errors into actions using `mapError`.
    /// - Handles cancellation and removes the task's registration when execution finishes.
    ///
    /// - Parameters:
    ///   - effect: The concurrency effect to execute.
    ///   - flowId: The flow identifier passed to the task and used when mapping errors.
    ///   - cancellation: The identifier used to deduplicate and cancel the task.
    ///   - mapAction: Transforms result actions and cancellation actions before dispatch. Defaults to `{ $0 }`.
    ///   - mapError: Converts an error and the flow identifier into an action. Defaults to `Actions.Error` using the error's
    ///     localized description and the flow identifier.
    ///   - fileName: The calling file recorded with dispatched actions. Defaults to `#file`.
    ///   - functionName: The calling function recorded with dispatched actions. Defaults to `#function`.
    ///   - lineNumber: The calling line recorded with dispatched actions. Defaults to `#line`.
    ///
    /// - Important: An active task with the same cancellation identifier prevents a second task.
    open func execute(
        effect: some ConcurrencyEffect,
        flowId: AnyHashable,
        cancellation: some Hashable & Sendable,
        mapAction: @escaping @Sendable (any Action) -> any Action = { $0 },
        mapError: @escaping ErrorMapper<AnyHashable> = { flowId, error in Actions.Error(error: error.localizedDescription, id: flowId) },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        let anyCancellationId = AnyHashable(cancellation)

        // Prevent running the effect if an effect with the same cancellation ID is already in progress
        guard cancellations[anyCancellationId] == nil else {
            return
        }

        // Capture file name, function name, and line number for debugging and logging purposes
        let filePosition: FileFunctionLineDescription = (fileName: fileName, functionName: functionName, lineNumber: lineNumber)
        TestGroup.instance(for: store).enter()

        // Start the task and store the cancellation token
        let task = Task { @Sendable [weak self] in
            do {
                // Execute the effect's task, passing flowId
                let action = try await effect.task(flowId: flowId)

                // Check if the task was cancelled and dispatch appropriate actions
                if Task.isCancelled {
                    self?.dispatch(action: mapAction(Actions.DidCancelEffect(by: cancellation)), filePosition: filePosition)
                } else {
                    self?.dispatch(action: mapAction(action), filePosition: filePosition)
                }

            } catch {
                // Handle errors and task cancellation
                if error is CancellationError {
                    self?.dispatch(action: mapAction(Actions.DidCancelEffect(by: cancellation)), filePosition: filePosition)
                } else if !Task.isCancelled {
                    self?.dispatch(action: mapError(flowId, error), filePosition: filePosition)
                }
            }

            // Remove the task from the cancellations dictionary
            self?.cancellationsBox.withLockUnchecked { box in
                box.removeCancellation(forKey: anyCancellationId)
            }
        }

        // Store the task in the cancellations dictionary for future cancellation
        cancellationsBox.withLockUnchecked { box in
            box.set(cancellable: task, forKey: anyCancellationId)
        }
    }
    
    /// Executes a concurrency effect after assigning compatible middleware dependencies.
    ///
    /// The effect opts into dependency injection by also conforming to `EnvironmentEffect`. If the middleware has no compatible
    /// environment, the effect retains its existing environment. Action mapping, error mapping, cancellation, and source metadata
    /// behave as in the concurrency-effect overload of `execute`.
    open func execute(
        effect: some ConcurrencyEffect & EnvironmentEffect,
        flowId: AnyHashable,
        cancellation: some Hashable & Sendable,
        mapAction: @escaping @Sendable (any Action) -> any Action = { $0 },
        mapError: @escaping ErrorMapper<AnyHashable> = { flowId, error in Actions.Error(error: error.localizedDescription, id: flowId) },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        execute(
            flowId: flowId,
            cancellation: cancellation,
            mapAction: mapAction,
            mapError: mapError,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        ) { flowId in
            try await  effect.withEnvironment(from: self).task(flowId: flowId)
        }
    }

    /// Executes a state concurrency effect with middleware dependencies and a current application state snapshot.
    ///
    /// This method assigns a compatible middleware environment, reads the current state, and passes that snapshot and the flow
    /// identifier to `task(flowId:state:)`. The resulting action is mapped before dispatch. If the store is unavailable when the task
    /// starts, the effect produces a cancellation action.
    ///
    /// This method:
    /// - Assigns compatible middleware dependencies to the effect.
    /// - Reads the current application state when the task starts.
    /// - Invokes the effect's asynchronous `task(flowId:state:)` method.
    /// - Maps result and cancellation actions using `mapAction`, and task errors using `mapError`.
    /// - Handles cancellation using the `cancellation` identifier.
    ///
    /// - Parameters:
    ///   - effect: The state concurrency effect to execute.
    ///   - flowId: The flow identifier passed to the task and used when mapping errors.
    ///   - cancellation: The identifier used to deduplicate and cancel the task.
    ///   - mapAction: Transforms result actions and cancellation actions before dispatch. Defaults to `{ $0 }`.
    ///   - mapError: Converts an error and the flow identifier into an action. Defaults to `Actions.Error` using the error's
    ///     localized description and the flow identifier.
    ///   - fileName: The calling file recorded with dispatched actions. Defaults to `#file`.
    ///   - functionName: The calling function recorded with dispatched actions. Defaults to `#function`.
    ///   - lineNumber: The calling line recorded with dispatched actions. Defaults to `#line`.
    ///
    /// - Important: An active task with the same cancellation identifier prevents a second task.
    open func execute<Effect: StateConcurrencyEffect & Sendable>(
        effect: Effect,
        flowId: AnyHashable,
        cancellation: some Hashable & Sendable,
        mapAction: @escaping @Sendable (any Action) -> any Action = { $0 },
        mapError: @escaping ErrorMapper<AnyHashable> = { flowId, error in Actions.Error(error: error.localizedDescription, id: flowId) },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where Effect.State == State {
        execute(
            flowId: flowId,
            cancellation: cancellation,
            mapAction: mapAction,
            mapError: mapError,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        ) { [weak store] flowId in
            guard let store else {
                throw CancellationError()
            }
            
            return try await effect.withEnvironment(from: self).task(flowId: flowId, state: store.state)
        }
    }
    
    /// A container for the middleware's mutable state, designed to be managed by a synchronization mechanism
    /// 
    /// This class enables the safe retrieval and cancellation of tasks across different threads,
    /// ensuring that internal storage is modified only through the established lock.
    private class CancellationsBox: @unchecked Sendable {
        var cancellations: [AnyHashable: CancellableTask] = [:]
        
        /// Registers a cancellable task or subscription under the specified identifier.
        ///
        /// This method associates an active effect with its cancellation identifier so the middleware can find and cancel it later.
        /// Assigning an existing identifier replaces its current registration.
        ///
        /// This method:
        /// - Associates the supplied cancellable with its identifier.
        /// - Replaces any registration already stored under that identifier.
        ///
        /// - Parameters:
        ///   - cancellable: The task or publisher subscription to register.
        ///   - key: The identifier used to find and cancel the effect.
        ///
        /// - Important: Call this method while holding the middleware's cancellation lock.
        func set(cancellable: CancellableTask, forKey key: AnyHashable) {
            cancellations[key] = cancellable
        }
        
        /// Removes the cancellation registration associated with the specified identifier.
        ///
        /// This method releases the tracked entry when an effect completes or is cancelled, making its identifier available for later work.
        /// If no registration exists for the identifier, the dictionary remains unchanged.
        ///
        /// This method:
        /// - Finds the registration associated with the identifier.
        /// - Removes that registration from the tracked cancellations.
        ///
        /// - Parameters:
        ///   - key: The identifier of the registration to remove.
        ///
        /// - Important: Call this method while holding the middleware's cancellation lock.
        func removeCancellation(forKey key: AnyHashable) {
            cancellations.removeValue(forKey: key)
        }
    }
}


private extension _BaseMiddleware {
    /// Controls when a Combine effect registers pending work with `TestGroup` for `TestStore.wait()`.
    /// This policy affects test synchronization only; it does not change the publisher's output or scheduling.
    enum EffectWaitBehavior {
        /// Registers pending work before subscribing, so tests wait for work that has not emitted an action yet.
        /// Use for finite effects such as network requests.
        case onStart

        /// Registers pending work for each action queued for dispatch, allowing tests to wait for action processing
        /// without waiting for future emissions or for the subscription to finish.
        /// Use for ongoing effects such as timers and notification streams.
        case onDispatchAction
    }
    
    /// Dispatches an action to the application store on the middleware's queue.
    ///
    /// This method queues the supplied action for dispatch and attaches the original call's source location.
    ///
    /// This method:
    /// - Queues the action on the middleware's execution queue.
    /// - Forwards the action with its file, function, and line information.
    ///
    /// - Parameters:
    ///   - action: The already-mapped action to dispatch.
    ///   - filePosition: The source location attached to the dispatched action.
    func dispatch(action: any Action, filePosition: FileFunctionLineDescription) {
        queue.async { [weak self] in
            self?.store.dispatch(
                action,
                fileName: filePosition.fileName,
                functionName: filePosition.functionName,
                lineNumber: filePosition.lineNumber
            )
            if let self {
                TestGroup.instance(for: self.store).leave()
            }
        }
    }
    
    /// Executes a pure effect through the shared subscription pipeline, allowing for cancellation, mapping, and optional state filtering.
    ///
    /// This method subscribes to the supplied action publisher and forwards accepted outputs to the store. When a filter is supplied,
    /// each output is checked against a fresh state snapshot before mapping. Callers configure environment dependencies and effect
    /// conversion before invoking this method.
    ///
    /// This method:
    /// - Subscribes to the effect on the specified `queue`.
    /// - Reads state and evaluates the original action when `dispatchFilter` is provided.
    /// - Maps accepted outputs and forwards them to the dispatch helper.
    /// - Handles cancellation and dispatches a mapped `Actions.DidCancelEffect` action.
    /// - Removes the subscription's registration when it completes or is cancelled.
    ///
    /// - Parameters:
    ///   - effect: The action-producing publisher to subscribe to. Its failure type must be `Never`.
    ///   - cancellation: The identifier used to deduplicate and cancel the subscription.
    ///   - waitBehavior: Controls when the test synchronization group is entered: `.onStart` before subscribing to the publisher, or
    ///     `.onDispatchAction` before dispatching each accepted action to the store.
    ///   - mapAction: Transforms accepted outputs and cancellation actions before dispatch. Defaults to `{ $0 }`.
    ///   - dispatchFilter: An optional predicate applied to a fresh state snapshot and the original output action.
    ///     Defaults to `nil`, which skips state reads.
    ///   - fileName: The calling file recorded with dispatched actions. Defaults to `#file`.
    ///   - functionName: The calling function recorded with dispatched actions. Defaults to `#function`.
    ///   - lineNumber: The calling line recorded with dispatched actions. Defaults to `#line`.
    ///
    /// - Important: An active subscription with the same cancellation identifier prevents a second subscription.
    func execute<E>(
        _ effect: E,
        cancellation: some Hashable,
        waitBehavior: EffectWaitBehavior,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        dispatchFilter: DispatchFilter<any Action>? = nil,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect, E.Output == any Action, E.Failure == Never {
        let anyId = AnyHashable(cancellation)
        
        // Prevent running the effect if an effect with the same ID is already in progress
        guard cancellations[anyId] == nil else {
            return
        }
        
        // Capture file name, function name, and line number for debugging and logging purposes
        let filePosition = fileFunctionLine(effect, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
        let testGroup = TestGroup.instance(for: store)
        if case .onStart = waitBehavior {
            testGroup.enter()
        }
        
        // Subscribe to the effect and store the cancellation token
        let cancellable = effect
            .subscribe(on: queue)
            .receive(on: queue)
            .handleEvents(receiveCancel: { [weak self] in
                // Handle cancellation: Remove the task from cancellations and dispatch cancellation action
                self?.cancellationsBox.withLockUnchecked { box in
                    box.removeCancellation(forKey: anyId)
                }
                self?.dispatch(action: mapAction(Actions.DidCancelEffect(by: cancellation)), filePosition: filePosition)
            })
            .flatMap { [weak self] action -> AnyPublisher<any Action, Never> in
                guard let dispatchFilter else {
                    return Just(action).eraseToAnyPublisher()
                }
                
                guard let self else {
                    return Empty<any Action, Never>(completeImmediately: true)
                        .eraseToAnyPublisher()
                }
                
                return Publishers.IsolatedState(from: self.store)
                    .filter { [weak self] state in
                        self?.cancellations[anyId] != nil && dispatchFilter(state, action)
                    }
                    .map { _ in action }
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { [weak self] _ in
                // Handle completion: Remove the task from cancellations
                self?.cancellationsBox.withLockUnchecked { box in
                    box.removeCancellation(forKey: anyId)
                }
                
                if case .onDispatchAction = waitBehavior {
                    testGroup.leave()
                }
                
            }, receiveValue: { [weak self] action in
                // Dispatch the mapped action if the effect is still active
                if self?.cancellations[anyId] != nil {
                    if case .onDispatchAction = waitBehavior {
                        testGroup.enter()
                    }
                    self?.dispatch(action: mapAction(action), filePosition: filePosition)
                } else if case .onStart = waitBehavior {
                    testGroup.leave()
                }
            })
        cancellationsBox.withLockUnchecked { box in
            box.set(cancellable: cancellable, forKey: anyId)
        }
    }
}
