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
    /// - Parameters:
    ///   - effect: The `PureEffect` to execute. It must output an `Action` and never fail.
    ///   - cancellation: A unique identifier to track and cancel the effect.
    ///   - mapAction: A closure that maps the output of the effect to an action. Defaults to an identity mapping (`{ $0 }`).
    ///   - fileName: The name of the file from which the method is called. Defaults to the file in which this method is used.
    ///   - functionName: The name of the function from which the method is called. Defaults to the function in which this method is used.
    ///   - lineNumber: The line number from which the method is called. Defaults to the line in which this method is used.
    ///
    /// This method:
    /// - Subscribes to the effect on the specified `queue`.
    /// - Handles cancellation using the `cancellation` identifier.
    /// - Dispatches actions to the store based on the effect's output.
    ///
    /// - Note: This method uses Combine's `sink` and `handleEvents` to manage the effect's lifecycle, including cancellation and
    /// completion.
    ///
    /// - Important: If an effect with the same `cancellation` identifier is already running, this method will not start a new effect.
    open func execute<E>(
        _ effect: E,
        cancellation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect, E.Output == any Action, E.Failure == Never {
        let anyId = AnyHashable(cancellation)

        // Prevent executing the effect if an effect with the same ID is already in progress
        guard cancellations[anyId] == nil else {
            return
        }

        // Capture file name, function name, and line number for debugging and logging purposes
        let filePosition = fileFunctionLine(effect, fileName: fileName, functionName: functionName, lineNumber: lineNumber)

        // Registering for testing framework to wait for asynchronous code
        let testGroupKey = TestGroup.enter(for: store)

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
            .sink(receiveCompletion: { [weak self] _ in
                // Handle completion: Remove the task from cancellations and signal Testing
                self?.cancellationsBox.withLockUnchecked { box in
                    box.removeCancellation(forKey: anyId)
                }
            }, receiveValue: { [weak self] action in
                // Handle receiving a value: Dispatch the action to the store
                if self?.cancellations[anyId] != nil {
                    self?.dispatch(action: mapAction(action), filePosition: filePosition)
                } else {
                    TestGroup.instanceFor(key: testGroupKey).leave()
                }
            })
        cancellationsBox.withLockUnchecked { state in
            state.set(cancellable: cancellable, forKey: anyId)
        }
    }

    /// Executes an effect that conforms to both `PureEffect` and `ErasableToEffect` and dispatches actions to the store.
    ///
    /// This method serves as an overload of the `execute` method for effects that can be erased to a more generic effect type. It converts
    /// the given effect to an `Effectable` using the `asEffectable` method before executing it.
    ///
    /// - Parameters:
    ///   - effect: The effect to execute, which conforms to both `PureEffect` and `ErasableToEffect`.
    ///   - cancellation: A unique identifier used to track and cancel the effect.
    ///   - mapAction: A closure that maps the output of the effect to an action. Defaults to an identity mapping (`{ $0 }`).
    ///   - fileName: The name of the file from which this method is called. Defaults to the file where the method is used.
    ///   - functionName: The name of the function from which this method is called. Defaults to the function where the method is used.
    ///   - lineNumber: The line number from which this method is called. Defaults to the line where the method is used.
    ///
    /// This method:
    /// - Converts the effect to an `Effectable` type using the `asEffectable` method.
    /// - Calls the main `execute` method with the converted effect.
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

    /// Executes a `StateEffectable` and dispatches actions to the store, allowing for cancellation and mapping of actions.
    ///
    /// This method builds a publisher from the provided `StateEffectable` using the supplied `flowId` and a snapshot of the current
    /// store state. It then subscribes to that publisher and dispatches its emitted actions to the store.
    ///
    /// - Parameters:
    ///   - effect: The `StateEffectable` to execute.
    ///   - flowId: The unique identifier for the flow associated with the effect.
    ///   - cancellation: A unique identifier to track and cancel the effect.
    ///   - mapAction: A closure that maps the output of the effect to an action. Defaults to an identity mapping (`{ $0 }`).
    ///   - fileName: The name of the file from which the method is called. Defaults to the file in which this method is used.
    ///   - functionName: The name of the function from which the method is called. Defaults to the function in which this method is used.
    ///   - lineNumber: The line number from which the method is called. Defaults to the line in which this method is used.
    ///
    /// This method:
    /// - Checks if an effect with the same `cancellation` identifier is already running. If it is, the method returns early.
    /// - Captures the current store state and passes it to `publisher(flowId:state:)`.
    /// - Subscribes to the resulting publisher on the specified `queue`.
    /// - Dispatches actions emitted by the publisher to the store.
    ///
    /// - Note: This method uses Combine's `sink` and `handleEvents` to manage the effect's lifecycle, including cancellation and
    /// completion.
    open func execute<Effect: StateEffectable & Sendable>(
        effect: Effect,
        flowId: AnyHashable,
        cancellation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where Effect.AppState == State {
        let publisher = Publishers
            .IsolatedState(from: store)
            .flatMap { state in
                effect.publisher(flowId: flowId, state: state)
            }
            .eraseToAnyPublisher()
        
        execute(
            publisher,
            cancellation: cancellation,
            mapAction: mapAction,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    /// Runs a `PureEffect` and conditionally dispatches actions to the store based on a filter.
    ///
    /// This method subscribes to the provided effect, allowing for its cancellation and mapping of actions. Additionally, it utilizes a
    /// dispatch filter to determine whether each action should be dispatched based on the current state.
    ///
    /// - Parameters:
    ///   - effect: The `PureEffect` to execute, which outputs an `Action` and never fails.
    ///   - cancellation: A unique identifier used to track and cancel the effect.
    ///   - mapAction: A closure that maps the output of the effect to an action. Defaults to an identity mapping (`{ $0 }`).
    ///   - dispatchFilter: A closure that determines whether the action should be dispatched, based on the current state and the action
    /// itself.
    ///   - fileName: The name of the file from which the method is called. Defaults to the file in which this method is used.
    ///   - functionName: The name of the function from which the method is called. Defaults to the function in which this method is used.
    ///   - lineNumber: The line number from which the method is called. Defaults to the line in which this method is used.
    ///
    /// This method:
    /// - Subscribes to the effect on the specified `queue`.
    /// - Uses `handleEvents` to manage cancellation.
    /// - Applies a `dispatchFilter` to determine if the action should be dispatched.
    /// - Uses Combine's `flatMap` and `sink` to handle the effect's output.
    ///
    /// - Note: This method uses Combine's publishers to isolate the current state and process the effect's output conditionally.
    ///
    /// - Important: If an effect with the same `cancellation` identifier is already running, this method will not start a new effect.
    open func run<E>(
        _ effect: E,
        cancellation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        dispatchFilter: @escaping DispatchFilter<any Action>,
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
        let testGroupKey = TestGroup.instanceKey(store)

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
            .flatMap { [weak self] action in
                guard let self else {
                    return Empty<(state: State, action: any Action), Never>(completeImmediately: true)
                        .eraseToAnyPublisher()
                }

                // Isolate the state to be used in the dispatch filter
                return Publishers.IsolatedState(from: self.store)
                    .map { state in
                        (state: state, action: action)
                    }
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { [weak self] _ in
                // Handle completion: Remove the task from cancellations
                self?.cancellationsBox.withLockUnchecked { box in
                    box.removeCancellation(forKey: anyId)
                }
                TestGroup.instanceFor(key: testGroupKey).leave()

            }, receiveValue: { [weak self] result in
                // Dispatch the action if the cancellation token exists and the dispatch filter returns true
                if self?.cancellations[anyId] != nil, dispatchFilter(result.state, result.action) {
                    self?.dispatch(action: mapAction(result.action), filePosition: filePosition)
                }
            })
        cancellationsBox.withLockUnchecked { box in
            box.set(cancellable: cancellable, forKey: anyId)
        }
    }

    /// Runs a `StateEffectable` and conditionally dispatches its actions to the store based on a filter.
    ///
    /// This method builds a publisher from the provided `StateEffectable` using a snapshot of the current store state and the supplied
    /// `flowId`, then forwards the resulting publisher to the existing `run` pipeline with a dispatch filter.
    ///
    /// - Parameters:
    ///   - effect: The `StateEffectable` to execute.
    ///   - flowId: The unique identifier for the flow associated with the effect.
    ///   - cancellation: A unique identifier used to track and cancel the effect.
    ///   - mapAction: A closure that maps the output of the effect to an action. Defaults to an identity mapping (`{ $0 }`).
    ///   - dispatchFilter: A closure that determines whether the action should be dispatched, based on the current state and the action
    /// itself.
    ///   - fileName: The name of the file from which the method is called. Defaults to the file in which this method is used.
    ///   - functionName: The name of the function from which the method is called. Defaults to the function in which this method is used.
    ///   - lineNumber: The line number from which the method is called. Defaults to the line in which this method is used.
    open func run<Effect: StateEffectable & Sendable>(
        effect: Effect,
        flowId: AnyHashable,
        cancellation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        dispatchFilter: @escaping DispatchFilter<any Action>,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where Effect.AppState == State {
        let publisher = Publishers.IsolatedState(from: store)
            .flatMap { state in
                effect.publisher(flowId: flowId, state: state)
            }
            .eraseToAnyPublisher()

        run(
            publisher,
            cancellation: cancellation,
            mapAction: mapAction,
            dispatchFilter: dispatchFilter,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    /// Runs a `PureEffect` and dispatches its actions to the store.
    ///
    /// This method subscribes to the provided effect, allowing for its cancellation and mapping of actions. It handles the lifecycle of the
    /// effect by managing its subscription and cancellation.
    ///
    /// - Parameters:
    ///   - effect: The `PureEffect` to execute, which outputs an `Action` and never fails.
    ///   - cancellation: A unique identifier used to track and cancel the effect.
    ///   - mapAction: A closure that maps the output of the effect to an action. Defaults to an identity mapping (`{ $0 }`).
    ///   - fileName: The name of the file from which the method is called. Defaults to the file where this method is used.
    ///   - functionName: The name of the function from which the method is called. Defaults to the function where this method is used.
    ///   - lineNumber: The line number from which the method is called. Defaults to the line where this method is used.
    ///
    /// This method:
    /// - Subscribes to the effect on the specified `queue`.
    /// - Uses `handleEvents` to manage the effect's cancellation by dispatching an `Actions.DidCancelEffect`.
    /// - Uses Combine's `sink` to handle the effect's output and dispatches the action to the store.
    ///
    /// - Note: This method ensures that if an effect with the same `cancellation` identifier is already running, it will not start a new
    /// effect.
    open func run<E>(
        _ effect: E,
        cancellation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
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
        let testGroupKey = TestGroup.instanceKey(store)

        // Subscribe to the effect and store the cancellation token
        let cancellable = effect
            .subscribe(on: queue) // Subscribe to the effect on the specified queue
            .receive(on: queue) // Specify the queue on which to receive events
            .handleEvents(receiveCancel: { [weak self] in
                // Handle cancellation: Remove the task from cancellations and dispatch cancellation action
                self?.cancellationsBox.withLockUnchecked { box in
                    box.removeCancellation(forKey: anyId)
                }
                self?.dispatch(action: mapAction(Actions.DidCancelEffect(by: cancellation)), filePosition: filePosition)
            })
            .sink(receiveCompletion: { [weak self] _ in
                // Handle completion: Remove the task from cancellations
                self?.cancellationsBox.withLockUnchecked { box in
                    box.removeCancellation(forKey: anyId)
                }
                TestGroup.instanceFor(key: testGroupKey).leave()

            }, receiveValue: { [weak self] action in
                // Dispatch the mapped action to the store if the effect is still active
                if self?.cancellations[anyId] != nil {
                    TestGroup.instanceFor(key: testGroupKey).enter()
                    self?.dispatch(action: mapAction(action), filePosition: filePosition)
                }
            })
        cancellationsBox.withLockUnchecked { box in
            box.set(cancellable: cancellable, forKey: anyId)
        }
    }

    /// Runs a `StateEffectable` and dispatches its actions to the store.
    ///
    /// This method builds a publisher from the provided `StateEffectable` using a snapshot of the current store state and the supplied
    /// `flowId`, then forwards the resulting publisher to the existing `run` pipeline.
    ///
    /// - Parameters:
    ///   - effect: The `StateEffectable` to execute.
    ///   - flowId: The unique identifier for the flow associated with the effect.
    ///   - cancellation: A unique identifier used to track and cancel the effect.
    ///   - mapAction: A closure that maps the output of the effect to an action. Defaults to an identity mapping (`{ $0 }`).
    ///   - fileName: The name of the file from which the method is called. Defaults to the file where this method is used.
    ///   - functionName: The name of the function from which the method is called. Defaults to the function where this method is used.
    ///   - lineNumber: The line number from which the method is called. Defaults to the line where this method is used.
    open func run<Effect: StateEffectable & Sendable>(
        effect: Effect,
        flowId: AnyHashable,
        cancellation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where Effect.AppState == State {
        let publisher = Publishers.IsolatedState(from: store)
            .flatMap { state in
                effect.publisher(flowId: flowId, state: state)
            }
            .eraseToAnyPublisher()

        run(
            publisher,
            cancellation: cancellation,
            mapAction: mapAction,
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
    /// - Parameters:
    ///   - id: A unique identifier for the task, used for tracking and error mapping.
    ///   - cancellation: A unique identifier for tracking and potentially canceling the effect.
    ///   - mapAction: A closure that maps the result of the task to an action. Defaults to an identity mapping (`{ $0 }`).
    ///   - mapError: A closure that maps errors thrown by the task to an action. Defaults to creating an `Actions.Error` action using the
    /// error's localized description.
    ///   - fileName: The name of the file from which the method is called. Defaults to the file where this method is used.
    ///   - functionName: The name of the function from which the method is called. Defaults to the function where this method is used.
    ///   - lineNumber: The line number from which the method is called. Defaults to the line where this method is used.
    ///   - task: The asynchronous task to execute. It takes the task's `id` as a parameter and returns an action.
    ///
    /// This method:
    /// - Wraps the provided asynchronous task in a `ConcurrencyBlockEffect`.
    /// - Supports cancellation using a unique identifier.
    /// - Maps the output of the task to an action using `mapAction`.
    /// - Maps any errors thrown by the task to an action using `mapError`.
    ///
    /// - Note: This method makes use of the `execute` method that handles `ConcurrencyBlockEffect` objects.
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
                let action = try await task(flowId)

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

    private func dispatch(action: any Action, filePosition: FileFunctionLineDescription) {
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

    /// Executes a `ConcurrencyEffect` with support for cancellation and error handling.
    ///
    /// This method starts a new asynchronous task, invoking the provided `ConcurrencyEffect`'s `task()` method. It supports cancellation,
    /// mapping of the resulting action, and error handling.
    ///
    /// - Parameters:
    ///   - effect: The `ConcurrencyEffect` to execute.
    ///   - cancellation: A unique identifier for tracking and potentially canceling the task.
    ///   - mapAction: A closure that maps the output action of the task to another action. Defaults to an identity mapping (`{ $0 }`).
    ///   - mapError: A closure that maps errors thrown by the task to an action. Defaults to creating an `Actions.Error` using the error's
    /// localized description.
    ///   - fileName: The name of the file from which the method is called. Defaults to the file where this method is used.
    ///   - functionName: The name of the function from which the method is called. Defaults to the function where this method is used.
    ///   - lineNumber: The line number from which the method is called. Defaults to the line where this method is used.
    ///
    /// This method:
    /// - Checks if a task with the same `cancellation` identifier is already running. If it is, the method returns early.
    /// - Executes the `ConcurrencyEffect`'s asynchronous `task()` method.
    /// - Handles task cancellation and errors, dispatching appropriate actions to the store.
    /// - Removes the task from the `cancellations` dictionary when it is completed.
    ///
    /// - Note: This method uses the Swift `Task` API to run the asynchronous task.
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
        execute(
            flowId: flowId,
            cancellation: cancellation,
            mapAction: mapAction,
            mapError: mapError,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        ) { flowID in
            try await effect.task(flowId: flowId)
        }
    }
    
    /// Executes a `StateConcurrencyEffect` with support for cancellation and error handling.
    ///
    /// This method starts a new asynchronous task, invoking the provided `StateConcurrencyEffect`'s `task(flowId:state:)` method.
    /// It captures the current store state at execution time and passes that state into the effect together with the provided `flowId`.
    /// It supports cancellation, mapping of the resulting action, and error handling.
    ///
    /// - Parameters:
    ///   - effect: The `StateConcurrencyEffect` to execute.
    ///   - flowId: The unique identifier for the flow associated with the effect.
    ///   - cancellation: A unique identifier for tracking and potentially canceling the task.
    ///   - mapAction: A closure that maps the output action of the task to another action. Defaults to an identity mapping (`{ $0 }`).
    ///   - mapError: A closure that maps errors thrown by the task to an action. Defaults to creating an `Actions.Error` using the error's
    /// localized description.
    ///   - fileName: The name of the file from which the method is called. Defaults to the file where this method is used.
    ///   - functionName: The name of the function from which the method is called. Defaults to the function where this method is used.
    ///   - lineNumber: The line number from which the method is called. Defaults to the line where this method is used.
    ///
    /// This method:
    /// - Checks if a task with the same `cancellation` identifier is already running. If it is, the method returns early.
    /// - Reads the current store state and passes it to the effect's asynchronous `task(flowId:state:)` method.
    /// - Handles task cancellation and errors, dispatching appropriate actions to the store.
    /// - Removes the task from the `cancellations` dictionary when it is completed.
    ///
    /// - Note: If the store is no longer available when the task starts, this method throws `CancellationError`.
    /// - Note: This method uses the Swift `Task` API to run the asynchronous task.
    open func execute<Effect: StateConcurrencyEffect & Sendable>(
        effect: Effect,
        flowId: AnyHashable,
        cancellation: some Hashable & Sendable,
        mapAction: @escaping @Sendable (any Action) -> any Action = { $0 },
        mapError: @escaping ErrorMapper<AnyHashable> = { flowId, error in Actions.Error(error: error.localizedDescription, id: flowId) },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where Effect.AppState == State {
        execute(
            flowId: flowId,
            cancellation: cancellation,
            mapAction: mapAction,
            mapError: mapError,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        ) { [weak store] flowID in
            guard let store else {
                throw CancellationError()
            }
            return try await effect.task(flowId: flowId, state: store.state)
        }
    }
    
    /// A container for the middleware's mutable state, designed to be managed by a synchronization mechanism
    /// 
    /// This class enables the safe retrieval and cancellation of tasks across different threads,
    /// ensuring that internal storage is modified only through the established lock.
    private class CancellationsBox: @unchecked Sendable {
        var cancellations: [AnyHashable: CancellableTask] = [:]
        
        func set(cancellable: CancellableTask, forKey key: AnyHashable) {
            cancellations[key] = cancellable
        }
        
        func removeCancellation(forKey key: AnyHashable) {
            cancellations.removeValue(forKey: key)
        }
    }
}
