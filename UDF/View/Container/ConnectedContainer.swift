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
import Runtime

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
    let scope: @MainActor (_ state: State) -> Scope
    
    /// A closure executed when the container appears in the view hierarchy.
    var onContainerAppear: @MainActor (EnvironmentStore<State>) -> Void
    
    /// A closure executed when the container disappears from the view hierarchy.
    var onContainerDisappear: @MainActor (EnvironmentStore<State>) -> Void
    
    /// The container's lifecycle manager that handles loading, unloading, and hooks.
    @SwiftUI.State var containerLifecycle: ContainerLifecycle<State>
    
    /// The container state that observes changes in the scoped state.
    @ObservedObject var containerState: ContainerState<State>

    /// Provides access to the `EnvironmentStore`, which can be either global or explicitly provided.
    private var store: EnvironmentStore<State>

    /// Initializes the `ConnectedContainer` with an  store and closures for mapping state, managing scope,
    /// handling lifecycle events, and creating hooks.
    ///
    /// - Parameters:
    ///   - store: The `EnvironmentStore` instance to use for this container. Defaults to `.global` if not provided.
    ///   - map: A closure to map the `EnvironmentStore` to the component's properties.
    ///   - scope: A closure to extract a specific scope from the global state.
    ///   - onContainerAppear: A closure executed when the container appears.
    ///   - onContainerDisappear: A closure executed when the container disappears.
    ///   - onContainerDidLoad: A closure executed when the container is loaded.
    ///   - onContainerDidUnload: A closure executed when the container is unloaded.
    ///   - useHooks: A closure that provides an array of hooks to use within the container.
    init(
        store: EnvironmentStore<State>,
        map: @escaping (EnvironmentStore<State>) -> C.Props,
        scope: @escaping @Sendable (State) -> Scope,
        onContainerAppear: @escaping @MainActor (EnvironmentStore<State>) -> Void,
        onContainerDisappear: @escaping @MainActor (EnvironmentStore<State>) -> Void,
        onContainerDidLoad: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDidUnload: @escaping (EnvironmentStore<State>) -> Void,
        useHooks: @escaping () -> [Hook<State>]
    ) {
        self.store = store
        self.map = map
        self.scope = scope
        self.onContainerAppear = onContainerAppear
        self.onContainerDisappear = onContainerDisappear
        self._containerLifecycle = .init(
            wrappedValue: ContainerLifecycle(
                didLoadCommand: onContainerDidLoad,
                didUnloadCommand: onContainerDidUnload,
                useHooks: useHooks
            )
        )
        self._containerState = .init(wrappedValue: .init(store: store, scope: scope))
    }
    /// Initializes a `ConnectedContainer` for a bindable container type, managing state and lifecycle events.
    ///
    /// - Parameters:
    ///   - store: The `EnvironmentStore` instance to use for this container. Defaults to `.global` if not provided.
    ///   - containerType: The type of the bindable container.
    ///   - containerId: A closure that returns the container's unique identifier.
    ///   - map: A closure to map the `EnvironmentStore` to the component's properties.
    ///   - scope: A closure to extract a specific scope from the global state.
    ///   - onContainerAppear: A closure executed when the container appears.
    ///   - onContainerDisappear: A closure executed when the container disappears.
    ///   - onContainerDidLoad: A closure executed when the container is loaded.
    ///   - onContainerDidUnload: A closure executed when the container is unloaded.
    ///   - onBindableReducerDidLoad: A closure executed when the bindable container's state is loaded and verified online.
    ///   - onBindableReducerDidUnload: A closure executed when the bindable container's state is unloaded and verified offline.
    ///   - useHooks: A closure that provides an array of hooks to use within the container.
    init<BindedContainer: BindableContainer>(
        store: EnvironmentStore<State>,
        containerType: BindedContainer.Type,
        containerId: @escaping () -> BindedContainer.ID,
        map: @escaping (EnvironmentStore<State>) -> C.Props,
        scope: @escaping @Sendable (State) -> Scope,
        onContainerAppear: @escaping @MainActor (EnvironmentStore<State>) -> Void,
        onContainerDisappear: @escaping @MainActor (EnvironmentStore<State>) -> Void,
        onContainerDidLoad: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDidUnload: @escaping (EnvironmentStore<State>) -> Void,
        onBindableReducerDidLoad: @escaping (EnvironmentStore<State>) -> Void,
        onBindableReducerDidUnload: @escaping (EnvironmentStore<State>) -> Void,
        useHooks: @escaping () -> [Hook<State>]
    ) where BindedContainer.ID: Sendable {
        self.store = store
        self.map = map
        self.scope = scope
        self.onContainerAppear = onContainerAppear
        self.onContainerDisappear = onContainerDisappear
        let wrappedUseHooks = {
            var hooks = useHooks()
            if let syntheticHook = Self.makeStateDidLoadHook(
                store: store,
                containerType: containerType,
                id: containerId(),
                onBindableReducerDidLoad: onBindableReducerDidLoad
            ) {
                hooks.append(syntheticHook)
            }
            return hooks
        }

        self._containerLifecycle = .init(
            wrappedValue: ContainerLifecycle(
                didLoadCommand: { store in
                    let id = containerId()
                    Self.handleContainerDidLoad(
                        containerType: containerType,
                        id: id,
                        store: store,
                        onContainerDidLoad: onContainerDidLoad
                    )
                },
                didUnloadCommand: { store in
                    onContainerDidUnload(store)
                    
                    let id = containerId()
                    Self.handleContainerDidUnload(
                        containerType: containerType,
                        id: id,
                        store: store,
                        onBindableReducerDidUnload: onBindableReducerDidUnload
                    )
                    
                    store.dispatch(
                        Actions._OnContainerDidUnLoad(containerType: containerType, id: id)
                            .with(delay: 0.15)
                            .silent()
                    )
                },
                useHooks: wrappedUseHooks
            )
        )
        self._containerState = .init(wrappedValue: .init(store: store, scope: scope))
    }

    /// The main view body that renders the component and attaches lifecycle events.
    var body: some View {
        containerLifecycle.set(didLoad: true, store: store)
        
        return C(props: map(store))
            .onAppear { onContainerAppear(store) }
            .onDisappear { onContainerDisappear(store) }
    }
}

