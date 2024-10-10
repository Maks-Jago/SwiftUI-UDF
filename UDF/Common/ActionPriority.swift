//===--- ActionPriority.swift -------------------------------------===//
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

/// An enumeration that represents the priority level of an action within the application.
///
/// `ActionPriority` is used to define how important an action is in terms of its execution and interaction
/// within the application’s state management.
public enum ActionPriority: Sendable {
    
    /// The default priority for actions. Used when no specific priority is needed.
    case `default`
    
    /// A higher priority level, indicating that the action involves direct user interaction and should be processed promptly.
    case userInteractive
}
