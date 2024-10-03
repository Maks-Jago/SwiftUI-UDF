//===--- LoggingAction.swift ----------------------------------------------===//
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

/// A structure representing an action to be logged, including metadata about the action's origin.
public struct LoggingAction: CustomDebugStringConvertible {
    
    /// The action being logged.
    public let value: any Action
    
    /// The name of the file where the action originated.
    public let fileName: String
    
    /// The name of the function where the action originated.
    public let functionName: String
    
    /// The line number in the file where the action originated.
    public let lineNumber: Int
    
    /// A description of the action, used for debugging purposes.
    private let actionDescription: String
    
    /// The internal representation of the action.
    var internalAction: InternalAction
    
    /// Initializes a new `LoggingAction` from an `InternalAction`.
    ///
    /// - Parameter internalAction: The `InternalAction` instance to be wrapped and logged.
    internal init(_ internalAction: InternalAction) {
        self.value = internalAction.value
        self.internalAction = internalAction
        self.fileName = internalAction.fileName
        self.functionName = internalAction.functionName
        self.lineNumber = internalAction.lineNumber
        self.actionDescription = internalAction.debugDescription
    }
    
    /// A textual description of the action for debugging purposes.
    public var debugDescription: String {
        actionDescription
    }
}
