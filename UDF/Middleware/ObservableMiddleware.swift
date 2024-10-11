//===--- ObservableMiddleware.swift -------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

/// A protocol that defines middleware with observation capabilities in the UDF architecture.
///
/// `ObservableMiddleware` extends the standard `Middleware` to include the ability to observe changes in the state
/// and respond to these changes by executing side effects. This protocol is intended for use cases where middleware
/// needs to react to specific changes in the application state.
///
/// ## Requirements
/// - `scope(for:)`: Returns a `Scope` for a given state, which defines the part of the state that the middleware should observe.
/// - `observe(state:)`: A method that performs actions based on the observed changes in the state.
///
public protocol ObservableMiddleware<State>: Middleware {
    /// Defines the scope for the middleware to observe within the given state.
    ///
    /// - Parameter state: The state to define the scope for.
    /// - Returns: A `Scope` that the middleware should observe.
    @ScopeBuilder func scope(for state: State) -> Scope

    /// Observes the state changes and executes the necessary side effects.
    ///
    /// - Parameter state: The current state of the application.
    func observe(state: State)
}

/// A typealias for combining `BaseMiddleware`, `ObservableMiddleware`, and `EnvironmentMiddleware`.
///
/// This typealias simplifies the creation of middleware that includes environment and observable capabilities.
/// ## Example Usage
/// This example demonstrates how to create an `BaseObservableMiddleware` by implementing a `FaqMiddleware`:
///
/// ```swift
/// final class FaqMiddleware: BaseObservableMiddleware<AppState> {
///
///     enum Cancellation: Hashable, CaseIterable {
///         case loadFaqItems
///     }
///
///     struct Environment {
///         var loadFaqItems: (_ faqCategoryId: Int, _ page: Int, _ perPage: Int) async throws -> [FaqItem]
///     }
///
///     var environment: Environment!
///
///     func scope(for state: AppState) -> Scope {
///         state.faqFlow
///     }
///
///     func observe(state: AppState) {
///         switch state.faqFlow {
///         case .loadingFaqItems(let page):
///             execute(
///                 id: FaqFlow.id,
///                 cancellation: Cancellation.loadFaqItems
///             ) { [unowned self] id in
///                 guard let faqCategoryID = state.faqForm.faqCategoryID else {
///                     throw CancellationError()
///                 }
///                 let items = try await self.environment.loadFaqItems(
///                     faqCategoryID.value, page, kPerPage
///                 )
///                 return Actions.DidLoadItems(items: items, id: id)
///             }
///         default:
///             break
///         }
///     }
/// }
///
/// // MARK: - Environment build methods
/// extension FaqMiddleware {
///     static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
///         .init(
///             loadFaqItems: { faqCategoryId, page, perPage in
///                 try await FaqAPIClient.loadFaqs(
///                     faqCategoryId: faqCategoryId, page: page, perPage: perPage
///                 )
///                 .map { $0.asFaqItem }
///             }
///         )
///     }
///
///     static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
///         .init(
///             loadFaqItems: { _, _, _ in
///                 FaqItem.testItems(count: 10)
///             }
///         )
///     }
/// }
/// ```
///
/// In this example:
/// - **`scope(for:)`** defines the scope of state that this middleware observes (`faqFlow` in `AppState`).
/// - **`observe(state:)`** reacts to state changes, performing an asynchronous operation to load FAQ items when the state is
/// `.loadingFaqItems`.
/// - **Environment:** Contains dependencies, such as a function for loading FAQ items from an API, with separate methods to build live and
/// test environments.
///
public typealias BaseObservableMiddleware<State: AppReducer> = BaseMiddleware<State> & EnvironmentMiddleware & ObservableMiddleware
