//===--- NotificationProtocols.swift ---------------------------------===//
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

/// Base protocol for all notification content types
public protocol NotificationContentProtocol {
    var message: String { get }
}

/// Protocol for alert notifications that have both title and message
public protocol AlertNotification: NotificationContentProtocol {
    var title: String { get }
}

/// Protocol for toast notifications that only have a message
public protocol ToastNotification: NotificationContentProtocol {
    // Just inherits message from base protocol
}

/// Concrete alert notification type
public struct Alert: AlertNotification {
    public let title: String
    public let message: String
    
    public init(title: String, message: String) {
        self.title = title
        self.message = message
    }
}

/// Concrete toast notification type
public struct Toast: ToastNotification {
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}
