//
//  Container.swift
//  UDF
//
//  Created by Maksym Kuznetsov on 04.06.2020.
//  Copyright © 2024 Max Kuznetsov. All rights reserved.
//

import SwiftUI

/// A protocol that defines a container view in the UDF architecture, responsible for managing
/// state and connecting it to a SwiftUI `Component`. Containers serve as "smart views," handling
/// the data flow and actions for their associated components.
///
/// The `Container` protocol provides lifecycle methods, state mapping, hooks, and a way to scope
/// the state within the app's store.
///
/// ## Associated Types:
/// - `ContainerState`: A type conforming to `AppReducer` that represents the state managed by this container.
/// - `ContainerComponent`: A `Component` that this container connects to and manages.
///
/// ## Requirements:
/// - `map(store:)`: Maps the global state in the `EnvironmentStore` to the properties required by the `Component`.
/// - `scope(for:)`: Defines a `Scope` for a specific slice of the `ContainerState`.
/// - Lifecycle Methods: Methods to handle view lifecycle events like appearing, disappearing, loading, and unloading.
/// - `useHooks()`: Specifies hooks to be used within the container to handle state changes or other effects.
///
/// ## Example Usage:
/// ```swift
/// struct MyContainer: Container {
///     typealias ContainerComponent = MyComponent
///
///     func map(store: EnvironmentStore<MyAppState>) -> MyComponent.Props {
///         // Map the state to component props
///     }
///
///     func scope(for state: MyAppState) -> Scope {
///         // Define the scope for this container's state
///     }
///
///     func onContainerAppear(store: EnvironmentStore<MyAppState>) {
///         // Handle view appearance
///     }
/// }
/// ```
public protocol Container<ContainerState>: View {
    associatedtype ContainerState: AppReducer
    associatedtype ContainerComponent: Component
    
    /// Maps the `EnvironmentStore` to the properties required by the `ContainerComponent`.
    ///
    /// - Parameter store: The global store containing the state.
    /// - Returns: The properties (`Props`) needed by the `ContainerComponent`.
    func map(store: EnvironmentStore<ContainerState>) -> ContainerComponent.Props
    
    /// Defines a scope for the `ContainerState`.
    ///
    /// - Parameter state: The state managed by the container.
    /// - Returns: A `Scope` object defining the relevant slice of the state.
    @ScopeBuilder
    func scope(for state: ContainerState) -> Scope
    
    /// Called when the container's view appears.
    ///
    /// - Parameter store: The global store containing the state.
    func onContainerAppear(store: EnvironmentStore<ContainerState>)
    
    /// Called when the container's view disappears.
    ///
    /// - Parameter store: The global store containing the state.
    func onContainerDisappear(store: EnvironmentStore<ContainerState>)
    
    /// Called when the container is loaded for the first time.
    ///
    /// - Parameter store: The global store containing the state.
    func onContainerDidLoad(store: EnvironmentStore<ContainerState>)
    
    /// Called when the container is unloaded.
    ///
    /// - Parameter store: The global store containing the state.
    func onContainerDidUnload(store: EnvironmentStore<ContainerState>)
    
    /// Defines hooks to be used within the container.
    ///
    /// - Returns: An array of hooks that respond to state changes or other effects.
    @HookBuilder<ContainerState>
    func useHooks() -> [Hook<ContainerState>]
}

// MARK: - Lifecycle methods
public extension Container {
    /// Default implementation for `onContainerAppear`. Does nothing by default.
    @MainActor
    func onContainerAppear(store: EnvironmentStore<ContainerState>) {}
    
    /// Default implementation for `onContainerDisappear`. Does nothing by default.
    @MainActor
    func onContainerDisappear(store: EnvironmentStore<ContainerState>) {}
    
    /// Default implementation for `onContainerDidLoad`. Does nothing by default.
    @MainActor
    func onContainerDidLoad(store: EnvironmentStore<ContainerState>) {}
    
    /// Default implementation for `onContainerDidUnload`. Does nothing by default.
    @MainActor
    func onContainerDidUnload(store: EnvironmentStore<ContainerState>) {}
    
    /// Default implementation for `useHooks`. Returns an empty array by default.
    func useHooks() -> [Hook<ContainerState>] { [] }
}

// MARK: - Store
public extension Container {
    /// Provides access to the global `EnvironmentStore` for the container's state.
    var store: EnvironmentStore<ContainerState> { .global }
    
    /// The body of the container view. Connects the `ContainerComponent` with the `ContainerState` using a `ConnectedContainer`.
    @MainActor
    var body: some View {
        ConnectedContainer<ContainerComponent, ContainerState>(
            map: map,
            scope: scope(for:),
            onContainerAppear: onContainerAppear,
            onContainerDisappear: onContainerDisappear,
            onContainerDidLoad: onContainerDidLoad,
            onContainerDidUnload: onContainerDidUnload,
            useHooks: useHooks
        )
    }
}
