//===--- Middleware.swift -----------------------------------------===//
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

/// A protocol that defines a middleware component in the UDF architecture.
///
/// Middleware in the UDF (Unidirectional Data Flow) handles side effects and asynchronous operations (e.g., network requests, file uploads, data processing) outside of the reducer.
/// It listens for specific actions, performs tasks, and dispatches new actions based on the outcome.
/// Middleware is designed to work in its own queue, keeping the UI responsive by offloading long-running tasks.
///
public protocol Middleware<State> {
    associatedtype State: AppReducer
    
    /// The store that the middleware interacts with.
    var store: any Store<State> { get }
    
    /// The dispatch queue on which the middleware performs its operations.
    var queue: DispatchQueue { get set }
    
    /// Initializes the middleware with a store.
    ///
    /// - Parameter store: The store that the middleware will interact with.
    init(store: some Store<State>)
    
    /// Initializes the middleware with a store and a specific dispatch queue.
    ///
    /// - Parameters:
    ///   - store: The store that the middleware will interact with.
    ///   - queue: The dispatch queue for performing middleware operations.
    init(store: some Store<State>, queue: DispatchQueue)
    
    /// Determines the current status of the middleware for the given state.
    ///
    /// - Parameter state: The state to evaluate.
    /// - Returns: A `MiddlewareStatus` representing the current status.
    func status(for state: State) -> MiddlewareStatus
    
    /// Cancels an operation identified by the given cancellation identifier.
    ///
    /// - Parameter cancelation: A unique identifier for the operation to be canceled.
    /// - Returns: `true` if the operation was successfully canceled; otherwise, `false`.
    @discardableResult
    func cancel<Id: Hashable>(by cancelation: Id) -> Bool
    
    /// Cancels all ongoing operations managed by the middleware.
    func cancelAll()
}

// MARK: - Default Initializer for Middleware

public extension Middleware {
    /// Provides a default initializer for `Middleware` implementations.
    ///
    /// This initializer creates a dispatch queue using the type name of the middleware as its label.
    /// - Parameter store: The store that the middleware will interact with.
    init(store: some Store<State>) {
        let queueLabel = String(describing: Self.self)
        self.init(store: store, queue: DispatchQueue(label: queueLabel))
    }
}

// MARK: - Environment Middleware Extensions

public extension Middleware where Self: EnvironmentMiddleware {
    /// Initializes the middleware with a store, using a live environment.
    ///
    /// This initializer creates a middleware with a live environment built from the provided store.
    /// - Parameter store: The store that the middleware will interact with.
    init(store: some Store<State>) {
        self.init(store: store, environment: Self.buildLiveEnvironment(for: store))
    }
    
    /// Initializes the middleware with a store and a specific dispatch queue, using a live environment.
    ///
    /// This initializer creates a middleware with a live environment built from the provided store and a specific queue.
    /// - Parameters:
    ///   - store: The store that the middleware will interact with.
    ///   - queue: The dispatch queue for performing middleware operations.
    init(store: some Store<State>, queue: DispatchQueue) {
        self.init(store: store, environment: Self.buildLiveEnvironment(for: store), queue: queue)
    }
    
    /// Initializes the middleware with a store and a custom environment.
    ///
    /// This initializer creates a middleware with a custom environment and a queue using the middleware's type name as the label.
    /// - Parameters:
    ///   - store: The store that the middleware will interact with.
    ///   - environment: The custom environment for the middleware.
    init(store: some Store<State>, environment: Environment) {
        let queueLabel = String(describing: Self.self)
        self.init(store: store, environment: environment, queue: DispatchQueue(label: queueLabel))
    }
    
    /// Initializes the middleware with a store, a custom environment, and a specific dispatch queue.
    ///
    /// This initializer creates a middleware with the specified environment and queue.
    /// - Parameters:
    ///   - store: The store that the middleware will interact with.
    ///   - environment: The custom environment for the middleware.
    ///   - queue: The dispatch queue for performing middleware operations.
    init(store: some Store<State>, environment: Environment, queue: DispatchQueue) {
        self.init(store: store, queue: queue)
        self.environment = environment
    }
}

// MARK: - Typealias for Middleware with Environment

/// A typealias that represents a middleware with an environment, combining `Middleware` and `EnvironmentMiddleware`.
typealias MiddlewareWithEnvironment<State> = Middleware<State> & EnvironmentMiddleware<State>
