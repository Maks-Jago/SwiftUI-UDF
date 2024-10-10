//===--- Scope.swift ---------------------------------------------===//
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

/// A protocol that extends `IsEquatable`, representing a unit of data that can be compared for equality.
///
/// Defines a specific slice of the `ContainerState`, which will be tracked for changes.
/// Types conforming to `Scope` can leverage the `isEqual` method for equality checks.
public protocol Scope: IsEquatable {}

/// A typealias representing a `Scope` that is also `Equatable`.
///
/// `EquatableScope` is commonly used when building scopes that need both custom equality logic and automatic
/// conformance to the `Equatable` protocol.
public typealias EquatableScope = Scope & Equatable

/// A result builder that constructs instances of `Scope`.
///
/// `ScopeBuilder` simplifies the creation of scopes by allowing various data types to be combined into a single scope,
/// ensuring that they conform to `EquatableScope`. This is particularly useful when working with reducers or combining
/// multiple scopes into a unified scope.
///
/// ## Example
/// ```swift
/// let scope = ScopeBuilder.build {
///     MyScope()
///     AnotherReducer()
/// }
/// ```
@resultBuilder
public enum ScopeBuilder {
    
    /// Builds an `EquatableScope` from a given expression conforming to both `Scope` and `Equatable`.
    ///
    /// - Parameter expression: An expression that conforms to both `Scope` and `Equatable`.
    /// - Returns: An `EquatableScope` instance.
    public static func buildExpression<S: Scope & Equatable>(_ expression: S) -> some EquatableScope {
        expression
    }
    
    /// Builds an `EquatableScope` from a given expression conforming to `Reducible`.
    ///
    /// - Parameter expression: An expression that conforms to `Reducible`.
    /// - Returns: A `ReducerScope` wrapped in an `EquatableScope`.
    public static func buildExpression<R: Reducible>(_ expression: R) -> some EquatableScope {
        ReducerScope(reducer: expression)
    }
    
    /// Builds an `EquatableScope` from an optional expression conforming to `Reducible`.
    ///
    /// - Parameter expression: An optional expression that conforms to `Reducible`.
    /// - Returns: A `ReducerScope` wrapped in an `EquatableScope`.
    public static func buildExpression<R: Reducible>(_ expression: R?) -> some EquatableScope {
        ReducerScope(reducer: expression)
    }
    
    /// Builds an `EquatableScope` from an expression conforming to `AppReducer`.
    ///
    /// - Parameter expression: An expression that conforms to `AppReducer`.
    /// - Returns: An `EquatableScope` instance.
    public static func buildExpression<R: AppReducer>(_ expression: R) -> some EquatableScope {
        expression
    }
    
    /// Creates the first partial block in a scope using an expression conforming to `EquatableScope`.
    ///
    /// - Parameter scope: The first `EquatableScope` to be included in the result builder.
    /// - Returns: An `EquatableScope` instance.
    public static func buildPartialBlock<S: EquatableScope>(first scope: S) -> some EquatableScope {
        scope
    }
    
    /// Combines accumulated scopes into a single `EquatableScope` by adding the next scope.
    ///
    /// - Parameters:
    ///   - accumulated: The accumulated scope built so far.
    ///   - next: The next scope to be added.
    /// - Returns: A `CombinedScope` containing both the accumulated and next scopes.
    public static func buildPartialBlock<S1: EquatableScope, S2: EquatableScope>(accumulated: S1, next: S2) -> some EquatableScope {
        CombinedScope(accumulated, next)
    }
}
