
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
    struct Delay: Effectable {
        /// The upstream publisher that produces the delayed actions.
        public var upstream: AnyPublisher<any Action, Never>

        /// Initializes a new `Delay` effect.
        ///
        /// - Parameters:
        ///   - effect: An existing effect to be delayed.
        ///   - duration: The duration for which the effect should be delayed.
        ///   - queue: The dispatch queue on which the delay will be applied.
        public init(_ effect: some Effectable, _ duration: TimeInterval, queue: DispatchQueue) {
            upstream = effect
                .delay(for: .seconds(duration), scheduler: queue)
                .eraseToAnyPublisher()
        }
    }
}
