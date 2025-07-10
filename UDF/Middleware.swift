//===--- Middleware.swift ----------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2025 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

/// A protocol that combines observation and reduction capabilities in a single middleware component.
///
/// `Middleware` merges the functionality of both observation and reduction capabilities,
/// enabling middleware to both observe state changes and react to specific actions. This approach simplifies
/// middleware implementation when both capabilities are needed.
///
/// ## Requirements
/// - `scope(for:)`: Defines which part of the state this middleware should observe for changes.
/// - `observe(state:)`: Performs side effects in response to state changes.
/// - `reduce(_:for:)`: Processes actions and performs related side effects.
///
/// ## Example Usage
/// This example shows a unified middleware for handling user authentication:
///
/// ```swift
/// final class AuthMiddleware: Middleware<AppState> {
///     enum Cancellation: Hashable {
///         case login
///         case refreshToken
///     }
///
///     struct Environment {
///         let login: (_ email: String, _ password: String) async throws -> AuthToken
///         let refreshToken: (_ token: String) async throws -> AuthToken
///     }
///
///     var environment: Environment!
///
///     static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
///         .init(
///             login: { email, password in
///                 try await AuthAPIClient.login(email: email, password: password)
///             },
///             refreshToken: { token in
///                 try await AuthAPIClient.refreshToken(token: token)
///             }
///         )
///     }
///
///     static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
///         .init(
///             login: { _, _ in AuthToken.mock() },
///             refreshToken: { _ in AuthToken.mock() }
///         )
///     }
///
///     @ScopeBuilder
///     func scope(for state: AppState) -> Scope {
///         state.authFlow
///     }
///
///     func observe(state: AppState) {
///         switch state.authFlow {
///         case .refreshingToken:
///             execute(
///                 id: AuthFlow.id,
///                 cancellation: Cancellation.refreshToken
///             ) { [unowned self] id in
///                 let token = try await self.environment.refreshToken(state.authForm.token)
///                 return Actions.DidRefreshToken(token: token, id: id)
///             }
///         default:
///             break
///         }
///     }
///
///     func reduce(_ action: some Action, for state: AppState) {
///         switch action {
///         case let action as Actions.Login:
///             execute(
///                 id: action.id,
///                 cancellation: Cancellation.login,
///                 mapError: mapAPIError
///             ) { [unowned self] id in
///                 let token = try await self.environment.login(
///                     state.loginForm.email,
///                     state.loginForm.password
///                 )
///                 return Actions.DidLogin(token: token, id: id)
///             }
///         default:
///             break
///         }
///     }
/// }
/// ```
///
/// In this example:
/// - **`scope(for:)`** defines the middleware's observation scope to be the auth flow state.
/// - **`observe(state:)`** watches for when the auth flow enters a token refresh state and executes the refresh operation.
/// - **`reduce(_:for:)`** handles login actions by executing the login API call.
/// - **Environment:** Provides dependencies for authentication operations with both live and test implementations.
public protocol MiddlewareProtocol<State>: _Middleware where State: AppReducer {
    
    /// Defines the scope for the middleware to observe within the given state.
    ///
    /// - Parameter state: The state to define the scope for.
    /// - Returns: A `Scope` that the middleware should observe.
    @ScopeBuilder
    func scope(for state: State) -> Scope
    
    /// Observes the state changes and executes the necessary side effects.
    ///
    /// - Parameter state: The current state of the application.
    func observe(state: State)
    
    /// Processes an action and performs side effects based on the current state.
    ///
    /// - Parameters:
    ///   - action: The action to be processed.
    ///   - state: The current state of the application.
    func reduce(_ action: some Action, for state: State)
}

// MARK: - Default Implementations
public extension MiddlewareProtocol {
    @ScopeBuilder
    func scope(for state: State) -> Scope {
        .none
    }
    
    func observe(state: State) {}
    
    func reduce(_ action: some Action, for state: State) {}
    
    func status(for state: State) -> MiddlewareStatus {
        .active
    }
    
    init(store: some Store<State>) {
        let queueLabel = String(describing: Self.self)
        self.init(store: store, queue: DispatchQueue(label: queueLabel))
    }
}

/// A typealias for backward compatibility.
public typealias Middleware<State: AppReducer> = _BaseMiddleware<State> & EnvironmentMiddleware & MiddlewareProtocol

/// Legacy support for `ObservableMiddleware` and `ReducibleMiddleware` to maintain backward compatibility.
@available(*, deprecated, message: "Use Middleware instead.")
public typealias ObservableMiddleware<State: AppReducer> = Middleware<State>
@available(*, deprecated, message: "Use Middleware instead.")
public typealias ReducibleMiddleware<State: AppReducer> = Middleware<State>

@available(*, deprecated, message: "Use BaseMiddleware instead.")
public typealias BaseObservableMiddleware<State: AppReducer> = Middleware<State>
@available(*, deprecated, message: "Use BaseMiddleware instead.")
public typealias BaseReducibleMiddleware<State: AppReducer> = Middleware<State>
