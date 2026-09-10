//===--- MiddlewareRegistering.swift ------------------------------===//
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

/// A reducer that subscribes the middleware it owns.
///
/// `EnvironmentStore` inspects the app state once, while the store is being created, and calls
/// `registerMiddlewares(in:)` on every conforming property it finds. Each call names middleware to a
/// ``FeatureMiddlewareRegistrar`` rather than subscribing it, so the whole app's middleware is subscribed in a
/// single pass no matter how many features there are. Mounting the reducer in the app state is
/// therefore the whole integration; nothing has to be wired by hand.
///
/// One call registers as many middleware as the feature owns:
///
/// ```swift
/// public static func registerMiddlewares(in registrar: FeatureMiddlewareRegistrar<AppState>) {
///     registrar.add(ProfileMiddleware<AppState>.self, environment: AppState.Environments.profile)
///     registrar.add(ProfileAnalyticsMiddleware<AppState>.self, environment: AppState.Environments.analytics)
/// }
/// ```
///
/// A feature module declares its reducer generic over the app state that hosts it, constrained to the
/// protocol the feature requires. Because the host is a generic parameter, the reducer can name
/// `EnvironmentStore<AppState>` and its own middleware without knowing the concrete app state, and it
/// reaches its environment through the host rather than building one:
///
/// ```swift
/// public struct ProfileFeatureState<AppState: ProfileFeature>: Reducible, MiddlewareRegistering {
///     var form = ProfileForm()
///     var flow = ProfileFlow()
///
///     public init() {}
///
///     public static func registerMiddlewares(in registrar: FeatureMiddlewareRegistrar<AppState>) {
///         registrar.add(ProfileMiddleware<AppState>.self, environment: AppState.Environments.profile)
///     }
/// }
/// ```
///
/// The app mounts it as it mounts any reducer, and registration follows from that:
///
/// ```swift
/// struct AppState: AppReducer, ProfileFeature {
///     typealias Environments = AppEnvironments
///     var profile = ProfileFeatureState<AppState>()
/// }
/// ```
///
/// Adoption is optional. A reducer that does not conform is left untouched, and middleware may still be
/// subscribed directly against the store.
///
/// - Important: Mount a conforming reducer directly in the app state. Only the app state's own
///   properties are inspected, so a conformer nested inside another reducer is never called and its
///   middleware never subscribed. Debug builds walk deeper solely to trap on that mistake rather than
///   let it pass in silence; release builds do not pay for the walk. This is a deliberate difference
///   from ``InitialSetup``, which does visit nested reducers.
///
/// - Important: ``MiddlewareRegistering/AppState`` must be the root reducer the store was created with,
///   never an intermediate container. Feature protocols express this by requiring the reducer as
///   `ProfileFeatureState<Self>`, which pins the two together at compile time.
///
/// - SeeAlso: ``FeatureState``, which pairs this with a feature's entry point.
public protocol MiddlewareRegistering: Reducing {
    /// The root reducer the store was created with.
    associatedtype AppState: AppReducer

    /// Names the middleware this reducer owns.
    ///
    /// Called once per conforming reducer, while the store is being built. Nothing is subscribed here:
    /// the registrar gathers every feature's middleware and subscribes the whole set at once.
    ///
    /// - Parameter registrar: The registrar to name this reducer's middleware to.
    static func registerMiddlewares(in registrar: FeatureMiddlewareRegistrar<AppState>)
}
