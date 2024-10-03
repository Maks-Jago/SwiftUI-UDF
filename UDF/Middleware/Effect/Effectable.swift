//===--- Effectable.swift ----------------------------------------===//
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
import Combine

/// A namespace for defining various effect-related utilities and operations.
public enum Effects {}

/// A protocol that represents an effect capable of producing actions, conforming to `PureEffect`.
///
/// `Effectable` is a specialized form of `PureEffect` where the output is always an `Action` and the failure is `Never`.
/// It provides a set of operators for transforming and filtering effects, allowing developers to build complex side effects
/// in a declarative manner.
public protocol Effectable: PureEffect where Output == any Action, Failure == Never {}

// MARK: - Operators

public extension Effectable {
    
    /// Filters actions emitted by the effect based on the provided condition.
    ///
    /// This operator allows filtering of the effect's output, ensuring only actions that meet the specified condition
    /// are passed downstream.
    ///
    /// - Parameter isIncluded: A closure that takes an action of type `A` and returns a Boolean indicating whether the action should be included.
    /// - Returns: An effect that emits only actions that satisfy the given condition.
    func filterAction<A: Action>(_ isIncluded: @escaping (A) -> Bool) -> some Effectable {
        Effects.Filter<A>(self, isIncluded)
    }
    
    /// Delays the emission of actions by a specified duration.
    ///
    /// This operator introduces a delay for actions emitted by the effect, allowing you to control when actions are processed.
    ///
    /// - Parameters:
    ///   - duration: The time interval to delay each action.
    ///   - queue: The dispatch queue on which to delay the action.
    /// - Returns: An effect that emits actions after the specified delay.
    func delay(duration: TimeInterval, queue: DispatchQueue) -> some Effectable {
        Effects.Delay(self, duration, queue: queue)
    }
}
