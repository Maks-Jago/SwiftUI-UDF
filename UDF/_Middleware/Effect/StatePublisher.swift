//===--- StatePublisher.swift -----------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Combine

/// A publisher that asynchronously emits a fresh snapshot of a store's application state, then completes.
///
/// Use this publisher directly with Combine operators when an effect needs state.
/// Creating a publisher or composing its pipeline does not read state. Each subscription asynchronously reads one current snapshot
/// and completes without failure. Subscribe again to read updated state, including between asynchronous steps in an effect.
/// This publisher does not observe subsequent state changes or cache previously emitted snapshots.
///
/// ```swift
/// let statePublisher = StatePublisher(store: store)
/// let subscription = statePublisher.sink { state in
///     print(state)
/// }
/// ```
public struct StatePublisher<State: AppReducer>: Publisher, Sendable {
    /// The application state snapshot emitted to subscribers.
    public typealias Output = State

    /// State snapshots are emitted without failure.
    public typealias Failure = Never

    private let store: any Store<State>

    /// Creates a publisher that retrieves snapshots from the supplied store.
    ///
    /// The store is retained for the publisher's lifetime. Initialization does not read or modify its state.
    ///
    /// - Parameter store: The store whose actor-isolated state will be read when the publisher is subscribed to.
    public init(store: any Store<State>) {
        self.store = store
    }

    /// Attaches a subscriber to a new asynchronous state snapshot subscription.
    ///
    /// The snapshot reflects state when the asynchronous read occurs. Each subscription performs a separate read and forwards
    /// cancellation to its underlying state-read task.
    ///
    /// - Parameter subscriber: The subscriber that receives the state snapshot and completion.
    public func receive<S: Subscriber>(subscriber: S) where S.Input == Output, S.Failure == Failure {
        Publishers.IsolatedState(from: store)
            .receive(subscriber: subscriber)
    }
}
