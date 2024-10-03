//===--- HookType.swift -------------------------------------------===//
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

/// An enumeration representing the type of a hook.
///
/// `HookType` defines the behavior of hooks in an application state lifecycle, such as whether they are executed every time
/// or only once.
public enum HookType {
    
    /// A hook that executes under the default conditions each time its associated state changes.
    case `default`
    
    /// A hook that executes only once and is then discarded.
    case oneTime
}
