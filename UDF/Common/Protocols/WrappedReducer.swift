//===--- WrappedReducer.swift ---------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

/// A protocol representing a reducer that wraps another `Reducing` instance.
/// It provides a way to contain and manage the state of a wrapped reducer,
/// allowing for the reduction of actions on the wrapped reducer.
public protocol WrappedReducer: Reducing {
    
    /// The reducer instance that this wrapper manages.
    var reducer: Reducing { get set }
}

extension WrappedReducer {
    
    /// Reduces an action by invoking the `RuntimeReducing` mechanism on the wrapped reducer.
    /// This method attempts to mutate the state of the wrapped reducer based on the given action.
    /// - Parameter action: The action to be reduced.
    mutating public func reduce(_ action: some Action) {
        _ = RuntimeReducing.reduce(action, reducer: &reducer)
    }
}
