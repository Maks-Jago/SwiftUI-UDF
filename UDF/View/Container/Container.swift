//===--- Container.swift ----------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

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
///                 When the scope is mutated, the container will redraw the Component, and the map(store:) function will be called again.
/// - Lifecycle Methods: Methods to handle view lifecycle events like appearing, disappearing, loading, and unloading.
/// - `useHooks()`: Specifies hooks to be used within the container to handle state changes or other effects.
///
/// ## Example Usage:
/// ```swift
/// struct MyContainer: Container {
///     typealias ContainerComponent = MyComponent
///
///     // Define the scope for this container's state
///     func scope(for state: AppState) -> Scope {
///         state.hookForm
///     }
///
///     // Map the state to component props
///     func map(store: EnvironmentStore<MyAppState>) -> MyComponent.Props {///
///         .init()
///     }
///
///     func onContainerAppear(store: EnvironmentStore<MyAppState>) {
///         // What needs to be done when view appears
///     }
///
///     func onContainerDisappear(store: EnvironmentStore<MyAppState>) {
///         // What needs to be done when view disappears
///     }
///
///     func onContainerDidLoad(store: EnvironmentStore<AppState>) {
///         // What needs to be done when view didLoad
///     }
///
///     func onContainerDidUnload(store: EnvironmentStore<AppState>) {
///         // What needs to be done when view didUnload
///     }
///
///     func useHooks() -> [Hook<ContainerHookTests.AppState>] {
///         Hook.oneTimeHook(id: "OneTimeHook") { state in
///             state.hookForm.triggerValue == "1"
///         } block: { store in
///             store.$state.hookForm.triggerValue.wrappedValue = "2"
///         }
///
///         Hook.hook(id: "DefaultHook") { state in
///             state.hookForm.triggerValue == "3"
///         } block: { store in
///             store.$state.hookForm.callbacksCount.wrappedValue += 1
///         }
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
    /// Equals to native SwiftUI View's onAppear lifecycle method.
    ///
    /// - Parameter store: The global store containing the state.
    func onContainerAppear(store: EnvironmentStore<ContainerState>)

    /// Called when the container's view disappears.
    /// Equals to native SwiftUI View's onDisappear lifecycle method.
    ///
    /// - Parameter store: The global store containing the state.
    func onContainerDisappear(store: EnvironmentStore<ContainerState>)

    /// Called when the container is initialized and loaded for the first time.
    ///
    /// - Parameter store: The global store containing the state.
    func onContainerDidLoad(store: EnvironmentStore<ContainerState>)

    /// Called when the container is deinitialized and unloaded.
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
