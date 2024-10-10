//===--- FilterEffect.swift -----------------------------------------===//
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
import Combine

public extension Effects {
    
    /// `Filter` is an effect that filters actions emitted by an effect based on a given condition.
    /// This is useful for allowing only specific actions to pass through in an effect pipeline.
    ///
    /// - Note: The filter condition is applied to actions of a specific type, `A`.
    struct Filter<A: Action>: Effectable {
        
        /// The upstream publisher that produces the filtered actions.
        public var upstream: AnyPublisher<any Action, Never>
        
        /// Initializes a new `Filter` effect.
        ///
        /// - Parameters:
        ///   - effect: An existing effect to be filtered.
        ///   - isInclude: A closure that takes an action of type `A` and returns a Boolean value indicating whether the action should pass through.
        ///
        /// - Precondition: The type of action emitted by the effect must be of type `A`.
        public init<E: Effectable>(_ effect: E, _ isInclude: @escaping (A) -> Bool) {
            upstream = Publishers.Filter(upstream: effect) { anyAction -> Bool in
                guard let action = anyAction as? A else {
                    preconditionFailure("anyAction.value type must be of type A")
                }
                
                return isInclude(action)
            }
            .eraseToAnyPublisher()
        }
    }
}
