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
/// from `store` and completes; it does not observe subsequent state changes.
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
///     struct LoadProfileEffect: StateEffectable, Sendable {
///         var environment: ProfileMiddleware.Environment!
///         let store: any Store<AppState>
///
///         init(store: some Store<AppState>) {
///             self.store = store
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

    /// The store whose actor-isolated state is accessed through `statePublisher`.
    var store: any Store<State> { get }
    
    /// A publisher that asynchronously emits one current state snapshot for each subscription, then completes.
    /// Subscribe again to read updated state.
    var statePublisher: AnyPublisher<State, Never> { get }
}

public extension StateEffectable {
    /// Provides the default snapshot publisher using `Publishers.IsolatedState(from:)`.
    var statePublisher: AnyPublisher<State, Never> {
        Publishers
            .IsolatedState(from: store)
            .eraseToAnyPublisher()
    }
}
