
//===--- DelayEffect.swift -----------------------------------------===//
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
    /// `Delay` is an effect that delays the emission of actions in a given effect for a specified duration.
    /// This is useful for throttling actions, adding a delay before triggering an action, or debouncing actions in an effect pipeline.
    /// When the wrapped effect conforms to `EnvironmentEffect`, middleware dependencies are forwarded to that effect.
    struct Delay<Wrapped: Effectable>: Effectable {
        private var effect: Wrapped
        private let duration: TimeInterval
        private let queue: DispatchQueue

        /// Builds the delayed publisher using the wrapped effect's current dependencies.
        public var upstream: AnyPublisher<any Action, Never> {
            effect
                .delay(for: .seconds(duration), scheduler: queue)
                .eraseToAnyPublisher()
        }

        /// Initializes a new `Delay` effect.
        ///
        /// - Parameters:
        ///   - effect: An existing effect to be delayed.
        ///   - duration: The duration for which the effect should be delayed.
        ///   - queue: The dispatch queue on which the delay will be applied.
        public init(_ effect: Wrapped, _ duration: TimeInterval, queue: DispatchQueue) {
            self.effect = effect
            self.duration = duration
            self.queue = queue
        }
    }
}

extension Effects.Delay: EnvironmentEffect where Wrapped: EnvironmentEffect {
    public typealias Environment = Wrapped.Environment

    /// Forwards middleware dependencies to the wrapped effect before subscription.
    public var environment: Environment! {
        get { effect.environment }
        set { effect.environment = newValue }
    }
}
