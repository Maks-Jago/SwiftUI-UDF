//===--- Initable.swift ----------------------------------------------===//
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

/// A protocol representing types that can be initialized with a default initializer.
/// Conforming types must implement an `init()` method.
public protocol Initable {
    init()
}

// Conformances to the `Initable` protocol for standard collection types.
extension Dictionary: Initable {}
extension Set: Initable {}
extension Array: Initable {}
