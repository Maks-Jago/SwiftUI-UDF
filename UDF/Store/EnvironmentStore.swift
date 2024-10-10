//===--- EnvironmentStore.swift -----------------------------------===//
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
import Combine

/// A store that manages the global state of the application and provides a centralized way to dispatch actions and manage middleware.
///
/// The `EnvironmentStore` class is responsible for handling application state, managing subscribers, and dispatching actions.
/// It works in conjunction with the `AppReducer` to provide unidirectional data flow throughout the app.
public final class EnvironmentStore<State: AppReducer> {
    
    @SourceOfTruth public private(set) var state: State
    
    private var store: InternalStore<State>
    private var cancelation: Cancellable? = nil
    private let subscribersCoordinator: SubscribersCoordinator<StateSubscriber<State>> = SubscribersCoordinator()
    private let storeQueue: DispatchQueue = .init(label: "EnvironmentStore")
    
    // MARK: - Initializers
    
    /// Initializes the `EnvironmentStore` with an initial state and an array of action loggers.
    ///
    /// - Parameters:
    ///   - state: The initial state of the application.
    ///   - loggers: An array of action loggers used for logging dispatched actions.
    public init(initial state: State, loggers: [ActionLogger]) {
        var mutableState = state
        mutableState.initialSetup()
        
        let store = InternalStore(initial: mutableState, loggers: loggers)
        self.store = store
        self._state = .init(wrappedValue: mutableState, store: store)
        
        sinkSubject()
        GlobalValue.set(self)
    }
    
    /// Convenience initializer with a single action logger.
    ///
    /// - Parameters:
    ///   - state: The initial state of the application.
    ///   - logger: A single action logger used for logging dispatched actions.
    public convenience init(initial state: State, logger: ActionLogger) {
        self.init(initial: state, loggers: [logger])
    }
    
    // MARK: - Dispatch Actions
    
