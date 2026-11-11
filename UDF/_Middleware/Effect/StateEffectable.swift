//===--- StateEffectable.swift --------------------------------------------===//
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
import Foundation

/// An action-producing Combine effect that can read fresh snapshots of application state.
///
/// Implement `upstream` to build a publisher with `any Action` output and a `Never` failure type. Call `state()` wherever the
/// pipeline needs fresh state, including inside a later `flatMap`. Each call synchronously reads the latest committed snapshot;
/// it does not observe state changes or wait for queued actions to finish. The reader does not expose the store or dispatch.
///
/// State effects use the standard Combine `execute` and `run` overloads. To receive compatible middleware dependencies,
/// also conform to `EnvironmentEffect`; the state reader is supplied during initialization. Convert failures and missing-input
/// conditions into actions within `upstream`.
///
/// ## Example
///
/// Read the token directly in `upstream`, then build the request publisher using the injected environment.
/// A missing token produces a cancellation action so the flow can leave its loading state.
///
/// ```swift
/// private extension MessageMiddleware {
///     struct MessageStateEffectable: StateEffectInitializable, EnvironmentEffect, Sendable {
///         var environment: LoadMessageEnvironment!
///         var state: @Sendable () -> AppState
///
///         init(state: @escaping @Sendable () -> AppState) {
///             self.state = state
///         }
///
///         var upstream: AnyPublisher<any Action, Never> {
///             guard let token = state().userForm.currentUser?.token else {
///                 return Just(Actions.DidCancelEffect(by: Cancellation.message) as any Action)
///                     .eraseToAnyPublisher()
///             }
///
///             return environment.loadMessage(token: token)
///                 .map { message in
///                     Actions.DidLoadItem(item: Message(content: message), id: MessageFlow.id) as any Action
///                 }
///                 .eraseToAnyPublisher()
///         }
///     }
/// }
/// ```

public protocol StateEffectable: Effectable {
    /// The application state read by this effect.
    associatedtype State: AppReducer

    /// Reads a fresh snapshot. Call again when a later pipeline step needs updated state.
    var state: @Sendable () -> State { get }
}

public extension StateEffectInitializable {
    /// Creates an effect with a synchronous state reader for the supplied store.
    ///
    /// Captures the store and delegates to ``init(state:)``. Each reader call accesses `store.currentState` without caching it.
    /// Initialization does not read state, subscribe to the effect, or configure its environment.
    /// For effects that also conform to `EnvironmentEffect`, compatible middleware dependencies are assigned during execution.
    ///
    /// - Parameter store: Any store implementation providing synchronized, synchronous state snapshots.
    init(store: any Store<State>) {
        self.init(state: { [store] in
            store.currentState
        })
    }
}

/// A state effect that can be initialized using only a synchronous state reader.
///
/// Adopt this protocol to receive the default ``init(store:)`` initializer. Implement ``init(state:)`` to store the reader
/// and initialize the effect's other properties. Effects with an environment property may need an explicit implementation because
/// a synthesized memberwise initializer that also accepts an environment does not satisfy this initializer requirement.
///
/// To receive middleware dependencies, also conform to `EnvironmentEffect`. Initializing an effect through either initializer
/// does not configure its dependencies or subscribe to its publisher.
///
/// Effects with additional required inputs, such as a profile name and avatar data, should conform directly to ``StateEffectable``
/// and provide their own initializer accepting a reader and those inputs. This protocol cannot supply values for those inputs.
public protocol StateEffectInitializable: StateEffectable {
    /// Creates an effect using the supplied closure as its source of application state.
    ///
    /// Store the reader for use by `upstream`. Call it wherever the effect needs current state.
    ///
    /// - Parameter state: The reader used to retrieve fresh state snapshots without exposing the store.
    init(state: @escaping @Sendable () -> State)
}
