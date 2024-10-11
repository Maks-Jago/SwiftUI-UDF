//===--- Flow.swift ----------------------------------------------===//
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

/// A protocol representing a flow of state changes in the application, conforming to `Reducible`.
///
/// `Flow` provides a structure for managing state transitions in a unidirectional data flow (UDF) architecture.
/// Types conforming to this protocol are expected to be `Reducible`, meaning they can respond to actions to update their state.
/// Additionally, conforming types must implement a default initializer (`init()`), allowing instances of the flow to be easily created.
///
/// Example of a Flow implementation using UDF:
/// ```swift
///
/// enum FaqFlow: IdentifiableFlow {
///     case none, loadingFaqItems(Int)
///
///     // Default initializer for the flow
///     init() { self = .none }
///
///     // Method to handle actions and update the flow's state
///     mutating func reduce(_ action: some Action) {
///         switch action {
///
///         // Handle an error action and reset the flow to 'none'
///         case let action as Actions.Error where action.id == Self.id:
///             self = .none
///
///         // Handle loading page action and update the state to 'loadingFaqItems'
///         case let action as Actions.LoadPage where action.id == Self.id:
///             self = .loadingFaqItems(action.pageNumber)
///
///         // Handle successfully loaded items and reset the flow to 'none'
///         case let action as Actions.DidLoadItems<FaqItem> where action.id == Self.id:
///             self = .none
///
///         // Handle cancellation actions and reset the flow to 'none'
///         case let action as Actions.DidCancelEffect
///             where FaqMiddleware.Cancellation.allCases.contains(action.cancellation):
///             self = .none
///
///         // Ignore other actions
///         default:
///             break
///         }
///     }
/// }
/// ```
///
/// In this example:
/// - `FaqFlow` is an `IdentifiableFlow` that defines different states (`none`, `loadingFaqItems`) to represent the flow of fetching FAQ
/// items.
/// - The `reduce(_:)` method handles various actions:
///   - `Actions.Error`: Resets the flow to `none`.
///   - `Actions.LoadPage`: Updates the state to `loadingFaqItems` with the specified page number.
///   - `Actions.DidLoadItems`: Resets the flow to `none` after items are loaded.
///   - `Actions.DidCancelEffect`: Resets the flow to `none` when a cancellation effect is detected.
public protocol Flow: Reducible {
    /// Initializes a new instance of the flow.
    ///
    /// Conforming types must provide a default initializer to allow the creation of instances without any parameters.
    init()
}
