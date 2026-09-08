//===--- FeatureState.swift ---------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI

/// The reducer a feature module mounts into a host app state.
///
/// A `FeatureState` groups everything a feature owns, its forms and its flows, names the middleware that
/// belongs to it, and exposes the single view the composing app presents to enter the feature. Mounting
/// it as a property of the app state is the only step that app performs: the store finds it there at
/// launch and registers its middleware.
///
/// A feature states what it needs from its host in a single protocol and reaches the outside world only
/// through it. `Environments` carries the same name in every feature, so Swift merges the requirements
/// into one associated type and the app satisfies all of them with a single `typealias`:
///
/// ```swift
/// public protocol ProfileFeature: AppReducer {
///     associatedtype Environments: ProfileEnvironmentProviding
///
///     var profile: ProfileFeatureState<Self> { get }
/// }
///
/// public protocol ProfileEnvironmentProviding {
///     static var profile: ProfileEnvironment { get }
/// }
/// ```
///
/// Requiring the reducer as `ProfileFeatureState<Self>` is what keeps the feature's `AppState` and the
/// store's root reducer provably the same type.
///
/// The module then owns its state, its entry point and its registration, and never names a concrete app:
///
/// ```swift
/// public struct ProfileFeatureState<AppState: ProfileFeature>: FeatureState {
///     var form = ProfileForm()
///     var flow = ProfileFlow()
///
///     public init() {}
///
///     public static func entryPoint(input: User.ID) -> some View {
///         ProfileContainer<AppState>(id: input)
///     }
///
///     public static func registerMiddlewares(in registrar: FeatureMiddlewareRegistrar<AppState>) {
///         registrar.add(ProfileMiddleware<AppState>.self, environment: AppState.Environments.profile)
///     }
/// }
/// ```
///
/// The app conforms its state per feature and mounts each feature as a single property:
///
/// ```swift
/// extension AppState: ProfileFeature {}
///
/// struct AppState: AppReducer {
///     typealias Environments = AppEnvironments
///     var profile = ProfileFeatureState<AppState>()
/// }
/// ```
///
/// - Note: `FeatureState` belongs to the modular protocol set. An app composed as a single module places
///   `Form`, `Flow` and `Storage` reducers in its app state directly and never adopts it.
public protocol FeatureState<AppState>: Reducible, MiddlewareRegistering {
    /// The view the composing app presents to enter this feature.
    ///
    /// Inferred from the return type of ``FeatureState/entryPoint(input:)``, so a conforming feature
    /// writes `some View` and never names this type.
    associatedtype Destination: View

    /// Everything the feature needs in order to be entered.
    ///
    /// A feature that needs nothing declares `Void`. A feature that needs more than one value declares a
    /// type that carries them together, rather than widening this into several parameters.
    associatedtype Input

    /// Builds the feature's entry point.
    ///
    /// This is the only view the composing app is expected to present directly. Everything the feature
    /// shows beyond it is reached through the feature's own navigation.
    ///
    /// - Parameter input: The values the feature needs in order to be entered.
    /// - Returns: The feature's entry view.
    static func entryPoint(input: Input) -> Destination
}

public extension FeatureState {
    /// Registers nothing.
    ///
    /// A feature with no side effects of its own, one that only holds state and presents it, needs no
    /// middleware and says so by leaving this alone.
    static func registerMiddlewares(in registrar: FeatureMiddlewareRegistrar<AppState>) {}
}
