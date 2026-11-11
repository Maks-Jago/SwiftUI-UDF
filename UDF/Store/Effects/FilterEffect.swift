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

import Combine
import Foundation

public extension Effects {
    /// `Filter` is an effect that filters actions emitted by an effect based on a given condition.
    /// This is useful for allowing only specific actions to pass through in an effect pipeline.
    /// When the wrapped effect conforms to `EnvironmentEffect`, middleware dependencies are forwarded to that effect.
    ///
    /// - Note: The filter condition is applied to actions of a specific type, `A`.
    struct Filter<A: Action, Wrapped: Effectable>: Effectable {
        private var effect: Wrapped
        private let isIncluded: (A) -> Bool

        /// Builds the filtered publisher using the wrapped effect's current dependencies.
        public var upstream: AnyPublisher<any Action, Never> {
            Publishers.Filter(upstream: effect) { [isIncluded] anyAction -> Bool in
                guard let action = anyAction as? A else {
                    preconditionFailure("anyAction.value type must be of type A")
                }

                return isIncluded(action)
            }
            .eraseToAnyPublisher()
        }

        /// Initializes a new `Filter` effect.
        ///
        /// - Parameters:
        ///   - effect: An existing effect to be filtered.
        ///   - isInclude: A closure that takes an action of type `A` and returns a Boolean value indicating whether the action should pass
        /// through.
        ///
        /// - Precondition: The type of action emitted by the effect must be of type `A`.
        public init(_ effect: Wrapped, _ isInclude: @escaping (A) -> Bool) {
            self.effect = effect
            self.isIncluded = isInclude
        }
    }
}

extension Effects.Filter: EnvironmentEffect where Wrapped: EnvironmentEffect {
    public typealias Environment = Wrapped.Environment

    /// Forwards middleware dependencies to the wrapped effect before subscription.
    public var environment: Environment! {
        get { effect.environment }
        set { effect.environment = newValue }
    }
}
