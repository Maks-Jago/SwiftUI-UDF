//===--- ReducibleMiddleware.swift -------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

/// A protocol that defines a middleware component with reducing capabilities in the UDF architecture.
///
/// `ReducibleMiddleware` extends the standard `Middleware` by introducing the `reduce` method, allowing the middleware
/// to handle actions and modify the state. This protocol is used when middleware needs to react to specific actions and
/// perform side effects based on those actions and the current state.
///
/// ## Requirements
/// - `reduce(_:for:)`: A method that processes an action and performs side effects based on the current state.
///
/// ## Example Usage
/// This example demonstrates how to create a `ReducibleMiddleware` by implementing a `SessionLoadingMiddleware`:
///
/// ```swift
/// final class SessionLoadingMiddleware: BaseReducibleMiddleware<AppState> {
///     enum Cancellation: Hashable {
///         case loadSession(AnyHashable)
///     }
///
///     struct Environment {
///         let loadSession: (_ token: String) async throws -> User
///     }
///
///     var environment: Environment!
///
///     func reduce(_ action: some Action, for state: AppState) {
///         switch action {
///         case let action as Actions.LoadSession:
///             execute(
///                 id: action.id,
///                 cancellation: Cancellation.loadSession(action.id),
///                 mapError: mapAPIError
///             ) { [self] id in
///                 let user = try await self.environment.loadSession(state.userForm.token)
///                 return Actions.DidReceiveCurrentUser(id: id, user: user)
///             }
///
///         default:
///             break
///         }
///     }
/// }
///
/// // MARK: - Environment build methods
/// extension SessionLoadingMiddleware {
///     static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
///         .init(
///             loadSession: { token in
///                 try await AuthAPIClient.loadCurrentUser(token: token).asUser
///             }
///         )
///     }
///
///     static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
///         .init(loadSession: { _ in User.testItem() })
///     }
/// }
/// ```
///
/// In this example:
/// - **`reduce(_:for:)`**: Handles the `Actions.LoadSession` action, triggering an asynchronous operation to load the user session based on the current state (`AppState`).
/// - **Environment:** Contains dependencies for loading a user session, with methods to build live and test environments.
///
/// ## Typealias
/// `BaseReducibleMiddleware` is a convenience typealias combining `BaseMiddleware`, `ReducibleMiddleware`, and `EnvironmentMiddleware`.
public protocol ReducibleMiddleware<State>: Middleware {
    
    /// Processes an action and performs side effects based on the current state.
    ///
    /// - Parameters:
    ///   - action: The action to be processed.
    ///   - state: The current state of the application.
    func reduce(_ action: some Action, for state: State)
}

/// A typealias for combining `BaseMiddleware`, `ReducibleMiddleware`, and `EnvironmentMiddleware`.
///
/// This typealias simplifies the creation of middleware that includes environment and reducing capabilities.
public typealias BaseReducibleMiddleware<State: AppReducer> = BaseMiddleware<State> & ReducibleMiddleware & EnvironmentMiddleware
