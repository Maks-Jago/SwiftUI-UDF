//===--- BindableReducerReference.swift --------------------------===//
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

/// A class that provides a reference to a `BindableReducer`, allowing access to reducers associated with specific container IDs.
///
/// `BindableReducerReference` extends `ReducerReference` to work with `BindableReducer` instances, enabling dynamic access
/// and modification of state associated with a `BindableContainer`. This allows for the flexible management of nested state
/// in applications that use UDF architecture.
///
/// - Note: This class is useful for managing state associated with containers that can have multiple instances, each with its own reducer.
public final class BindableReducerReference<AppState: AppReducer, BindedContainer: BindableContainer, Reducer: Reducible>: ReducerReference<AppState, BindableReducer<BindedContainer, Reducer>> {
    
    /// Initializes a new `BindableReducerReference` with the specified `BindableReducer` and action dispatcher.
    ///
    /// - Parameters:
    ///   - reducer: The `BindableReducer` to reference.
    ///   - dispatcher: A closure for dispatching actions.
    override init(reducer: BindableReducer<BindedContainer, Reducer>, dispatcher: @escaping (any Action) -> Void) {
        super.init(reducer: reducer, dispatcher: dispatcher)
    }
    
    /// Provides access to a specific reducer associated with a container ID.
    ///
    /// - Parameter id: The ID of the container whose reducer is to be accessed.
    /// - Returns: A `ReducerReference` for the reducer associated with the specified container ID.
    public subscript(_ id: BindedContainer.ID) -> ReducerReference<AppState, Reducer> {
        ReducerReference(reducer: reducer[id] ?? .init()) { [dispatcher] action in
            dispatcher(action.binded(to: BindedContainer.self, by: id))
        }
    }
}
