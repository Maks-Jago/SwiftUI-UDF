//===--- EnvironmentEffect.swift ------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

/// An effect that receives external dependencies from its middleware.
///
/// Combine effects opt in by conforming to both `PureEffect` and `EnvironmentEffect`; asynchronous effects conform to both
/// `ConcurrencyEffect` and `EnvironmentEffect`. Middleware assigns compatible dependencies through the standard `execute`,
/// `run` methods.
///
/// State-aware effects must also declare this conformance explicitly. `StateEffectable` and `StateConcurrencyEffect` provide
/// state access independently of environment injection. Conforming effects without external dependencies can use the default
/// `Void` environment.
public protocol EnvironmentEffect {
    /// The dependency type required by the effect.
    associatedtype Environment: Sendable

    /// The environment used by the effect to access external dependencies.
    /// Configure it before evaluating effect code that uses those dependencies.
    var environment: Environment! { get set }
}

public extension EnvironmentEffect {
    /// Provides an empty environment for effects that do not require external dependencies.
    var environment: Void! {
        get { () }
        set { }
    }
}

extension EnvironmentEffect {
    /// Returns this effect with a compatible environment obtained from the middleware.
    ///
    /// The middleware must conform to `EnvironmentMiddleware`, and its environment must be castable to this effect's `Environment`.
    /// If either condition is unmet, the effect is returned unchanged, including any environment already assigned to it.
    ///
    /// The concrete effect type is preserved. For value type effects, use the returned copy; the original value is not modified.
    ///
    /// ```swift
    /// let configuredEffect = effect.withEnvironment(from: middleware)
    /// ```
    ///
    /// - Parameter middleware: The middleware supplying the effect's dependencies.
    /// - Returns: The configured effect, or the current effect when no compatible environment is available.
    func withEnvironment(from middleware: any _Middleware) -> Self {
        guard
            let middleware = (middleware as? any EnvironmentMiddleware),
            let middlewareEnvironment = middleware.environment as? Environment
        else {
            return self
        }
        var effect = self
        effect.environment = middlewareEnvironment
        return effect
    }
}
