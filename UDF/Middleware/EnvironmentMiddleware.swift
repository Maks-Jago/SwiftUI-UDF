//===--- EnvironmentMiddleware.swift ------------------------------===//
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

/// A protocol that defines a middleware component with an associated environment in the UDF architecture.
///
/// `EnvironmentMiddleware` extends the standard middleware concept by introducing an `Environment` type that encapsulates
/// dependencies or services needed to handle side effects. This is particularly useful for injecting dependencies such as network clients,
/// database instances, or other external services into the middleware.
public protocol EnvironmentMiddleware<State> {
    associatedtype Environment
    associatedtype State: AppReducer
    
    /// The environment instance containing dependencies required by the middleware.
    var environment: Environment! { get set }
    
    /// Initializes the middleware with a store and a specific environment.
    ///
    /// - Parameters:
    ///   - store: The store that the middleware will interact with.
    ///   - environment: The environment instance to be used by the middleware.
    init(store: some Store<State>, environment: Environment)
    
    /// Initializes the middleware with a store, a specific environment, and a dispatch queue.
    ///
    /// - Parameters:
    ///   - store: The store that the middleware will interact with.
    ///   - environment: The environment instance to be used by the middleware.
    ///   - queue: The dispatch queue for performing middleware operations.
    init(store: some Store<State>, environment: Environment, queue: DispatchQueue)
    
    /// Builds a live environment for the middleware.
    ///
    /// This method is intended to set up an environment containing live instances of services or dependencies.
    /// - Parameter store: The store that the middleware will interact with.
    /// - Returns: A live environment instance.
    static func buildLiveEnvironment(for store: some Store<State>) -> Environment
    
    /// Builds a test environment for the middleware.
    ///
    /// This method is intended to set up an environment containing mock or test instances of services or dependencies.
    /// - Parameter store: The store that the middleware will interact with.
    /// - Returns: A test environment instance.
    static func buildTestEnvironment(for store: some Store<State>) -> Environment
}

// MARK: - Default Implementation for Void Environment

public extension EnvironmentMiddleware where Environment == Void {
    
    /// Provides a default implementation of `buildLiveEnvironment` when the environment type is `Void`.
    ///
    /// This allows middleware that does not require an environment to conform to `EnvironmentMiddleware`.
    /// - Parameter store: The store that the middleware will interact with.
    /// - Returns: An empty environment (`Void`).
    static func buildLiveEnvironment(for store: some Store<State>) -> Environment { () }
    
    /// Provides a default implementation of `buildTestEnvironment` when the environment type is `Void`.
    ///
    /// This allows middleware that does not require an environment to conform to `EnvironmentMiddleware`.
    /// - Parameter store: The store that the middleware will interact with.
    /// - Returns: An empty environment (`Void`).
    static func buildTestEnvironment(for store: some Store<State>) -> Environment { () }
}
