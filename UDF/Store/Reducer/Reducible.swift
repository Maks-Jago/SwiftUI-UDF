//===--- Reducing.swift ------------------------------------------===//
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

/// A protocol that represents an entity capable of reducing actions to update its internal state.
///
/// The `Reducing` protocol is designed to be adopted by types that wish to respond to dispatched actions and mutate their
/// state accordingly. It extends `IsEquatable` for custom equality logic and `Initable` to ensure that conforming types
/// can be initialized with a default initializer.
public protocol Reducing: Initable, IsEquatable {
    /// Reduces the current state based on the provided action.
    ///
    /// Implementations of this method define how a particular action should affect the state of the conforming type.
    /// The default implementation is a no-op, which allows conforming types to selectively implement action handling.
    ///
    /// - Parameter action: An action that potentially affects the current state.
    mutating func reduce(_ action: some Action)
}

public extension Reducing {
    /// A default implementation of the `reduce(_:)` method that does nothing.
    ///
    /// This allows conforming types to choose which actions they handle and ignore others.
    mutating func reduce(_ action: some Action) {}
}

/// A type that conforms to both `Reducing` and `Equatable`.
///
/// `Reducible` is used when a type needs to implement state reduction logic and also conform to `Equatable` for automatic
/// equality checks. This is often used in application state management to identify changes in state and react accordingly.
public typealias Reducible = Equatable & Reducing
