//===--- DebugOnlyActionFilter.swift -------------------------------------===//
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

/// An action filter that includes actions only in debug builds.
/// Useful for logging or debugging purposes without affecting release builds.
public struct DebugOnlyActionFilter: ActionFilter {
    /// Initializes a new `DebugOnlyActionFilter`.
    public init() {}

    /// Determines whether a given action should be included based on the build configuration.
    ///
    /// - Parameter action: The action to be evaluated.
    /// - Returns: `true` if in a debug build, `false` otherwise.
    public func include(action: LoggingAction) -> Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
}

public extension ActionFilter where Self == DebugOnlyActionFilter {
    /// A static property that provides an action filter for debug builds only.
    static var debugOnly: ActionFilter { DebugOnlyActionFilter() }
}
