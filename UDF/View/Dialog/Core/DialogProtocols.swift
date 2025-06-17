//===--- DialogProtocols.swift ---------------------------------===//
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

/// Base protocol for all dialog content types
public protocol DialogContentProtocol {
    var message: String { get }
}

/// Protocol for alert dialogs that have both title and message
public protocol AlertDialog: DialogContentProtocol {
    var title: String { get }
}

/// Protocol for toast dialogs that only have a message
public protocol ToastDialog: DialogContentProtocol {
    // Just inherits message from base protocol
}

/// Concrete alert dialog type
public struct Alert: AlertDialog {
    public let title: String
    public let message: String
    
    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}

/// Concrete toast dialog type
public struct Toast: ToastDialog {
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}
