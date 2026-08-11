//===--- ConcurrencyEffect.swift ---------------------------------===//
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

/// A protocol that defines an asynchronous effect with a unique identifier, capable of producing an action.
///
/// `ConcurrencyEffect` represents an effect that runs asynchronously and returns an action. The effect is identified
/// by an associated `Id` type, allowing for the management and tracking of concurrent tasks in the UDF architecture.
///
/// ## Example of a `ConcurrencyEffect`
///
/// This example demonstrates how to create an asynchronous effect that saves user information using the `SomeMiddleware` environment.
///
/// ```swift
/// private extension SomeMiddleware {
///     struct RevolutInfoSavingEffect<Id: Hashable>: ConcurrencyEffect {
///         var id: Id
///         let token: String
///         let userId: Int
///         let firstName: String
///         let lastName: String
///         let revolutTag: String
///         let environment: SomeMiddleware.Environment
///
///         func task() async throws -> any Action {
///             let bankInfo = try await environment.saveRevolutInfo(token, userId, firstName, lastName, revolutTag)
///
///             return ActionGroup {
///                 Actions.DidLoadItem(item: bankInfo, id: id)
///                 Actions.LoadPage(id: CashOutMethodsFlow.id)
///             }
///         }
///     }
/// }
/// ```
public protocol ConcurrencyEffect: Sendable {
    /// An asynchronous method that performs a task and returns an action.
    ///
    /// - Parameter flowId: The unique identifier for the flow.
    /// - Returns: An action produced by the asynchronous task.
    func task(flowId: AnyHashable) async throws -> any Action
}

/// A protocol that defines an asynchronous effect that receives both a unique flow identifier and the current application state,
/// and produces an action.
///
/// `StateConcurrencyEffect` represents an effect that runs asynchronously and returns an action while having access to the current
/// `AppState`. It is useful when the effect needs both middleware dependencies and a snapshot of the current state in order to
/// produce the next action.
///
/// ## Example of a `StateConcurrencyEffect`
///
/// This example demonstrates how to create an asynchronous effect that loads a user profile using a token stored in the current state.
///
/// ```swift
/// private extension ProfileMiddleware {
///     struct LoadProfileEffect: StateConcurrencyEffect {
///         var environment: ProfileMiddleware.Environment
///
///         func task(flowId: AnyHashable, state: AppState) async throws -> any Action {
///             guard let token = state.userForm.currentUser?.token else {
///                 throw CancellationError()
///             }
///
///             let profile = try await environment.loadProfile(token: token)
///
///             return Actions.DidLoadItem(item: profile, id: flowId)
///         }
///     }
/// }
/// ```
public protocol StateConcurrencyEffect {
    associatedtype Environment: Sendable
    associatedtype AppState: AppReducer
    
    /// The environment used by the effect to access external dependencies.
    var environment: Environment! { get set }

    /// An asynchronous method that performs a task using both the provided flow identifier and the current application state,
    /// and returns an action.
    ///
    /// - Parameters:
    ///   - flowId: The unique identifier for the flow.
    ///   - state: The current application state captured when the effect begins execution.
    /// - Returns: An action produced by the asynchronous task.
    func task(flowId: AnyHashable, state: AppState) async throws -> any Action
}

public extension StateConcurrencyEffect {
    var environment: Void! {
        get { () }
        set { }
    }
}

/// A concrete implementation of `ConcurrencyEffect` that runs an asynchronous block of code to produce an action.
///
/// `ConcurrencyBlockEffect` encapsulates an asynchronous block, allowing you to define custom logic for the effect's task.
/// It conforms to both `ConcurrencyEffect` and `FileFunctionLine`, making it possible to track the source location where the effect was
/// created.
struct ConcurrencyBlockEffect: ConcurrencyEffect, FileFunctionLine {
    /// The asynchronous block to be executed, producing an action.
    let block: @Sendable (AnyHashable) async throws -> any Action

    // Metadata for debugging: file name, function name, and line number.
    var fileName: String
    var functionName: String
    var lineNumber: Int

    /// Executes the asynchronous block with the provided `flowId`.
    ///
    /// - Parameter flowId: The unique identifier for the flow.
    /// - Returns: An action produced by the asynchronous block.
    /// - Throws: An error if the block fails to complete successfully.
    func task(flowId: AnyHashable) async throws -> any Action {
        try await block(flowId)
    }
}
