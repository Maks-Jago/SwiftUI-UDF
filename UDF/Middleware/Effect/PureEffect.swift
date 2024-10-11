//===--- PureEffect.swift ----------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Combine
import Foundation

/// A protocol representing a side effect in the application that produces an output via a Combine publisher.
public protocol PureEffect<Output>: Publisher {
    /// The underlying publisher stream for this effect.
    var upstream: AnyPublisher<Output, Failure> { get }
}

public extension PureEffect {
    /// Subscribes to the effect's upstream publisher using the provided subscriber.
    ///
    /// - Parameter subscriber: The subscriber to attach to the effect's publisher.
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        self.upstream.subscribe(subscriber)
    }

    /// Transforms the effect into an action-producing publisher, handling both output and failure cases.
    ///
    /// This method maps the effect's output to an action and handles failures by catching errors and mapping them to another action.
    ///
    /// - Parameters:
    ///   - output: A closure that transforms the effect's output into an action.
    ///   - failure: A closure that transforms the effect's failure into an action.
    /// - Returns: A publisher that emits actions, encapsulating the effect's output and potential failures.
    func eraseToEffectable(
        output: @escaping (Output) -> any Action,
        failure: @escaping (Failure) -> any Action
    ) -> AnyPublisher<any Action, Never> {
        self
            .map(output)
            .catch { error in
                Just(failure(error))
            }
            .eraseToAnyPublisher()
    }
}

public extension PureEffect where Failure == Never {
    /// Transforms the effect into an action-producing publisher, handling the output only (as the failure is `Never`).
    ///
    /// - Parameter output: A closure that transforms the effect's output into an action.
    /// - Returns: A publisher that emits actions based on the effect's output.
    func eraseToEffectable(output: @escaping (Output) -> any Action) -> AnyPublisher<any Action, Never> {
        self
            .map(output)
            .eraseToAnyPublisher()
    }
}

extension AnyPublisher: PureEffect where Output == any Action, Failure == Never {
    /// The underlying publisher stream for the effect.
    public var upstream: AnyPublisher<any Action, Never> {
        self
    }
}

/// A protocol that allows conversion to an effect-producing publisher.
public protocol ErasableToEffect {
    /// Converts the conforming instance to an action-producing publisher.
    var asEffectable: AnyPublisher<any Action, Never> { get }
}
