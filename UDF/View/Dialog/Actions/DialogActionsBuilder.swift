//===--- DialogActionsBuilder.swift ----------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2025 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

/// A result builder that constructs an array of `DialogAction` elements.
///
/// `DialogActionsBuilder` allows for building an array of `DialogAction` elements in a declarative way,
/// using Swift's result builder syntax. It enables the creation of dialog actions in a more readable and
/// flexible manner, similar to how SwiftUI uses result builders for view construction.
///
/// This is a direct migration from `AlertActionsBuilder` with identical functionality, ensuring compatibility
/// with existing code while extending support to all dialog styles.
///
/// This result builder provides various methods for building dialog actions based on different input types,
/// including conditionals, optionals, and expressions.
///
/// ## Usage:
/// ```swift
/// @DialogActionsBuilder
/// func buildActions() -> [any DialogAction] {
///     DialogButton.default("OK") {
///         print("OK tapped")
///     }
///     
///     if showCancel {
///         DialogButton.cancel("Cancel")
///     }
///     
///     DialogTextField(title: "Input", text: $inputText)
/// }
/// ```
@resultBuilder
public enum DialogActionsBuilder {
    /// Chooses the first component in an `if-else` conditional block.
    ///
    /// - Parameter component: An array of `DialogAction` elements to include if the condition is true.
    /// - Returns: The array of `DialogAction` elements.
    public static func buildEither(first component: [any DialogAction]) -> [any DialogAction] {
        component
    }
    
    /// Chooses the second component in an `if-else` conditional block.
    ///
    /// - Parameter component: An array of `DialogAction` elements to include if the condition is false.
    /// - Returns: The array of `DialogAction` elements.
    public static func buildEither(second component: [any DialogAction]) -> [any DialogAction] {
        component
    }
    
    /// Builds an optional component.
    ///
    /// - Parameter component: An optional array of `DialogAction` elements.
    /// - Returns: The array of `DialogAction` elements, or an empty array if the component is `nil`.
    public static func buildOptional(_ component: [any DialogAction]?) -> [any DialogAction] {
        component ?? []
    }
    
    /// Builds a single `DialogAction` expression into an array.
    ///
    /// - Parameter expression: A `DialogAction` element.
    /// - Returns: An array containing the single `DialogAction` element.
    public static func buildExpression(_ expression: some DialogAction) -> [any DialogAction] {
        [expression]
    }
    
    /// Builds an empty array when an expression is of type `Void`.
    ///
    /// - Parameter expression: A `Void` type expression.
    /// - Returns: An empty array of `DialogAction` elements.
    public static func buildExpression(_ expression: ()) -> [any DialogAction] {
        []
    }
    
    /// Builds an array of `DialogAction` elements with limited availability.
    ///
    /// - Parameter components: An array of `DialogAction` elements with limited availability.
    /// - Returns: The array of `DialogAction` elements.
    public static func buildLimitedAvailability(_ components: [any DialogAction]) -> [any DialogAction] {
        components
    }
    
    /// Combines multiple arrays of `DialogAction` elements into a single array.
    ///
    /// - Parameter components: A variadic list of arrays containing `DialogAction` elements.
    /// - Returns: A flattened array of all `DialogAction` elements.
    public static func buildBlock(_ components: [any DialogAction]...) -> [any DialogAction] {
        components.flatMap { $0 }
    }
    
    /// Combines an array of `DialogAction` arrays into a single array.
    ///
    /// - Parameter components: An array of arrays, each containing `DialogAction` elements.
    /// - Returns: A flattened array of all `DialogAction` elements.
    public static func buildArray(_ components: [[any DialogAction]]) -> [any DialogAction] {
        components.flatMap { $0 }
    }
}

// MARK: - Builder Helpers
/// Helper functions for working with `DialogActionsBuilder` results.
public enum DialogActionsBuilderHelpers {
    /// Counts the actions of a specific type in the builder result.
    ///
    /// - Parameters:
    ///   - actions: The actions to analyze.
    ///   - type: The type of action to count.
    /// - Returns: The number of actions of the specified type.
    public static func count<T: DialogAction>(
        actions: [any DialogAction],
        ofType type: T.Type
    ) -> Int {
        actions.compactMap { $0 as? T }.count
    }
    
    /// Filters actions to only include those of a specific type.
    ///
    /// - Parameters:
    ///   - actions: The actions to filter.
    ///   - type: The type of action to include.
    /// - Returns: An array containing only actions of the specified type.
    public static func filter<T: DialogAction>(
        actions: [any DialogAction],
        toType type: T.Type
    ) -> [T] {
        actions.compactMap { $0 as? T }
    }
    
    /// Checks if the actions contain any of a specific type.
    ///
    /// - Parameters:
    ///   - actions: The actions to check.
    ///   - type: The type of action to look for.
    /// - Returns: True if at least one action of the specified type is found.
    public static func contains<T: DialogAction>(
        actions: [any DialogAction],
        actionOfType type: T.Type
    ) -> Bool {
        actions.contains { $0 is T }
    }
    
    /// Groups actions by their type for analysis.
    ///
    /// - Parameter actions: The actions to group.
    /// - Returns: A dictionary mapping action types to their counts.
    public static func groupByType(actions: [any DialogAction]) -> [String: Int] {
        var groups: [String: Int] = [:]
        
        for action in actions {
            let typeName = String(describing: type(of: action))
            groups[typeName, default: 0] += 1
        }
        
        return groups
    }
}
