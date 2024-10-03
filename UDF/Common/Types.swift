//===--- Types.swift -----------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
@_exported import OrderedCollections

/// A closure that performs an action without taking any parameters.
public typealias Command = () -> ()

/// A closure that performs an action with a single parameter of type `T`.
public typealias CommandWith<T> = (T) -> ()

/// A closure that performs an action with two parameters of types `T1` and `T2`.
public typealias CommandWith2<T1, T2> = (T1, T2) -> ()

/// A closure that performs an action with three parameters of types `T1`, `T2`, and `T3`.
public typealias CommandWith3<T1, T2, T3> = (T1, T2, T3) -> ()

/// A closure that performs an action with four parameters of types `T1`, `T2`, `T3`, and `T4`.
public typealias CommandWith4<T1, T2, T3, T4> = (T1, T2, T3, T4) -> ()

/// A closure that performs an action with five parameters of types `T1`, `T2`, `T3`, `T4`, and `T5`.
public typealias CommandWith5<T1, T2, T3, T4, T5> = (T1, T2, T3, T4, T5) -> ()

/// A function that compares two equatable values for equality.
/// - Parameters:
///   - lhs: The left-hand side value of the comparison.
///   - rhs: The right-hand side value of the comparison.
/// - Returns: `true` if the values are equal; otherwise, `false`.
func areEqual<Lhs: Equatable, Rhs: Equatable>(_ lhs: Lhs, _ rhs: Rhs) -> Bool {
    guard let rhsAs = rhs as? Lhs else {
        return false
    }
    
    return lhs == rhsAs
}