extension ConnectedContainer {
    /// Resolves and returns the bound reducer associated with a container type.
    ///
    /// Uses cached property metadata inside the `SourceOfTruth` wrapper to avoid repeatedly reflecting over
    /// the entire `AppState` properties list.
    ///
    /// - Parameters:
    ///   - state: The copy of the store's state.
    ///   - store: The environment store containing the state and cache.
    ///   - type: The type of the bindable container.
    /// - Returns: The matched bindable reducer existential, or `nil` if not found.
    static func getBoundReducer<T: BindableContainer>(
        from state: State,
        with store: EnvironmentStore<State>,
        for type: T.Type
    ) -> (any AnyBindableReducer)? {
        if let property = store.$state.getPropertyMetadata(for: T.self) {
            return try? property.get(from: state) as? AnyBindableReducer
        }
        
        guard let info = try? typeInfo(of: State.self) else {
            return nil
        }
        
        for property in info.properties {
            if let bindableReducer = try? property.get(from: state) as? AnyBindableReducer {
                store.$state.setPropertyMetadata(property, for: bindableReducer.boundContainerType)
                if bindableReducer.boundContainerType == T.self {
                    return bindableReducer
                }
            }
        }
        
        return nil
    }

    /// Builds a synthetic hook that monitors the online state of a bindable reducer
    /// and triggers `onBindableReducerDidLoad` once the reducer is online.
    static func makeStateDidLoadHook<T: BindableContainer>(
        store: EnvironmentStore<State>,
        containerType: T.Type,
        id: T.ID,
        onBindableReducerDidLoad: @escaping (EnvironmentStore<State>) -> Void
    ) -> Hook<State>? where T.ID: Sendable {
        guard getBoundReducer(
            from: store.state,
            with: store,
            for: containerType
        )?.hasReducer(for: id) == false else {
            return nil
        }
        
        return Hook(
            id: "onBindableReducerDidLoad-\(id)",
            type: .oneTime,
            condition: { state in
                getBoundReducer(from: state, with: store, for: containerType)?.hasReducer(for: id) == true
            },
            block: { store in
                onBindableReducerDidLoad(store)
            }
        )
    }

