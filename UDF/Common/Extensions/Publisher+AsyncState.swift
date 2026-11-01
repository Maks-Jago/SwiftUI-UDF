//===--- Publisher+AsyncState.swift ---------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Combine

public extension Publisher {
    /// Pairs each upstream output with a fresh, asynchronously fetched state snapshot.
    ///
    /// Every upstream output starts a new subscription to `Publishers.IsolatedState(from:)`. The snapshot reflects state when that
    /// asynchronous read occurs, rather than when this operator is added to the pipeline. Original outputs and the upstream failure
    /// type are preserved. Each result exposes the upstream value as `output` and its associated snapshot as `state`.
    ///
    /// State is read once per output; this operator does not subscribe to state changes. Reads for successive outputs may overlap,
    /// so their results are not guaranteed to retain upstream ordering.
    ///
    /// - Parameter store: The store from which to read state for each upstream output.
    /// - Returns: A publisher of `(output: Output, state: State)` pairs with the upstream failure type.
    func withState<State: AppReducer>(from store: any Store<State>) -> AnyPublisher<(output: Output, state: State), Failure> {
        flatMap { output in
            Publishers.IsolatedState(from: store)
                .setFailureType(to: Failure.self)
                .map { state in
                    (output: output, state: state)
                }
        }
        .eraseToAnyPublisher()
    }
}
