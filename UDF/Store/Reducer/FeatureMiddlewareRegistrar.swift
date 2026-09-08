//===--- FeatureMiddlewareRegistrar.swift --------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

/// Gathers the middleware every feature owns, then subscribes the whole set to the store at once.
///
/// A feature names its middleware and the environment it runs on; it never builds one. Construction needs
/// the store, which is supplied later, when the whole set is subscribed together. That is what
/// keeps a feature module free of any reference to the store, and its middleware free to stay `internal`.
///
/// ```swift
/// public static func registerMiddlewares(in registrar: FeatureMiddlewareRegistrar<AppState>) {
///     registrar.add(ProfileMiddleware<AppState>.self, environment: AppState.Environments.profile)
/// }
/// ```
public final class FeatureMiddlewareRegistrar<State: AppReducer>: @unchecked Sendable {
    /// Deferred construction. The store is not known while a feature is registering.
    private var factories: [(any Store<State>) -> any _Middleware<State>] = []

    init() {}

    /// Registers middleware whose environment the composing app supplies.
    ///
    /// - Parameters:
    ///   - middlewareType: The middleware to register.
    ///   - environment: The environment it runs on.
    public func add<M: FeatureMiddleware<State>>(_ middlewareType: M.Type, environment: M.Environment)
        where M.State == State
    {
        factories.append { store in middlewareType.init(store: store, environment: environment) }
    }

    /// Registers middleware whose environment the composing app supplies, on a queue of its own.
    ///
    /// - Parameters:
    ///   - middlewareType: The middleware to register.
    ///   - environment: The environment it runs on.
    ///   - queue: The queue the middleware performs its work on.
    public func add<M: FeatureMiddleware<State>>(_ middlewareType: M.Type, environment: M.Environment, on queue: DispatchQueue)
        where M.State == State
    {
        factories.append { store in middlewareType.init(store: store, environment: environment, queue: queue) }
    }

    /// Builds everything registered and subscribes the whole set in a single call.
    ///
    /// One call rather than one per feature is the point: subscribing hops onto the store actor and
    /// waits for it, so a hundred features would otherwise mean a hundred waits at launch. An app that
    /// registered nothing skips even that one.
    ///
    /// - Parameter store: The store the middleware is subscribed to.
    func register(in store: InternalStore<State>) {
        let middlewares = factories.map { $0(store) }
        guard !middlewares.isEmpty else {
            return
        }

        executeSynchronously {
            await store.subscribe(middlewares)
        }
    }
}
