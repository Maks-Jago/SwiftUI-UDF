//===--- ContainerHooks.swift ----------------------------------------------===//
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
import SwiftUI

/// Manages a collection of hooks for a container in the UDF architecture, allowing
/// the container to react to changes in the application state.
///
/// The `ContainerHooks` class observes changes in the state and triggers the
/// corresponding hooks based on predefined conditions. Hooks can be one-time or recurring,
/// enabling flexible reactions to state updates. Hooks are managed in a dictionary and
/// can be created, removed, or checked for state changes.
///
/// - Note: Hooks are provided as closures that define the conditions under which they
/// should execute and the actions to perform when triggered.
///
/// ## Generic Parameters:
/// - `State`: A type conforming to `AppReducer` representing the global state managed by the `EnvironmentStore`.
///
/// ## Properties:
/// - `store`: A weak reference to the `EnvironmentStore` containing the global app state.
/// - `subscriptionKey`: A private string key for managing the subscription in the store.
/// - `hooks`: A dictionary storing hooks by their unique identifiers.
/// - `buildHooks`: A closure that returns an array of hooks to be used in the container.
///
/// ## Initialization:
/// - `init(store:hooks:)`: Initializes the `ContainerHooks` with the given store and a closure that provides the hooks.
///
/// ## Methods:
/// - `createHooks()`: Builds and stores hooks based on the provided closure.
/// - `checkHooks(oldState:newState:)`: Checks the conditions of each hook against the old and new state, triggering and removing hooks as needed.
/// - `removeHook(by:)`: Removes a hook with a specific identifier.
/// - `removeAllHooks()`: Removes all hooks and cancels the state subscription.
/// - `deinit`: Cleans up by removing the state subscription when the `ContainerHooks` instance is deallocated.
final class ContainerHooks<State: AppReducer> {
    /// A weak reference to the environment store containing the global state.
    weak var store: EnvironmentStore<State>?
    
    /// A private key used to manage the subscription in the store.
    private var subscriptionKey: String = ""
    
    /// A dictionary of hooks, keyed by unique identifiers.
    var hooks: [AnyHashable: Hook<State>] = [:]
    
    /// A closure that returns an array of hooks to be used in the container.
    var buildHooks: () -> [Hook<State>]
    
    /// Initializes the `ContainerHooks` with a store and a closure that builds the hooks.
    ///
    /// - Parameters:
    ///   - store: The `EnvironmentStore` holding the global state.
    ///   - hooks: A closure that provides an array of hooks to use in the container.
    init(store: EnvironmentStore<State>, hooks: @escaping () -> [Hook<State>]) {
        self.store = store
        self.buildHooks = hooks
        self.subscriptionKey = store.add { [weak self] oldState, newState, _ in
            self?.checkHooks(oldState: .init(oldState), newState: .init(newState))
        }
    }
    
    /// Creates hooks by building them from the provided closure and storing them in a dictionary.
    func createHooks() {
        self.hooks = Dictionary(uniqueKeysWithValues: buildHooks().map { ($0.id, $0) })
    }
    
    /// Checks each hook's condition against the old and new state, triggering the hook if necessary.
    ///
    /// - Parameters:
    ///   - oldState: The previous state wrapped in a `Box`.
    ///   - newState: The current state wrapped in a `Box`.
    private func checkHooks(oldState: Box<State>, newState: Box<State>) {
        hooks.forEach { (key: AnyHashable, hook: Hook<State>) in
            if hook.condition(newState.value), !hook.condition(oldState.value), let store {
                hook.block(store)
                
                switch hook.type {
                case .oneTime:
                    removeHook(by: key)
                case .default:
                    break
                }
            }
        }
    }
    
    /// Removes a hook with the specified identifier.
    ///
    /// - Parameter id: The identifier of the hook to remove.
    func removeHook(by id: some Hashable) {
        hooks.removeValue(forKey: AnyHashable(id))
        
        if hooks.isEmpty {
            store?.removePublisher(forKey: subscriptionKey)
        }
    }
    
    /// Removes all hooks and cancels the state subscription.
    func removeAllHooks() {
        hooks.removeAll()
        store?.removePublisher(forKey: subscriptionKey)
    }
    
    /// Cleans up by removing the state subscription when the `ContainerHooks` instance is deallocated.
    deinit {
        store?.removePublisher(forKey: subscriptionKey)
    }
}
