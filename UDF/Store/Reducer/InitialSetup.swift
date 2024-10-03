//===--- InitialSetup.swift ---------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

/// A protocol that represents an entity capable of performing an initial setup using the application state.
///
/// `InitialSetup` is designed to be adopted by types that need to perform specific setup actions using the application state
/// when they are first initialized. This protocol extends `Reducing`, so conforming types must implement the `reduce(_:)` method
/// to handle actions.
public protocol InitialSetup: Reducing {
    associatedtype AppState: AppReducer
    
    /// Performs an initial setup using the provided application state.
    ///
    /// Implement this method to set up the initial state of the conforming type based on the provided application state.
    ///
    /// - Parameter state: The application state to use for initial setup.
    mutating func initialSetup(with state: AppState)
}

extension AppReducer {
    /// Calls the `initialSetup` method on a reducer that conforms to `InitialSetup` using the current application state.
    ///
    /// This method creates a mutable copy of the provided reducer, performs its initial setup with the current application state,
    /// and then returns the updated reducer.
    ///
    /// - Parameter reducer: The reducer that conforms to `InitialSetup`.
    /// - Returns: A new instance of the reducer, updated with the initial setup.
    func callInitialSetup<I: InitialSetup>(_ reducer: I) -> Reducing where I.AppState == Self {
        var mutableCopy = reducer
        mutableCopy.initialSetup(with: self)
        return mutableCopy
    }
}