    /// Handles the load event of a `BindableContainer` by tracking its active container instance count
    /// and executing the required load actions.
    ///
    /// This method increments the reference count in `BaseContainerLifecycle.activeContainersCount`
    /// for the given container type and identifier. It also dispatches the internal `_OnContainerDidLoad`
    /// action to the store and triggers the custom `onContainerDidLoad` callback.
    ///
    /// - Parameters:
    ///   - containerType: The metatype of the container being loaded (e.g., `MyContainer.self`).
    ///   - id: The unique domain identifier of the container instance.
    ///   - store: The environment store containing the global state.
    ///   - onContainerDidLoad: A callback closure to execute on container load.
    @MainActor
    static func handleContainerDidLoad<T: BindableContainer>(
        containerType: T.Type,
        id: T.ID,
        store: EnvironmentStore<State>,
        onContainerDidLoad: @escaping (EnvironmentStore<State>) -> Void
    ) {
        let key = BaseContainerLifecycle.ActiveContainerKey(containerType: ObjectIdentifier(containerType), id: id)
        BaseContainerLifecycle.activeContainersCount[key, default: 0] += 1
        
        store.dispatch(
            Actions._OnContainerDidLoad(containerType: containerType, id: id).silent(),
            priority: .userInteractive
        )
        onContainerDidLoad(store)
    }

    /// Handles the unload event of a `BindableContainer` by decrementing its active container instance count
    /// and executing state unloading if no active instances remain.
    ///
    /// ### Rationale for This Logic
    /// When multiple instances of the same container layout (sharing the same metatype and domain ID) are deallocated
    /// at the same time, checking the store's state directly to determine if an instance is the "last one" is prone to race conditions.
    /// Because the store state updates asynchronously, when two deallocating instances query the store, the delayed 
    /// `_OnContainerDidUnLoad` action has not been reduced yet. Both instances inspect the store state, see that the 
    /// reference count in the state is still 2 (meaning they both think another instance remains active), and conclude 
    /// that they are not the last instance. Consequently, `isLastInstance` returns false for both, and neither triggers 
    /// `onBindableReducerDidUnload`.
    ///
    /// To resolve this and ensure the unload is reliably triggered:
    /// 1. We maintain a local, synchronous reference count in `BaseContainerLifecycle.activeContainersCount`.
    /// 2. When an instance is deallocated, we decrement this count.
    /// 3. The instance that decrements the count to zero removes the key and schedules a 150ms delay using `Task.sleep`.
    /// 4. After the delay, we verify if the container's active count remains zero (confirming no new instance has been loaded
    ///    in the meantime). Only then do we execute the full state teardown (`onBindableReducerDidUnload`).
    ///
    /// - Parameters:
    ///   - containerType: The metatype of the container being unloaded (e.g., `MyContainer.self`).
    ///   - id: The unique domain identifier of the container instance.
    ///   - store: The environment store containing the global state.
    ///   - onBindableReducerDidUnload: A callback closure to execute when the bindable state unloads.
    @MainActor
    static func handleContainerDidUnload<T: BindableContainer>(
        containerType: T.Type,
        id: T.ID,
        store: EnvironmentStore<State>,
        onBindableReducerDidUnload: @escaping (EnvironmentStore<State>) -> Void
    ) {
        let key = BaseContainerLifecycle.ActiveContainerKey(containerType: ObjectIdentifier(containerType), id: id)
        guard let count = BaseContainerLifecycle.activeContainersCount[key] else { return }
        
        if (count - 1) <= 0 {
            BaseContainerLifecycle.activeContainersCount.removeValue(forKey: key)
            
            Task {
                try? await Task.sleep(for: .milliseconds(150))
                if BaseContainerLifecycle.activeContainersCount[key] == nil {
                    onBindableReducerDidUnload(store)
                }
            }
        } else {
            BaseContainerLifecycle.activeContainersCount[key] = count - 1
        }
    }
}
