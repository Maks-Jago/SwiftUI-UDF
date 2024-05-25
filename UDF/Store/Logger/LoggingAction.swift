//
//  LoggingAction.swift
//  
//
//  Created by Max Kuznetsov on 30.04.2023.
//

import Foundation

public struct LoggingAction: CustomDebugStringConvertible {
    public let value: any Action
    public let fileName: String
    public let functionName: String
    public let lineNumber: Int

    private let actionDescription: String
    var internalAction: InternalAction

    internal init(_ internalAction: InternalAction) {
        self.value = internalAction.value
        self.internalAction = internalAction
        self.fileName = internalAction.fileName
        self.functionName = internalAction.functionName
        self.lineNumber = internalAction.lineNumber
        self.actionDescription = internalAction.debugDescription
    }

    public var debugDescription: String {
        actionDescription
    }
}
