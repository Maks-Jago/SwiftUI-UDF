//===--- StringDescribingActionDescriptor.swift ---------------------------===//
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

/// An `ActionDescriptor` that generates a string description for a given action.
public final class StringDescribingActionDescriptor: Sendable, ActionDescriptor {
    /// Initializes a new instance of `StringDescribingActionDescriptor`.
    public init() {}

    /// Returns a string description for the specified logging action.
    ///
    /// - Parameter action: The `LoggingAction` for which to generate a description.
    /// - Returns: A string representation of the `LoggingAction`.
    public func description(for action: LoggingAction) -> String {
        String(describing: action)
    }
}
