//===--- Publishers+AsyncState.swift -----------------------------------===//
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
import os

public extension Publishers {
    /// Returns an `AnyPublisher` that publishes an isolated, immutable state from the given store.
    ///
    /// This method creates a publisher that captures the current state of the store in an isolated manner,
    /// ensuring that the state is retrieved safely even in a concurrent environment. It uses `Task.detached`
    /// with a high priority to obtain the store's state and provides it as a single value to the subscribers.
    ///
    /// - Parameter store: An instance conforming to `Store<State>` from which the state is retrieved.
    /// - Returns: An `AnyPublisher` that emits the isolated state of the store once.
    static func IsolatedState<State: AppReducer>(from store: any Store<State>) -> AnyPublisher<State, Never> {
        AsyncStatePublisher(store: store)
            .eraseToAnyPublisher()
    }
}

/// A custom publisher that fetches state asynchronously and supports cancellation.
private struct AsyncStatePublisher<State: AppReducer>: Publisher {
    typealias Output = State
    typealias Failure = Never
    
    let store: any Store<State>
    
    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        subscriber.receive(
            subscription: AsyncStateSubscription(
                subscriber: AnySubscriber(subscriber),
                store: store
            )
        )
    }
}

/// A subscription that manages the concurrent task for fetching state.
private final class AsyncStateSubscription<State: AppReducer>: Subscription, @unchecked Sendable {
    private struct MutableState: @unchecked Sendable {
        var subscriber: AnySubscriber<State, Never>?
        var task: Task<Void, Never>?
    }
    
    private let state: OSAllocatedUnfairLock<MutableState>
    private let store: any Store<State>
    
    init(subscriber: AnySubscriber<State, Never>?, store: any Store<State>) {
        self.state = OSAllocatedUnfairLock(initialState: MutableState(subscriber: subscriber, task: nil))
        self.store = store
    }
    
    func request(_ demand: Subscribers.Demand) {
        state.withLock { mutableState in
            guard mutableState.task == nil, mutableState.subscriber != nil else {
                return
            }
            
            mutableState.task = Task.detached(priority: .userInitiated) { [weak self] in
                guard let fetchedState = await self?.store.state else { return }
                self?.deliver(fetchedState)
            }
        }
    }
    
    private func deliver(_ fetchedState: State) {
        state.withLock { mutableState in
            guard let sub = mutableState.subscriber else { return }
            
            _ = sub.receive(fetchedState)
            sub.receive(completion: .finished)
            
            mutableState.subscriber = nil
            mutableState.task = nil
        }
    }
    
    func cancel() {
        state.withLock { mutableState in
            mutableState.task?.cancel()
            mutableState.task = nil
            mutableState.subscriber = nil
        }
    }
}
