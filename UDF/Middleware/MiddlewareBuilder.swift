//===--- MiddlewareBuilder.swift ----------------------------------===//
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

/// A result builder that constructs an array of `MiddlewareWrapper` instances.
///
/// `MiddlewareBuilder` simplifies the creation of middleware collections in the UDF architecture. It allows
/// the use of a declarative syntax to define middleware instances and types within a `buildBlock`.
@resultBuilder
public enum MiddlewareBuilder<State: AppReducer> {
    
    /// Combines multiple `MiddlewareWrapper` components into a single array.
    ///
    /// - Parameter components: Variadic list of `MiddlewareWrapper` components.
    /// - Returns: An array of `MiddlewareWrapper` instances.
    public static func buildBlock(_ components: MiddlewareWrapper<State>...) -> [MiddlewareWrapper<State>] {
        components.map { $0 }
    }
    
    /// Wraps a middleware instance in a `MiddlewareWrapper`.
    ///
    /// - Parameter expression: An instance of a middleware.
    /// - Returns: A `MiddlewareWrapper` containing the middleware instance.
    public static func buildExpression(_ expression: some Middleware<State>) -> MiddlewareWrapper<State> {
        .init(instance: expression)
    }
    
    /// Wraps a middleware type in a `MiddlewareWrapper`.
    ///
    /// - Parameter expression: A type of middleware conforming to `Middleware`.
    /// - Returns: A `MiddlewareWrapper` containing the middleware type.
    public static func buildExpression(_ expression: any Middleware<State>.Type) -> MiddlewareWrapper<State> {
        .init(type: expression)
    }
}

/// A wrapper that holds a middleware instance or type.
///
/// `MiddlewareWrapper` is used to encapsulate either an instance of a middleware or its type.
/// This allows for a flexible way to register middleware in the UDF architecture, supporting both
/// instantiated and non-instantiated middleware components.
public struct MiddlewareWrapper<State: AppReducer> {
    
    /// An optional instance of the middleware.
    var instance: (any Middleware<State>)?
    
    /// The type of the middleware.
    var type: any Middleware<State>.Type
    
    /// Initializes the wrapper with an instance of a middleware.
    ///
    /// - Parameter instance: An instance of a middleware.
    init(instance: any Middleware<State>) {
        self.instance = instance
        self.type = Swift.type(of: instance)
    }
    
    /// Initializes the wrapper with a middleware type.
    ///
    /// - Parameter type: A middleware type conforming to `Middleware`.
    init(type: any Middleware<State>.Type) {
        self.instance = nil
        self.type = type
    }
}
