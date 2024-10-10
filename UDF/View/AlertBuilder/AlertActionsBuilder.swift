
//===--- AlertActionsBuilder.swift ---------------------------------------===//
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

/// A result builder that constructs an array of `AlertAction` elements.
///
/// `AlertActionsBuilder` allows for building an array of `AlertAction` elements in a declarative way,
/// using Swift's result builder syntax. It enables the creation of alert actions in a more readable and
/// flexible manner, similar to how SwiftUI uses result builders for view construction.
///
/// This result builder provides various methods for building alert actions based on different input types,
/// including conditionals, optionals, and expressions.
@resultBuilder
public enum AlertActionsBuilder {
    
    /// Chooses the first component in an `if-else` conditional block.
    ///
    /// - Parameter component: An array of `AlertAction` elements to include if the condition is true.
    /// - Returns: The array of `AlertAction` elements.
    public static func buildEither(first component: [any AlertAction]) -> [any AlertAction] {
        component
    }
    
    /// Chooses the second component in an `if-else` conditional block.
    ///
    /// - Parameter component: An array of `AlertAction` elements to include if the condition is false.
    /// - Returns: The array of `AlertAction` elements.
    public static func buildEither(second component: [any AlertAction]) -> [any AlertAction] {
        component
    }
    
    /// Builds an optional component.
    ///
    /// - Parameter component: An optional array of `AlertAction` elements.
    /// - Returns: The array of `AlertAction` elements, or an empty array if the component is `nil`.
    public static func buildOptional(_ component: [any AlertAction]?) -> [any AlertAction] {
        component ?? []
    }
    
    /// Builds a single `AlertAction` expression into an array.
    ///
    /// - Parameter expression: An `AlertAction` element.
    /// - Returns: An array containing the single `AlertAction` element.
    public static func buildExpression(_ expression: some AlertAction) -> [any AlertAction] {
        [expression]
    }
    
    /// Builds an empty array when an expression is of type `Void`.
    ///
    /// - Parameter expression: A `Void` type expression.
    /// - Returns: An empty array of `AlertAction` elements.
    public static func buildExpression(_ expression: ()) -> [any AlertAction] {
        []
    }
    
    /// Builds an array of `AlertAction` elements with limited availability.
    ///
    /// - Parameter components: An array of `AlertAction` elements with limited availability.
    /// - Returns: The array of `AlertAction` elements.
    static func buildLimitedAvailability(_ components: [any AlertAction]) -> [any AlertAction] {
        components
    }
    
    /// Combines multiple arrays of `AlertAction` elements into a single array.
    ///
    /// - Parameter components: A variadic list of arrays containing `AlertAction` elements.
    /// - Returns: A flattened array of all `AlertAction` elements.
    public static func buildBlock(_ components: [any AlertAction]...) -> [any AlertAction] {
        components.flatMap { $0 }
    }
    
    /// Combines an array of `AlertAction` arrays into a single array.
    ///
    /// - Parameter components: An array of arrays, each containing `AlertAction` elements.
    /// - Returns: A flattened array of all `AlertAction` elements.
    public static func buildArray(_ components: [[any AlertAction]]) -> [any AlertAction] {
        components.flatMap { $0 }
    }
}
