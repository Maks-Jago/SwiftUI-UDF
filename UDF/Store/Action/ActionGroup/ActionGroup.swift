//===--- ActionGroup.swift ------------------------------------------===//
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

/// `ActionGroup` is a container that groups multiple actions into a single entity.
/// This is useful when multiple actions need to be dispatched or handled together.
/// It provides various methods to append, insert, and manipulate actions within the group.
public struct ActionGroup: Action {
    
    /// An array of actions contained in this group.
    /// The internal `_actions` array is mapped to extract the underlying actions.
    public var actions: [any Action] {
        _actions.map { $0.value }
    }
    
    /// The internal storage of actions. Each action is wrapped in an `InternalAction` object.
    var _actions: [InternalAction]
    
    /// Initializes an `ActionGroup` with a single action.
    ///
    /// - Parameters:
    ///   - action: The action to be added to the group.
    ///   - fileName: The name of the file where this action was created. Defaults to the current file.
    ///   - functionName: The name of the function where this action was created. Defaults to the current function.
    ///   - lineNumber: The line number where this action was created. Defaults to the current line.
    public init(
        action: some Action,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        _actions = [
            InternalAction(
                action,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        ]
    }
    
    /// Initializes an `ActionGroup` with an array of actions.
    ///
    /// - Parameters:
    ///   - actions: An array of actions to be added to the group.
    ///   - fileName: The name of the file where these actions were created. Defaults to the current file.
    ///   - functionName: The name of the function where these actions were created. Defaults to the current function.
    ///   - lineNumber: The line number where these actions were created. Defaults to the current line.
    public init(
        actions: [any Action],
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        _actions = actions.map {
            InternalAction(
                $0,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }
    
    /// Initializes an `ActionGroup` using a result builder.
    ///
    /// - Parameter builder: A closure that returns an `ActionGroup`.
    public init(@ActionGroupBuilder _ builder: () -> ActionGroup) {
        self = builder()
    }
    
    /// Internal initializer that accepts an array of `InternalAction`.
    ///
    /// - Parameter internalActions: An array of `InternalAction`.
    init(internalActions: [InternalAction]) {
        _actions = internalActions
    }
    
    /// Initializes an empty `ActionGroup`.
    public init() {
        _actions = []
    }
}

// MARK: - CustomDebugStringConvertible
extension ActionGroup: CustomDebugStringConvertible {
    /// A textual representation of the `ActionGroup`, useful for debugging.
    public var debugDescription: String {
        """
        ActionGroup {
                        \(_actions.map(\.debugDescription).joined(separator: "\n\t\t\t\t") )
        }
        """
    }
}

// MARK: - Equatable
extension ActionGroup {
    /// Compares two `ActionGroup` instances for equality.
    public static func == (lhs: ActionGroup, rhs: ActionGroup) -> Bool {
        lhs._actions == rhs._actions
    }
}

// MARK: - Append Actions
extension ActionGroup {
    
    /// Appends a single action to the group.
    ///
    /// - Parameters:
    ///   - action: The action to be appended.
    ///   - fileName: The name of the file where this action is appended. Defaults to the current file.
    ///   - functionName: The name of the function where this action is appended. Defaults to the current function.
    ///   - lineNumber: The line number where this action is appended. Defaults to the current line.
    public mutating func append(
        action: some Action,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        _actions.append(
            InternalAction(
                action,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        )
    }
    
    /// Appends multiple actions to the group.
    ///
    /// - Parameters:
    ///   - actions: An array of actions to be appended.
    ///   - fileName: The name of the file where these actions are appended. Defaults to the current file.
    ///   - functionName: The name of the function where these actions are appended. Defaults to the current function.
    ///   - lineNumber: The line number where these actions are appended. Defaults to the current line.
    public mutating func append(
        actions: [any Action],
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        _actions.append(
            contentsOf: actions.map {
                InternalAction(
                    $0,
                    fileName: fileName,
                    functionName: functionName,
                    lineNumber: lineNumber
                )
            }
        )
    }
}

// MARK: - Insert Actions
extension ActionGroup {
    
    /// Inserts a single action at a specified position in the group.
    ///
    /// - Parameters:
    ///   - action: The action to be inserted.
    ///   - at: The index at which the action should be inserted. Defaults to `0`.
    ///   - fileName: The name of the file where this action is inserted. Defaults to the current file.
    ///   - functionName: The name of the function where this action is inserted. Defaults to the current function.
    ///   - lineNumber: The line number where this action is inserted. Defaults to the current line.
    public mutating func insert(
        action: some Action,
        at: Int = 0,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        _actions.insert(
            InternalAction(
                action,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            ),
            at: at
        )
    }
}
