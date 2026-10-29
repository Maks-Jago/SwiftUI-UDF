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


/// A protocol that defines a Combine-based effect that receives both a unique flow identifier and the current application state,
/// and produces a publisher of actions.
///
/// `StateEffectable` is the Combine equivalent of `StateConcurrencyEffect`. It is useful when the effect needs both middleware
/// dependencies and a snapshot of the current state in order to build a publisher that emits actions.
public protocol StateEffectable: EnvironmentEffect {
    associatedtype AppState: AppReducer

    /// Creates a publisher using both the provided flow identifier and the current application state.
    ///
    /// - Parameters:
    ///   - flowId: The unique identifier for the flow.
    ///   - state: The current application state captured when the effect begins execution.
    /// - Returns: A publisher that emits actions produced by the effect.
    func publisher(flowId: AnyHashable, state: AppState) throws -> AnyPublisher<any Action, Never>
}
