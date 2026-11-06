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
/// `PureEffect` and `ConcurrencyEffect` can optionally conform to this protocol to receive compatible middleware dependencies
/// when passed to `execute` or `run`. `StateEffectable` and `StateConcurrencyEffect` inherit this protocol.
/// Conforming effects that do not require external dependencies use the default `Void` environment.
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
