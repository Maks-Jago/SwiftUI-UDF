//===--- ConnectedContainer.swift ------------------------------------------===//
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

/// A SwiftUI view that connects a `Component` with its associated state in the UDF architecture.
///
/// The `ConnectedContainer` is responsible for managing the lifecycle and state of a given component.
/// It observes changes in the global state (`EnvironmentStore`), applies hooks, and manages view
/// appearance and disappearance. This view serves as the bridge between the app's state and the UI,
/// ensuring that the state updates are reflected in the view.
///
/// ## Generic Parameters:
/// - `C`: A type conforming to `Component` that defines the UI.
/// - `State`: A type conforming to `AppReducer` representing the global state.
///
/// ## Properties:
/// - `map`: A closure that maps the global store to the properties needed by the component.
/// - `scope`: A closure that extracts a specific scope from the global state.
/// - `onContainerAppear`: A closure executed when the container appears in the view hierarchy.
/// - `onContainerDisappear`: A closure executed when the container disappears from the view hierarchy.
/// - `containerLifecycle`: A `ContainerLifecycle` instance that manages the container's lifecycle events.
/// - `containerState`: A `ContainerState` instance that observes changes in the scoped state.
///
/// ## Initialization:
/// - `init(map:scope:onContainerAppear:onContainerDisappear:onContainerDidLoad:onContainerDidUnload:useHooks:)`:
///   Initializes the `ConnectedContainer` with closures to manage state mapping, scope, lifecycle events, and hooks.
/// - `init<BindedContainer: BindableContainer>(...)`: Initializes a `ConnectedContainer` for a bindable container type, managing state and
/// lifecycle events.
///
/// ## Methods:
/// - `body`: The main view builder, responsible for creating the component and attaching lifecycle events.
///
/// ## Usage:
/// The `ConnectedContainer` can be used to encapsulate a component and automatically react to state changes,
/// manage its lifecycle events, and bind hooks for actions and side effects.
struct ConnectedContainer<C: Component, State: AppReducer>: View {
    /// A closure that maps the global store to the properties needed by the component.
    let map: (_ store: EnvironmentStore<State>) -> C.Props

    /// A closure that defines the scope within the global state.
    let scope: (_ state: State) -> Scope

    /// A closure executed when the container appears in the view hierarchy.
    var onContainerAppear: (EnvironmentStore<State>) -> Void

    /// A closure executed when the container disappears from the view hierarchy.
    var onContainerDisappear: (EnvironmentStore<State>) -> Void

    /// The container's lifecycle manager that handles loading, unloading, and hooks.
    @StateObject var containerLifecycle: ContainerLifecycle<State>

    /// The container state that observes changes in the scoped state.
    @ObservedObject var containerState: ContainerState<State>

    /// Provides access to the global `EnvironmentStore`.
    private var store: EnvironmentStore<State> { .global }

    /// Initializes the `ConnectedContainer` with closures for mapping state, managing scope,
    /// handling lifecycle events, and creating hooks.
    ///
    /// - Parameters:
    ///   - map: A closure to map the `EnvironmentStore` to the component's properties.
    ///   - scope: A closure to extract a specific scope from the global state.
    ///   - onContainerAppear: A closure executed when the container appears.
    ///   - onContainerDisappear: A closure executed when the container disappears.
    ///   - onContainerDidLoad: A closure executed when the container is loaded.
    ///   - onContainerDidUnload: A closure executed when the container is unloaded.
    ///   - useHooks: A closure that provides an array of hooks to use within the container.
    init(
        map: @escaping (EnvironmentStore<State>) -> C.Props,
        scope: @escaping (State) -> Scope,
        onContainerAppear: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDisappear: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDidLoad: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDidUnload: @escaping (EnvironmentStore<State>) -> Void,
        useHooks: @escaping () -> [Hook<State>]
    ) {
        self.map = map
        self.scope = scope
        self.onContainerAppear = onContainerAppear
        self.onContainerDisappear = onContainerDisappear
        self._containerLifecycle = .init(
            wrappedValue: ContainerLifecycle(
                didLoadCommand: { store, _ in onContainerDidLoad(store) },
                didUnloadCommand: { store, _ in onContainerDidUnload(store) },
                useHooks: useHooks
            )
        )
        self._containerState = .init(wrappedValue: .init(store: EnvironmentStore<State>.global, scope: scope))
    }

    /// Initializes a `ConnectedContainer` for a bindable container type, managing state and lifecycle events.
    ///
    /// - Parameters:
    ///   - containerType: The type of the bindable container.
    ///   - containerId: A closure that returns the container's unique identifier.
    ///   - map: A closure to map the `EnvironmentStore` to the component's properties.
    ///   - scope: A closure to extract a specific scope from the global state.
    ///   - onContainerAppear: A closure executed when the container appears.
    ///   - onContainerDisappear: A closure executed when the container disappears.
    ///   - onContainerDidLoad: A closure executed when the container is loaded.
    ///   - onContainerDidUnload: A closure executed when the container is unloaded.
    ///   - useHooks: A closure that provides an array of hooks to use within the container.
    init<BindedContainer: BindableContainer>(
        containerType: BindedContainer.Type,
        containerId: @escaping () -> BindedContainer.ID,
        map: @escaping (EnvironmentStore<State>) -> C.Props,
        scope: @escaping (State) -> Scope,
        onContainerAppear: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDisappear: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDidLoad: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDidUnload: @escaping (EnvironmentStore<State>) -> Void,
        useHooks: @escaping () -> [Hook<State>]
    ) {
        self.map = map
        self.scope = scope
        self.onContainerAppear = onContainerAppear
        self.onContainerDisappear = onContainerDisappear
        self._containerLifecycle = .init(
            wrappedValue: ContainerLifecycle(
                didLoadCommand: { store, uuid in
                    store.dispatch(
                        Actions._OnContainerDidLoad(
                            containerType: containerType,
                            id: .init(itemID: containerId(), containerUUID: uuid)
                        ).silent(),
                        priority: .userInteractive
                    )
                    onContainerDidLoad(store)
                },
                didUnloadCommand: { store, uuid in
                    onContainerDidUnload(store)
                    store.dispatch(
                        Actions._OnContainerDidUnLoad(
                            containerType: containerType,
                            id: .init(itemID: containerId(), containerUUID: uuid)
                        ).silent()
                    )
                },
                useHooks: useHooks
            )
        )
        self._containerState = .init(wrappedValue: .init(store: EnvironmentStore<State>.global, scope: scope))
    }

    /// The main view body that renders the component and attaches lifecycle events.
    var body: some View {
        containerLifecycle.set(didLoad: true, store: store)

        return C(props: map(store))
            .onAppear { onContainerAppear(store) }
            .onDisappear { onContainerDisappear(store) }
    }
}
