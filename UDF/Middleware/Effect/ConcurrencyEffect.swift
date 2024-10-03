//===--- ConcurrencyEffect.swift ---------------------------------===//
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
public protocol ConcurrencyEffect {
    /// The type of the unique identifier for the effect.
    associatedtype Id: Hashable
    
    /// The unique identifier for this effect.
    var id: Id { get }
    
    /// An asynchronous method that performs a task and returns an action.
    ///
    /// - Returns: An action produced by the asynchronous task.
    func task() async throws -> any Action
}

/// A concrete implementation of `ConcurrencyEffect` that runs an asynchronous block of code to produce an action.
///
/// `ConcurrencyBlockEffect` encapsulates an asynchronous block, allowing you to define custom logic for the effect's task.
/// It conforms to both `ConcurrencyEffect` and `FileFunctionLine`, making it possible to track the source location where the effect was created.
struct ConcurrencyBlockEffect<EffectId: Hashable>: ConcurrencyEffect, FileFunctionLine {
    typealias Id = EffectId
    
    /// The unique identifier for this effect.
    var id: EffectId
    
    /// The asynchronous block to be executed, producing an action.
    let block: (EffectId) async throws -> any Action
    
    // Metadata for debugging: file name, function name, and line number.
    var fileName: String
    var functionName: String
    var lineNumber: Int
    
    /// Executes the asynchronous block with the effect's `id`.
    ///
    /// - Returns: An action produced by the asynchronous block.
    /// - Throws: An error if the block fails to complete successfully.
    func task() async throws -> any Action {
        try await block(id)
    }
}
