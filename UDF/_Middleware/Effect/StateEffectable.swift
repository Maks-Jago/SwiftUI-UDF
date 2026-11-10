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
/// Implement `upstream` to build a publisher with `any Action` output and a `Never` failure type. Subscribe to `statePublisher`
/// wherever the pipeline needs state, including inside a later `flatMap`. Each subscription asynchronously reads one snapshot
/// and completes; it does not observe subsequent state changes. The publisher does not expose the store or its dispatch methods.
///
/// The middleware's `execute` overload injects a compatible environment before subscribing. Effects without external dependencies
/// use the default `Void` environment. Convert failures and missing-input conditions into actions within `upstream`.
///
/// ## Example
///
/// This effect reads the current user's token before loading a profile. The environment's `loadProfile(token:)` method returns
/// a publisher with a `Never` failure type. A missing token emits a cancellation action so the flow can leave its loading state.
///
/// ```swift
/// private extension ProfileMiddleware {
///     struct LoadProfileEffect: StateEffectInitializable, Sendable {
///         var environment: ProfileMiddleware.Environment!
///         let statePublisher: StatePublisher<AppState>
///
///         init(statePublisher: StatePublisher<AppState>) {
///             self.statePublisher = statePublisher
///         }
///
///         var upstream: AnyPublisher<any Action, Never> {
///             statePublisher
///                 .flatMap { state -> AnyPublisher<any Action, Never> in
///                     guard let token = state.userForm.currentUser?.token else {
///                         return Just(Actions.DidCancelEffect(by: Cancellation.loadProfile) as any Action)
///                             .eraseToAnyPublisher()
///                     }
///
///                     return environment.loadProfile(token: token)
///                         .map { profile in
///                             Actions.DidLoadItem(item: profile, id: ProfileFlow.id) as any Action
///                         }
///                         .eraseToAnyPublisher()
///                 }
///                 .eraseToAnyPublisher()
///         }
///     }
/// }
/// ```

public protocol StateEffectable: Effectable, EnvironmentEffect {
    /// The application state read by this effect.
    associatedtype State: AppReducer
    
    /// Reads fresh state snapshots without exposing the store
    var statePublisher: StatePublisher<State> { get }
}

public extension StateEffectInitializable {
    /// Creates an effect with a read-only state publisher for the supplied store.
    ///
    /// Wraps the store in a ``StatePublisher`` and delegates to ``init(statePublisher:)``. This initializer does not read state,
    /// subscribe to the effect, or configure its environment. Compatible middleware dependencies are assigned during execution.
    ///
    /// - Parameter store: The store from which the effect's publisher will retrieve fresh state snapshots.
    init(store: any Store<State>) {
        self.init(statePublisher: StatePublisher(store: store))
    }
}

/// A state effect that can be initialized using only a read-only state publisher.
///
/// Adopt this protocol to receive the default ``init(store:)`` initializer. Implement ``init(statePublisher:)`` to store the publisher
/// and initialize the effect's other properties. Effects with an environment property may need an explicit implementation because
/// a synthesized memberwise initializer that also accepts an environment does not satisfy this initializer requirement.
///
/// Environment injection follows the same rules as ``StateEffectable``. Initializing an effect through either initializer does
/// not configure its middleware dependencies or subscribe to its publisher.
///
/// Effects with additional required inputs, such as a profile name and avatar data, should conform directly to ``StateEffectable``
/// and provide their own initializer accepting a publisher and those inputs. This protocol cannot supply values for those inputs.
public protocol StateEffectInitializable: StateEffectable {
    /// Creates an effect using the supplied publisher as its source of application state.
    ///
    /// Store the publisher for use by `upstream`. Reading state and producing actions happen when the effect is subscribed to.
    ///
    /// - Parameter statePublisher: The publisher used to retrieve fresh state snapshots without exposing the store.
    init(statePublisher: StatePublisher<State>)
}
