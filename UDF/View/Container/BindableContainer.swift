//===--- BindableContainer.swift -------------------------------------------===//
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

/// A protocol that represents a container in the UDF architecture, which is identifiable and can be connected
/// to the app's state via a `ConnectedContainer`.
///
/// The `BindableContainer` protocol combines the functionalities of `Container` and `Identifiable`,
/// allowing containers to have unique identifiers and manage their state in a type-safe manner.
/// This protocol also provides a default implementation of the `body` property to automatically
/// connect the container with the `ConnectedContainer`.
///
/// ## Requirements:
/// - Must conform to `Container` and `Identifiable`.
///
/// ## Usage:
/// Conforming to `BindableContainer` enables a container to be connected to its state with an identifier,
/// which is useful when managing state across multiple instances of the container.
///
/// ## Example Usage:
/// ```swift
/// struct MyContainer: BindableContainer {
///     // Unique identifier for this container
///     var id: Item.ID
///
///     typealias ContainerComponent = MyComponent
///
///     func map(store: EnvironmentStore<MyAppState>) -> MyComponent.Props {
///         .init()
///     }
///
///     func scope(for state: MyAppState) -> Scope {
///         state.itemsForm[id]
///         state.itemsFlow[id]
///     }
///
///     func onContainerAppear(store: EnvironmentStore<MyAppState>) {
///         // Handle view appearance
///     }
/// }
/// ```
public protocol BindableContainer: Container, Identifiable where ID: Sendable {
    /// A lifecycle callback executed when the dynamic reducer state associated with this container's `id` is loaded and online.
    ///
    /// This callback is triggered when the dynamic reducer (e.g. form or flow) is successfully allocated and visible in the `EnvironmentStore`.
    /// Use this callback to perform state-dependent actions (like loading details or checking validation states) that require the reducer to be active.
    ///
    /// - Parameter store: The `EnvironmentStore` instance managing the state.
    @MainActor
    func onBindableReducerDidLoad(store: EnvironmentStore<ContainerState>)
    
    /// A lifecycle callback executed when the dynamic reducer state associated with this container's `id` is unloaded and offline.
    ///
    /// This callback is triggered when the dynamic reducer is deallocated from the store (e.g. when the last container with this ID is unloaded).
    /// Use this callback to perform cleanup operations or clear state variables that are no longer needed.
    ///
    /// - Parameter store: The `EnvironmentStore` instance managing the state.
    @MainActor
    func onBindableReducerDidUnload(store: EnvironmentStore<ContainerState>)
}

public extension BindableContainer {
    @MainActor
    func onBindableReducerDidLoad(store: EnvironmentStore<ContainerState>) {}
    
    @MainActor
    func onBindableReducerDidUnload(store: EnvironmentStore<ContainerState>) {}
}

public extension BindableContainer {
    /// The main view body that connects the container to the state using `ConnectedContainer`.
    ///
    /// This default implementation creates a `ConnectedContainer` for the `BindableContainer`,
    /// passing in the container's type, identifier, state mapping, scope, lifecycle events, and hooks.
    var body: some View {
        ConnectedContainer<ContainerComponent, ContainerState>(
            store: store,
            containerType: Self.self,
            containerId: { self.id },
            map: map,
            scope: scope(for:),
            onContainerAppear: onContainerAppear,
            onContainerDisappear: onContainerDisappear,
            onContainerDidLoad: onContainerDidLoad,
            onContainerDidUnload: onContainerDidUnload,
            onBindableReducerDidLoad: onBindableReducerDidLoad,
            onBindableReducerDidUnload: onBindableReducerDidUnload,
            useHooks: useHooks
        )
    }
}

// MARK: - Environment-Aware Container
extension BindableContainer {
    /// Creates a version of this container that uses a specific store instead of global
    func with(store: EnvironmentStore<ContainerState>) -> some View {
        ConnectedContainer<ContainerComponent, ContainerState>(
            store: store,
            containerType: Self.self,
            containerId: { self.id },
            map: map,
            scope: scope(for:),
            onContainerAppear: onContainerAppear,
            onContainerDisappear: onContainerDisappear,
            onContainerDidLoad: onContainerDidLoad,
            onContainerDidUnload: onContainerDidUnload,
            onBindableReducerDidLoad: onBindableReducerDidLoad,
            onBindableReducerDidUnload: onBindableReducerDidUnload,
            useHooks: useHooks
        )
    }
}
