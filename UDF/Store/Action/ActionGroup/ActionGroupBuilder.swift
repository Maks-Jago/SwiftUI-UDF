//===--- ActionGroupBuilder.swift ------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

/// `ActionGroupBuilder` is a custom result builder for constructing an `ActionGroup`.
/// It provides methods for handling different components (expressions, blocks, arrays, etc.) and
/// converting them into internal actions that can be processed by the UDF framework.
@resultBuilder
public enum ActionGroupBuilder {
    
    /// Converts an array of `Equatable` elements to an array of `InternalAction`.
    ///
    /// - Parameters:
    ///   - actions: An array of `Equatable` elements, which may include actions and internal actions.
    ///   - fileName: The name of the file where this method is called. Defaults to the current file.
    ///   - functionName: The name of the function where this method is called. Defaults to the current function.
    ///   - lineNumber: The line number where this method is called. Defaults to the current line.
    /// - Returns: An array of `InternalAction`.
    private static func toInternalActions(
        _ actions: [any Equatable],
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> [InternalAction] {
        
        actions.compactMap {
            switch ($0) {
            case let action as InternalAction:
                return action
            case let action as any Action:
                return InternalAction(
                    action,
                    fileName: fileName,
                    functionName: functionName,
                    lineNumber: lineNumber
                )
            default:
                return nil
            }
        }
    }
    
    /// Constructs an array of `Equatable` elements from an array of arrays.
    ///
    /// - Parameters:
    ///   - components: An array of arrays containing `Equatable` elements.
    ///   - fileName: The name of the file where this method is called. Defaults to the current file.
    ///   - functionName: The name of the function where this method is called. Defaults to the current function.
    ///   - lineNumber: The line number where this method is called. Defaults to the current line.
    /// - Returns: An array of `Equatable` elements.
    public static func buildArray(
        _ components: [[any Equatable]],
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> [any Equatable] {
        
        let actions = components.flatMap { $0 }
        return toInternalActions(
            actions,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }
    
    /// Constructs an array of `Equatable` elements from variadic components.
    ///
    /// - Parameters:
    ///   - components: Variadic arrays of `Equatable` elements.
    ///   - fileName: The name of the file where this method is called. Defaults to the current file.
    ///   - functionName: The name of the function where this method is called. Defaults to the current function.
    ///   - lineNumber: The line number where this method is called. Defaults to the current line.
    /// - Returns: An array of `Equatable` elements.
    public static func buildBlock(
        _ components: [any Equatable]...,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> [any Equatable] {
        let actions = components.flatMap { $0 }
        return toInternalActions(
            actions,
            fileName: fileName,
            functionName: functionName,
            lineNumber: lineNumber
        )
    }
    
    /// Converts a single action expression into an array of `Equatable`.
    ///
    /// - Parameters:
    ///   - expression: The action to be converted.
    ///   - fileName: The name of the file where this method is called. Defaults to the current file.
    ///   - functionName: The name of the function where this method is called. Defaults to the current function.
    ///   - lineNumber: The line number where this method is called. Defaults to the current line.
    /// - Returns: An array containing the converted `InternalAction`.
    public static func buildExpression(
        _ expression: some Action,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> [any Equatable] {
        [
            InternalAction(
                expression,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        ]
    }
    
    /// Handles a `Void` expression, returning an empty array.
    ///
    /// - Parameter expression: A `Void` expression.
    /// - Returns: An empty array of `Equatable`.
    public static func buildExpression(_ expression: Void) -> [any Equatable] {
        []
    }
    
    /// Converts an optional `Equatable` expression into an array.
    ///
    /// - Parameter expression: An optional `Equatable` expression.
    /// - Returns: An array containing the unwrapped expression, if available.
    public static func buildExpression(_ expression: (any Equatable)?) -> [any Equatable] {
        [expression].compactMap({ $0 })
    }
    
    /// Handles an optional component, returning either the component or an empty array.
    ///
    /// - Parameter component: An optional array of `Equatable`.
    /// - Returns: An array of `Equatable`, or an empty array if the component is `nil`.
    public static func buildOptional(_ component: [any Equatable]?) -> [any Equatable] {
        component ?? []
    }
    
    /// Handles the first component in a conditional statement.
    ///
    /// - Parameter component: An array of `Equatable`.
    /// - Returns: The same array of `Equatable`.
    public static func buildEither(first component: [any Equatable]) -> [any Equatable] {
        component
    }
    
    /// Handles the second component in a conditional statement.
    ///
    /// - Parameter component: An array of `Equatable`.
    /// - Returns: The same array of `Equatable`.
    public static func buildEither(second component: [any Equatable]) -> [any Equatable] {
        component
    }
    
    /// Handles components with limited availability, such as those behind a compiler flag.
    ///
    /// - Parameter component: An array of `Equatable`.
    /// - Returns: The same array of `Equatable`.
    public static func buildLimitedAvailability(_ component: [any Equatable]) -> [any Equatable] {
        component
    }
    
    /// Builds the final result of the builder and wraps it in an `ActionGroup`.
    ///
    /// - Parameters:
    ///   - component: An array of `Equatable` elements to be wrapped in an `ActionGroup`.
    ///   - fileName: The name of the file where this method is called. Defaults to the current file.
    ///   - functionName: The name of the function where this method is called. Defaults to the current function.
    ///   - lineNumber: The line number where this method is called. Defaults to the current line.
    /// - Returns: An `ActionGroup` containing the internal actions.
    public static func buildFinalResult(
        _ component: [any Equatable],
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> ActionGroup {
        
        ActionGroup(
            internalActions: toInternalActions(
                component,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        )
    }
}
