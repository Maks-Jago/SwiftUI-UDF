//===--- Publishers+AsyncState.swift -----------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import Combine

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
        Deferred {
            Future { promise in
                Task.detached(priority: .high) {
                    let immutableState = await store.state
                    promise(.success(immutableState))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
