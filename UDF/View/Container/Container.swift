//
//  Container.swift
//  UDF
//
//  Created by Max Kuznetsov on 04.06.2020.
//  Copyright © 2020 Max Kuznetsov. All rights reserved.
//

import SwiftUI

public protocol Container<ContainerState>: View {
    associatedtype ContainerState: AppReducer
    associatedtype ContainerComponent: Component

    func map(store: EnvironmentStore<ContainerState>) -> ContainerComponent.Props
    @ScopeBuilder func scope(for state: ContainerState) -> Scope

    @MainActor func onContainerAppear(store: EnvironmentStore<ContainerState>)
    @MainActor func onContainerDisappear(store: EnvironmentStore<ContainerState>)

    @MainActor func onContainerDidLoad(store: EnvironmentStore<ContainerState>)
    @MainActor func onContainerDidUnload(store: EnvironmentStore<ContainerState>)
    @MainActor func containerHooks(_ builder: HookBuilder<ContainerState>)
}

public extension Container {
    func onContainerAppear(store: EnvironmentStore<ContainerState>) {}
    func onContainerDisappear(store: EnvironmentStore<ContainerState>) {}
    func onContainerDidLoad(store: EnvironmentStore<ContainerState>) {}
    func onContainerDidUnload(store: EnvironmentStore<ContainerState>) {}
    func containerHooks(_ builder: HookBuilder<ContainerState>) {}
}

public extension Container {

    var store: EnvironmentStore<ContainerState> { .global }

    @MainActor
    var body: some View {
        let builder = HookBuilder<ContainerState>()
        containerHooks(builder)
        
        return ConnectedContainer<ContainerComponent, ContainerState>(
            map: map,
            scope: scope(for:),
            onContainerAppear: onContainerAppear,
            onContainerDisappear: onContainerDisappear,
            onContainerDidLoad: onContainerDidLoad,
            onContainerDidUnload: onContainerDidUnload,
            hooks: builder.build()
        )
    }
}


fileprivate struct ConnectedContainer<C: Component, State: AppReducer>: View {
    let map: (_ store: EnvironmentStore<State>) -> C.Props
    let scope: (_ state: State) -> Scope
    
    var onContainerAppear: (EnvironmentStore<State>) -> Void
    var onContainerDisappear: (EnvironmentStore<State>) -> Void

    @StateObject var containerLifecycle: ContainerLifecycle<State>
    @ObservedObject var containerState: ContainerState<State>

    private var store: EnvironmentStore<State> { .global }

    init(
        map: @escaping (EnvironmentStore<State>) -> C.Props,
        scope: @escaping (State) -> Scope,
        onContainerAppear: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDisappear: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDidLoad: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDidUnload: @escaping (EnvironmentStore<State>) -> Void,
        hooks: [Hook<State>]
    ) {
        self.map = map
        self.scope = scope
        self.onContainerAppear = onContainerAppear
        self.onContainerDisappear = onContainerDisappear
        self._containerLifecycle = .init(
            wrappedValue: ContainerLifecycle(
                didLoadCommand: onContainerDidLoad,
                didUnloadCommand: onContainerDidUnload,
                hooks: hooks
            )
        )
        self._containerState = .init(wrappedValue: .init(store: EnvironmentStore<State>.global, scope: scope))
    }

    var body: some View {
        containerLifecycle.set(didLoad: true, store: store)

        return C(props: map(store))
            .onAppear { onContainerAppear(store) }
            .onDisappear { onContainerDisappear(store) }
    }
}
