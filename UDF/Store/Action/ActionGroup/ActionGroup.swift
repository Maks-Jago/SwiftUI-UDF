//
//  ActionGroup.swift
//  
//
//  Created by Max Kuznetsov on 02.12.2020.
//

import Foundation

public struct ActionGroup: Action {
    public var actions: [any Action] {
        _actions.map { $0.value }
    }
    var _actions: [InternalAction]
    
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
    
    public init(
        actions: [any Action],
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        _actions = actions .map {
            InternalAction(
                $0,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }
    
    public init(@ActionGroupBuilder _ builder: () -> ActionGroup) {
        self = builder()
    }

    init(internalActions: [InternalAction]) {
        _actions = internalActions
    }
    
    public init() {
        _actions = []
    }
}

// MARK: - CustomDebugStringConvertible
extension ActionGroup: CustomDebugStringConvertible {

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
    public static func == (lhs: ActionGroup, rhs: ActionGroup) -> Bool {
        lhs._actions == rhs._actions
    }
}

// MARK: - Append Actions
extension ActionGroup {
    
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
