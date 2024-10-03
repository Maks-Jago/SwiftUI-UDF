//===--- Hashable.swift --------------------------------------------===//
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

public extension Hashable {
    /// Compares an `AnyHashable` instance with a `Hashable` instance.
    ///
    /// - Parameters:
    ///   - lhs: The `AnyHashable` instance.
    ///   - rhs: The `Hashable` instance.
    /// - Returns: A Boolean value indicating whether the two values are equal.
    static func ==(lhs: AnyHashable, rhs: Self) -> Bool {
        lhs == AnyHashable(rhs)
    }
}

public extension Hashable {
    /// Compares a `Hashable` instance with an `AnyHashable` instance.
    ///
    /// - Parameters:
    ///   - lhs: The `Hashable` instance.
    ///   - rhs: The `AnyHashable` instance.
    /// - Returns: A Boolean value indicating whether the two values are equal.
    static func ==(lhs: Self, rhs: AnyHashable) -> Bool {
        AnyHashable(lhs) == rhs
    }
}

public extension Hashable {
    /// Compares an optional `AnyHashable` instance with a `Hashable` instance.
    ///
    /// - Parameters:
    ///   - lhs: An optional `AnyHashable` instance.
    ///   - rhs: The `Hashable` instance.
    /// - Returns: A Boolean value indicating whether the two values are equal.
    static func ==(lhs: AnyHashable?, rhs: Self) -> Bool {
        switch lhs {
        case .some(let value):
            return value == rhs
        default:
            return false
        }
    }
}

public extension Hashable {
    /// Compares a `Hashable` instance with an optional `AnyHashable` instance.
    ///
    /// - Parameters:
    ///   - lhs: The `Hashable` instance.
    ///   - rhs: An optional `AnyHashable` instance.
    /// - Returns: A Boolean value indicating whether the two values are equal.
    static func ==(lhs: Self, rhs: AnyHashable?) -> Bool {
        switch rhs {
        case .some(let value):
            return lhs == value
        default:
            return false
        }
    }
}