    /// Dispatches an action to the store with an optional priority and debug information.
    ///
    /// - Parameters:
    ///   - action: The action to dispatch.
    ///   - priority: The priority of the action. Defaults to `.default`.
    ///   - fileName: The name of the file where the action is dispatched. Defaults to the caller's file.
    ///   - functionName: The name of the function where the action is dispatched. Defaults to the caller's function.
    ///   - lineNumber: The line number where the action is dispatched. Defaults to the caller's line.
    public func dispatch(
        _ action: some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        storeQueue.async { [weak self] in
            self?.store.dispatch(action, priority: priority, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
        }
    }
    
    // MARK: - Binding Actions
    
    /// Binds an action to be dispatched when a command is executed.
    ///
    /// - Parameters:
    ///   - action: The action to bind.
    ///   - priority: The priority of the action. Defaults to `.default`.
    ///   - fileName: The name of the file where the action is bound. Defaults to the caller's file.
    ///   - functionName: The name of the function where the action is bound. Defaults to the caller's function.
    ///   - lineNumber: The line number where the action is bound. Defaults to the caller's line.
    /// - Returns: A command that, when executed, dispatches the specified action.
    public func bind(
        _ action: some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> Command {
        return {
            self.dispatch(
                action,
                priority: priority,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }
    
    /// Binds a parameterized action to be dispatched when a command with a parameter is executed.
    ///
    /// - Parameters:
    ///   - action: A closure that returns an action when given a parameter of type `T`.
    ///   - priority: The priority of the action. Defaults to `.default`.
    ///   - fileName: The name of the file where the action is bound. Defaults to the caller's file.
    ///   - functionName: The name of the function where the action is bound. Defaults to the caller's function.
    ///   - lineNumber: The line number where the action is bound. Defaults to the caller's line.
    /// - Returns: A command with a parameter that, when executed, dispatches the specified action.
    public func bind<T>(
        _ action: @escaping (T) -> some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> CommandWith<T> {
        return { value in
            self.dispatch(
                action(value),
                priority: priority,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }
    
    // MARK: - Subscription Management
    
    /// Subscribes the environment store to changes in the state using a subject.
    private func sinkSubject() {
        self.cancelation = store.subject
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] (newState, oldState, animation) in
                self.state = newState
                
                Task(priority: .high) {
                    let subscribers = await subscribersCoordinator.allSubscibers()
                    await MainActor.run {
                        subscribers.forEach { subscriber in
                            subscriber(oldState, newState, animation)
                        }
                    }
                }
            }
    }
}

// MARK: - State Subscribers
extension EnvironmentStore {
    
    /// Adds a subscriber to the state changes and returns a unique key for the subscriber.
    ///
    /// - Parameter statePublisher: A closure that will be called when the state changes.
    /// - Returns: A unique key associated with the subscriber.
    func add(statePublisher: @escaping StateSubscriber<State>) -> String {
        let key = UUID().uuidString
        
        Task(priority: .high) {
            await subscribersCoordinator.add(subscriber: statePublisher, for: key)
        }
        
        return key
    }
    
    /// Removes a state subscriber using its unique key.
    ///
    /// - Parameter key: The unique key of the subscriber to remove.
    func removePublisher(forKey key: String) {
        Task(priority: .high) {
            await subscribersCoordinator.removeSubscriber(forKey: key)
        }
    }
}

// MARK: - Global
extension EnvironmentStore {
    
    /// Provides a globally accessible instance of the `EnvironmentStore`.
    class var global: EnvironmentStore<State> {
        GlobalValue.value(for: EnvironmentStore<State>.self)
    }
}

// MARK: - Subscribe Methods
public extension EnvironmentStore {
    
    /// Subscribes to a middleware type asynchronously. This method automatically chooses the appropriate environment (test or live)
    /// depending on the current process information.
    ///
    /// - Parameter middlewareType: The middleware type to subscribe to. Must conform to `Middleware` and `EnvironmentMiddleware`.
    /// - Note: This method is designed to work asynchronously and is intended for environments where middleware needs to interact
    ///   with the state in an isolated, asynchronous manner.
    func subscribe<M: Middleware<State>>(_ middlewareType: M.Type) async where M.State == State, M: EnvironmentMiddleware {
        if ProcessInfo.processInfo.xcTest {
            await self.subscribe { store in
                middlewareType.init(store: store, environment: M.buildTestEnvironment(for: store))
            }
        } else {
            await self.subscribe { store in
                middlewareType.init(store: store, environment: M.buildLiveEnvironment(for: store))
            }
        }
    }
    
    /// Subscribes to a middleware type asynchronously with a specified environment.
    ///
    /// - Parameters:
    ///   - middlewareType: The middleware type to subscribe to. Must conform to `Middleware` and `EnvironmentMiddleware`.
    ///   - environment: The environment to be used by the middleware.
    func subscribe<M: Middleware<State>>(_ middlewareType: M.Type, environment: M.Environment) async where M.State == State, M: EnvironmentMiddleware {
        await self.subscribe { store in
            middlewareType.init(store: store, environment: environment)
        }
    }
    
    /// Subscribes to a middleware type asynchronously on a specified queue.
    ///
    /// - Parameters:
    ///   - middlewareType: The middleware type to subscribe to. Must conform to `Middleware` and `EnvironmentMiddleware`.
    ///   - queue: The dispatch queue on which the middleware operates.
    func subscribe<M: Middleware<State>>(_ middlewareType: M.Type, on queue: DispatchQueue) async where M.State == State, M: EnvironmentMiddleware {
        if ProcessInfo.processInfo.xcTest {
            await self.subscribe { store in
                middlewareType.init(store: store, environment: M.buildTestEnvironment(for: store), queue: queue)
            }
        } else {
            await self.subscribe { store in
                middlewareType.init(store: store, environment: M.buildLiveEnvironment(for: store), queue: queue)
            }
        }
    }
    
    /// Subscribes to a middleware type asynchronously.
    ///
    /// - Parameters:
    ///   - middlewareType: The middleware type to subscribe to.
    func subscribe<M: Middleware<State>>(_ middlewareType: M.Type) async where M.State == State {
        await self.subscribe { store in
            middlewareType.init(store: store)
        }
    }
    
    /// Subscribes to a middleware type asynchronously using a specified queue.
    ///
    /// - Parameters:
    ///   - middlewareType: The middleware type to subscribe to.
    ///   - queue: The dispatch queue on which the middleware operates.
    func subscribe<M: Middleware<State>>(_ middlewareType: M.Type, on queue: DispatchQueue) async where M.State == State {
        await self.subscribe { store in
            middlewareType.init(store: store, queue: queue)
        }
    }
    
    /// Subscribes to a middleware type asynchronously, using a specified environment and queue.
    ///
    /// - Parameters:
    ///   - middlewareType: The middleware type to subscribe to. Must conform to `Middleware` and `EnvironmentMiddleware`.
    ///   - environment: The environment to use for the middleware.
    ///   - queue: The dispatch queue on which the middleware operates.
    func subscribe<M: Middleware<State>>(_ middlewareType: M.Type, environment: M.Environment, on queue: DispatchQueue) async where M.State == State, M: EnvironmentMiddleware {
        await self.subscribe { store in
            middlewareType.init(store: store, environment: environment, queue: queue)
        }
    }
    
    /// Asynchronously subscribes to a middleware type and executes a closure upon completion.
    ///
    /// - Parameters:
    ///   - middlewareType: The middleware type to subscribe to.
    ///   - onSubscribe: A closure to execute after the middleware has been subscribed.
    func subscribeAsync<M>(_ middlewareType: M.Type, onSubscribe: @escaping () -> Void = {}) where M: Middleware, M: EnvironmentMiddleware, State == M.State {
        Task(priority: .userInitiated) {
            await subscribe(middlewareType)
            onSubscribe()
        }
    }
    
    /// Asynchronously subscribes to a middleware type and executes a closure upon completion.
    ///
    /// - Parameters:
    ///   - middlewareType: The middleware type to subscribe to.
    ///   - onSubscribe: A closure to execute after the middleware has been subscribed.
    func subscribeAsync<M>(_ middlewareType: M.Type, onSubscribe: @escaping () -> Void = {}) where M: Middleware, State == M.State {
        Task(priority: .userInitiated) {
            await subscribe(middlewareType)
            onSubscribe()
        }
    }
    
    /// Asynchronously subscribes to a middleware type with a specified environment and executes a closure upon completion.
    ///
    /// - Parameters:
    ///   - middlewareType: The middleware type to subscribe to.
    ///   - environment: The environment to use for the middleware.
    ///   - onSubscribe: A closure to execute after the middleware has been subscribed.
    func subscribeAsync<M>(_ middlewareType: M.Type, environment: M.Environment, onSubscribe: @escaping () -> Void = {}) where M: Middleware, State == M.State, M: EnvironmentMiddleware {
        Task(priority: .userInitiated) {
            await subscribe(middlewareType, environment: environment)
            onSubscribe()
        }
    }
    
    /// Asynchronously subscribes to a middleware type on a specified queue and executes a closure upon completion.
    ///
    /// - Parameters:
    ///   - middlewareType: The middleware type to subscribe to.
    ///   - queue: The dispatch queue on which the middleware operates.
    ///   - onSubscribe: A closure to execute after the middleware has been subscribed.
    func subscribeAsync<M>(_ middlewareType: M.Type, on queue: DispatchQueue, onSubscribe: @escaping () -> Void = {}) where M: Middleware, State == M.State, M: EnvironmentMiddleware {
        Task(priority: .userInitiated) {
            await subscribe(middlewareType, on: queue)
            onSubscribe()
        }
    }
    
    /// Asynchronously subscribes to a middleware type on a specified queue and executes a closure upon completion.
    ///
    /// - Parameters:
    ///   - middlewareType: The middleware type to subscribe to.
    ///   - queue: The dispatch queue on which the middleware operates.
    ///   - onSubscribe: A closure to execute after the middleware has been subscribed.
    func subscribeAsync<M>(_ middlewareType: M.Type, on queue: DispatchQueue, onSubscribe: @escaping () -> Void = {}) where M: Middleware, State == M.State {
        Task(priority: .userInitiated) {
            await subscribe(middlewareType, on: queue)
            onSubscribe()
        }
    }
    
    /// Asynchronously subscribes to a middleware type with a specified environment and queue, then executes a closure upon completion.
    ///
    /// - Parameters:
    ///   - middlewareType: The middleware type to subscribe to.
    ///   - environment: The environment to use for the middleware.
    ///   - queue: The dispatch queue on which the middleware operates.
    ///   - onSubscribe: A closure to execute after the middleware has been subscribed.
    func subscribeAsync<M>(_ middlewareType: M.Type, environment: M.Environment, on queue: DispatchQueue, onSubscribe: @escaping () -> Void = {}) where M: Middleware, State == M.State, M: EnvironmentMiddleware {
        Task(priority: .userInitiated) {
            await subscribe(middlewareType, environment: environment, on: queue)
            onSubscribe()
        }
    }
    
    /// Subscribes to middleware using a custom builder asynchronously.
    ///
    /// - Parameter build: A closure that takes the store and returns an array of middleware wrappers.
    func subscribeAsync(@MiddlewareBuilder<State> build: @escaping (_ store: any Store<State>) -> [MiddlewareWrapper<State>]) {
        Task(priority: .userInitiated) {
            await self.store.subscribe(
                build(store).map { wrapper in
                    wrapper.instance ?? self.middleware(store: store, type: wrapper.type)
                }
            )
        }
    }
    
    /// Subscribes to middleware using a custom builder.
    ///
    /// - Parameter build: A closure that takes the store and returns an array of middleware wrappers.
    func subscribe(@MiddlewareBuilder<State> build: @escaping (_ store: any Store<State>) -> [MiddlewareWrapper<State>]) async {
        await self.store.subscribe(
            build(store).map { wrapper in
                wrapper.instance ?? self.middleware(store: store, type: wrapper.type)
            }
        )
    }
    
    // MARK: - Private Helpers
    
    /// Creates and returns a middleware instance for the specified store and type.
    ///
    /// - Parameters:
    ///   - store: The store instance.
    ///   - type: The type of middleware to create.
    /// - Returns: An instance of the middleware.
    private func middleware<M: Middleware<State>>(store: any Store<State>, type: M.Type) -> any Middleware<State> where M.State == State {
        switch type {
        case let envMiddlewareType as any MiddlewareWithEnvironment<State>.Type:
            envMiddleware(store: store, type: envMiddlewareType)
        default:
            type.init(store: store)
        }
    }
    
    /// Creates and returns an environment-aware middleware instance.
    ///
    /// - Parameters:
    ///   - store: The store instance.
    ///   - type: The type of environment-aware middleware to create.
    /// - Returns: An instance of the environment-aware middleware.
    private func envMiddleware<M: MiddlewareWithEnvironment<State>>(store: any Store<State>, type: M.Type) -> any Middleware<State> where M.State == State {
        if ProcessInfo.processInfo.xcTest {
            type.init(store: store, environment: type.buildTestEnvironment(for: store))
        } else {
            type.init(store: store, environment: type.buildLiveEnvironment(for: store))
        }
    }
}
