//===--- HookBuilder.swift -----------------------------------------===//
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

/// A result builder that facilitates the construction of a collection of `Hook` instances.
///
/// `HookBuilder` provides a syntax for aggregating hooks using a Swift result builder, allowing for more readable and flexible hook creation.
@resultBuilder
public struct HookBuilder<State: AppReducer> {
    
    /// Combines multiple `Hook` components into an array of hooks.
    ///
    /// - Parameter components: A variadic list of `Hook` instances.
    /// - Returns: An array containing the provided `Hook` instances.
    public static func buildBlock(_ components: Hook<State>...) -> [Hook<State>] {
        components
    }
    
    /// Converts a single `Hook` expression into a `Hook`.
    ///
    /// - Parameter expression: A single `Hook` expression.
    /// - Returns: The same `Hook` instance.
    public static func buildExpression(_ expression: Hook<State>) -> Hook<State> {
        expression
    }
    
    /// Optionally includes a `Hook` in the resulting collection if it exists.
    ///
    /// - Parameter component: An optional `Hook` instance.
    /// - Returns: An array containing the `Hook` if it exists, otherwise an empty array.
    public static func buildOptional(_ component: Hook<State>?) -> [Hook<State>] {
        component.map { [$0] } ?? []
    }
    
    /// Chooses between two collections of hooks.
    ///
    /// - Parameter component: The first collection of `Hook` instances.
    /// - Returns: The provided collection of `Hook`.
    public static func buildEither(first component: [Hook<State>]) -> [Hook<State>] {
        component
    }
    
    /// Chooses between two collections of hooks.
    ///
    /// - Parameter component: The second collection of `Hook` instances.
    /// - Returns: The provided collection of `Hook`.
    public static func buildEither(second component: [Hook<State>]) -> [Hook<State>] {
        component
    }
    
    /// Flattens an array of arrays of `Hook` instances into a single array.
    ///
    /// - Parameter components: An array of arrays containing `Hook` instances.
    /// - Returns: A flattened array of `Hook` instances.
    public static func buildArray(_ components: [[Hook<State>]]) -> [Hook<State>] {
        components.flatMap { $0 }
    }
    
    /// Constructs an array containing the first partial block of the `Hook`.
    ///
    /// - Parameter first: The first `Hook` instance.
    /// - Returns: An array containing the first `Hook`.
    public static func buildPartialBlock(first: Hook<State>) -> [Hook<State>] {
        [first]
    }
    
    /// Combines an accumulated collection of hooks with the next hook.
    ///
    /// - Parameters:
    ///   - accumulated: The accumulated collection of `Hook` instances.
    ///   - next: The next `Hook` to be added.
    /// - Returns: An updated array containing all hooks.
    public static func buildPartialBlock(accumulated: [Hook<State>], next: Hook<State>) -> [Hook<State>] {
        accumulated + [next]
    }
    
    /// Returns the final result of building a collection of `Hook` instances.
    ///
    /// - Parameter component: The final array of `Hook` instances.
    /// - Returns: The final array of `Hook` instances.
    public static func buildFinalResult(_ component: [Hook<State>]) -> [Hook<State>] {
        component
    }
}
