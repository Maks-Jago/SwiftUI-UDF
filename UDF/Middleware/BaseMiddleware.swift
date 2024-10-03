//===--- BaseMiddleware.swift --------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import Combine

/// `BaseMiddleware` is an open class that serves as the base for creating middleware components
/// in the UDF architecture. Middleware is responsible for handling side effects and can process actions
/// and perform asynchronous operations.
///
/// This class is generic over a `State` type that conforms to `AppReducer`.
open class BaseMiddleware<State: AppReducer>: Middleware {
    
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
    required public init(store: some Store<State>, queue: DispatchQueue) {
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
    public typealias ErrorMapper<Id> = (_ id: Id, _ error: Error) -> any Action
    
    /// A dictionary to track ongoing tasks by their unique identifiers, allowing for cancellation.
    public var cancellations: [AnyHashable: CancellableTask] = [:]
    
    // MARK: - Cancellation
    
    /// Cancels an ongoing task identified by the specified cancellation ID.
    ///
    /// - Parameter cancellation: The unique identifier for the task to be canceled.
    /// - Returns: A Boolean indicating whether the task was successfully canceled.
    @discardableResult
    open func cancel<Id: Hashable>(by cancellation: Id) -> Bool {
        let anyId = AnyHashable(cancellation)
        
        guard let cancellableTask = cancellations[anyId] else {
            return false
        }
        
        cancellableTask.cancel()
        cancellations[anyId] = nil
        return true
    }
    
    /// Cancels all ongoing tasks tracked in the `cancellations` dictionary.
    open func cancelAll() {
        cancellations.keys.forEach { cancel(by: $0) }
    }

    // MARK: - Combine
    
    /// Executes a pure effect and dispatches actions to the store, allowing for cancellation and mapping of actions.
    ///
    /// This method listens to a given `PureEffect` and dispatches actions to the store. It manages the effect lifecycle by allowing
    /// cancellation using an identifier. The effect is subscribed to on the specified `queue`, and upon completion, success, or cancellation,
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
    /// - Note: This method uses Combine's `sink` and `handleEvents` to manage the effect's lifecycle, including cancellation and completion.
    ///
    /// - Important: If an effect with the same `cancellation` identifier is already running, this method will not start a new effect.
    open func execute<E, Id>(
        _ effect: E,
        cancellation: Id,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect, E.Output == any Action, E.Failure == Never, Id: Hashable {
        let anyId = AnyHashable(cancellation)
        
        // Prevent executing the effect if an effect with the same ID is already in progress
        guard cancellations[anyId] == nil else {
            return
        }
        
        // Capture file name, function name, and line number for debugging and logging purposes
        let filePosition = fileFunctionLine(effect, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
        
        // Registering for XCTest to wait for asynchronous code in tests
        XCTestGroup.enter()
        
        // Subscribe to the effect and store the cancellation token
        cancellations[anyId] = effect
            .subscribe(on: queue)
            .receive(on: queue)
            .handleEvents(receiveCancel: { [weak self] in
                // Handle cancellation: Remove the task from cancellations and dispatch cancellation action
                self?.cancellations[anyId] = nil
                self?.store.dispatch(
                    Actions.DidCancelEffect(by: cancellation),
                    fileName: filePosition.fileName,
                    functionName: filePosition.functionName,
                    lineNumber: filePosition.lineNumber
                )
                // Signal XCTest that this task has been cancelled
                XCTestGroup.leave()
            })
            .sink(receiveCompletion: { [weak self] _ in
                // Handle completion: Remove the task from cancellations and signal XCTest
                self?.cancellations[anyId] = nil
                XCTestGroup.leave()
            }, receiveValue: { [weak self] action in
                // Handle receiving a value: Dispatch the action to the store
                if self?.cancellations[anyId] != nil {
                    self?.store.dispatch(
                        mapAction(action),
                        fileName: filePosition.fileName,
                        functionName: filePosition.functionName,
                        lineNumber: filePosition.lineNumber
                    )
                }
            })
    }

    /// Executes an effect that conforms to both `PureEffect` and `ErasableToEffect` and dispatches actions to the store.
    ///
    /// This method serves as an overload of the `execute` method for effects that can be erased to a more generic effect type. It converts the given effect to an `Effectable` using the `asEffectable` method before executing it.
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
    open func execute<E, Id>(
        _ effect: E,
        cancellation: Id,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect & ErasableToEffect, Id: Hashable {
        execute(
            effect.asEffectable,
            cancellation: cancellation,
            mapAction: mapAction,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }

    /// Runs a `PureEffect` and conditionally dispatches actions to the store based on a filter.
    ///
    /// This method subscribes to the provided effect, allowing for its cancellation and mapping of actions. Additionally, it utilizes a dispatch filter to determine whether each action should be dispatched based on the current state.
    ///
    /// - Parameters:
    ///   - effect: The `PureEffect` to execute, which outputs an `Action` and never fails.
    ///   - cancellation: A unique identifier used to track and cancel the effect.
    ///   - mapAction: A closure that maps the output of the effect to an action. Defaults to an identity mapping (`{ $0 }`).
    ///   - dispatchFilter: A closure that determines whether the action should be dispatched, based on the current state and the action itself.
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
    open func run<E, Id>(
        _ effect: E,
        cancellation: Id,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        dispatchFilter: @escaping DispatchFilter<any Action>,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect, E.Output == any Action, E.Failure == Never, Id: Hashable {
        let anyId = AnyHashable(cancellation)
        
        // Prevent running the effect if an effect with the same ID is already in progress
        guard cancellations[anyId] == nil else {
            return
        }
        
        // Capture file name, function name, and line number for debugging and logging purposes
        let filePosition = fileFunctionLine(effect, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
        
        // Subscribe to the effect and store the cancellation token
        cancellations[anyId] = effect
            .subscribe(on: queue)
            .receive(on: queue)
            .handleEvents(receiveCancel: { [weak self] in
                // Handle cancellation: Remove the task from cancellations and dispatch cancellation action
                self?.cancellations[anyId] = nil
                self?.store.dispatch(
                    Actions.DidCancelEffect(by: cancellation),
                    fileName: filePosition.fileName,
                    functionName: filePosition.functionName,
                    lineNumber: filePosition.lineNumber
                )
            })
            .flatMap { [unowned self] action in
                // Isolate the state to be used in the dispatch filter
                Publishers.IsolatedState(from: self.store)
                    .map { state in
                        (state: state, action: action)
                    }
                    .eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { [weak self] _ in
                // Handle completion: Remove the task from cancellations
                self?.cancellations[anyId] = nil
            }, receiveValue: { [weak self] result in
                // Dispatch the action if the cancellation token exists and the dispatch filter returns true
                if self?.cancellations[anyId] != nil, dispatchFilter(result.state, result.action) {
                    self?.store.dispatch(
                        mapAction(result.action),
                        fileName: filePosition.fileName,
                        functionName: filePosition.functionName,
                        lineNumber: filePosition.lineNumber
                    )
                }
            })
    }

    /// Runs a `PureEffect` and dispatches its actions to the store.
    ///
    /// This method subscribes to the provided effect, allowing for its cancellation and mapping of actions. It handles the lifecycle of the effect by managing its subscription and cancellation.
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
    /// - Note: This method ensures that if an effect with the same `cancellation` identifier is already running, it will not start a new effect.
    open func run<E, Id>(
        _ effect: E,
        cancellation: Id,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) where E: PureEffect, E.Output == any Action, E.Failure == Never, Id: Hashable {
        let anyId = AnyHashable(cancellation)
        
        // Prevent running the effect if an effect with the same ID is already in progress
        guard cancellations[anyId] == nil else {
            return
        }
        
        // Capture file name, function name, and line number for debugging and logging purposes
        let filePosition = fileFunctionLine(effect, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
        
        // Subscribe to the effect and store the cancellation token
        cancellations[anyId] = effect
            .subscribe(on: queue) // Subscribe to the effect on the specified queue
            .receive(on: queue) // Specify the queue on which to receive events
            .handleEvents(receiveCancel: { [weak self] in
                // Handle cancellation: Remove the task from cancellations and dispatch cancellation action
                self?.cancellations[anyId] = nil
                self?.store.dispatch(
                    Actions.DidCancelEffect(by: cancellation),
                    fileName: filePosition.fileName,
                    functionName: filePosition.functionName,
                    lineNumber: filePosition.lineNumber
                )
            })
            .sink(receiveCompletion: { [weak self] _ in
                // Handle completion: Remove the task from cancellations
                self?.cancellations[anyId] = nil
            }, receiveValue: { [weak self] action in
                // Dispatch the mapped action to the store if the effect is still active
                if self?.cancellations[anyId] != nil {
                    self?.store.dispatch(
                        mapAction(action),
                        fileName: filePosition.fileName,
                        functionName: filePosition.functionName,
                        lineNumber: filePosition.lineNumber
                    )
                }
            })
    }
    
    // MARK: - Concurrency
    /// Executes an asynchronous task with support for cancellation and error handling.
    ///
    /// This method allows for the execution of an asynchronous task. It wraps the task in a `ConcurrencyBlockEffect` to support cancellation, error mapping, and action mapping.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the task, used for tracking and error mapping.
    ///   - cancellation: A unique identifier for tracking and potentially canceling the effect.
    ///   - mapAction: A closure that maps the result of the task to an action. Defaults to an identity mapping (`{ $0 }`).
    ///   - mapError: A closure that maps errors thrown by the task to an action. Defaults to creating an `Actions.Error` action using the error's localized description.
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
    open func execute<TaskId: Hashable>(
        id: TaskId,
        cancellation: some Hashable,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        mapError: @escaping ErrorMapper<TaskId> = { effectId, error in Actions.Error(error: error.localizedDescription, id: effectId) },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line,
        _ task: @escaping (TaskId) async throws -> any Action
    ) {
        execute(
            ConcurrencyBlockEffect(
                id: id,
                block: task,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            ),
            cancellation: cancellation,
            mapAction: mapAction,
            mapError: mapError
        )
    }

    private func dispatch(action: any Action, filePosition: FileFunctionLineDescription) {
        queue.sync { [weak self] in
            self?.store.dispatch(
                action,
                fileName: filePosition.fileName,
                functionName: filePosition.functionName,
                lineNumber: filePosition.lineNumber
            )
            XCTestGroup.leave()
        }
    }
    
    /// Executes a `ConcurrencyEffect` with support for cancellation and error handling.
    ///
    /// This method starts a new asynchronous task, invoking the provided `ConcurrencyEffect`'s `task()` method. It supports cancellation, mapping of the resulting action, and error handling.
    ///
    /// - Parameters:
    ///   - effect: The `ConcurrencyEffect` to execute.
    ///   - cancellation: A unique identifier for tracking and potentially canceling the task.
    ///   - mapAction: A closure that maps the output action of the task to another action. Defaults to an identity mapping (`{ $0 }`).
    ///   - mapError: A closure that maps errors thrown by the task to an action. Defaults to creating an `Actions.Error` using the error's localized description.
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
    open func execute<Id: Hashable, E: ConcurrencyEffect>(
        _ effect: E,
        cancellation: Id,
        mapAction: @escaping (any Action) -> any Action = { $0 },
        mapError: @escaping ErrorMapper<E.Id> = { effectId, error in Actions.Error(error: error.localizedDescription, id: effectId) },
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        let anyId = AnyHashable(cancellation)
        
        // Prevent running the effect if an effect with the same ID is already in progress
        guard cancellations[anyId] == nil else {
            return
        }
        
        // Capture file name, function name, and line number for debugging and logging purposes
        let filePosition = fileFunctionLine(effect, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
        
        // Start the task and store the cancellation token
        XCTestGroup.enter()
        let task = Task { [weak self] in
            do {
                // Execute the effect's task
                let action = try await effect.task()
                
                // Check if the task was cancelled and dispatch appropriate actions
                if Task.isCancelled {
                    self?.dispatch(action: Actions.DidCancelEffect(by: cancellation), filePosition: filePosition)
                } else {
                    self?.dispatch(action: mapAction(action), filePosition: filePosition)
                }
                
            } catch let error {
                // Handle errors and task cancellation
                if error is CancellationError {
                    self?.dispatch(action: Actions.DidCancelEffect(by: cancellation), filePosition: filePosition)
                } else if !Task.isCancelled {
                    self?.dispatch(action: mapError(effect.id, error), filePosition: filePosition)
                }
            }
            
            // Remove the task from the cancellations dictionary
            _ = self?.queue.sync { [weak self] in
                self?.cancellations.removeValue(forKey: anyId)
            }
        }
        
        // Store the task in the cancellations dictionary for future cancellation
        cancellations[anyId] = task
    }
}
