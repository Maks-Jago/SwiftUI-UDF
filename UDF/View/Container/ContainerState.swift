//===--- ContainerState.swift ----------------------------------------------===//
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
import SwiftUI

/// A state container for managing scoped state in a `Container` within the UDF architecture.
///
/// The `ContainerState` class is responsible for observing changes in the global state provided
/// by the `EnvironmentStore` and managing the scoped state relevant to a specific container.
/// It subscribes to state changes and updates its `currentScope` when the scoped state changes,
/// allowing the container to reactively update its view.
///
/// - Note: This class is designed to be used as an `ObservableObject` in SwiftUI, so views can
/// automatically update when the `currentScope` changes.
///
/// ## Generic Parameters:
/// - `State`: A type conforming to `AppReducer` representing the global state managed by the `EnvironmentStore`.
///
/// ## Properties:
/// - `store`: A weak reference to the `EnvironmentStore` that holds the global app state.
/// - `subscriptionKey`: A private string key for identifying the subscription in the store.
/// - `currentScope`: The currently scoped state, published to notify observers of changes.
///
/// ## Initialization:
/// - `init(store:scope:)`: Initializes the container state with an `EnvironmentStore` and a
///   closure defining the scope for the state. Sets up a subscription to monitor changes in the scoped state.
///
/// ## Methods:
/// - `deinit`: Removes the state subscription from the store when the `ContainerState` instance is deallocated.
final class ContainerState<State: AppReducer>: ObservableObject {
    /// A weak reference to the environment store containing the global state.
    weak var store: EnvironmentStore<State>?
    
    /// A private key used to manage the subscription in the store.
    private var subscriptionKey: String = ""
    
    /// The current scoped state that is observed by SwiftUI views.
    @Published var currentScope: Scope?
    
    /// Initializes the `ContainerState` with a given store and scope closure.
    ///
    /// - Parameters:
    ///   - store: The `EnvironmentStore` holding the global state.
    ///   - scope: A closure that extracts a `Scope` from the global state.
    init(store: EnvironmentStore<State>, scope: @escaping (_ state: State) -> Scope) {
        self.store = store
        self.currentScope = nil
        
        // Subscribe to state changes in the store
        self.subscriptionKey = store.add { [weak self] oldState, newState, animation in
            let oldScope = scope(oldState)
            let newScope = scope(newState)
            
            // Update the scope if it has changed
            if !oldScope.isEqual(newScope) {
                withAnimation(animation) {
                    self?.currentScope = newScope
                }
            }
        }
    }
    
    /// Cleans up the subscription when the `ContainerState` is deinitialized.
    deinit {
        store?.removePublisher(forKey: subscriptionKey)
    }
}
