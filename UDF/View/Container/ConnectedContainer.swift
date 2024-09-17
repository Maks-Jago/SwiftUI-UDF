//
//  ConnectedContainer.swift
//
//
//  Created by Max Kuznetsov on 07.09.2024.
//

import Foundation
import SwiftUI

struct ConnectedContainer<C: Component, State: AppReducer>: View {
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
        hooks: @escaping () -> [Hook<State>]
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

    init<BindedContainer: BindableContainer>(
        containerType: BindedContainer.Type,
        containerId: @escaping () -> BindedContainer.ID,
        map: @escaping (EnvironmentStore<State>) -> C.Props,
        scope: @escaping (State) -> Scope,
        onContainerAppear: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDisappear: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDidLoad: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDidUnload: @escaping (EnvironmentStore<State>) -> Void,
        hooks: @escaping () -> [Hook<State>]
    ) {
        self.map = map
        self.scope = scope
        self.onContainerAppear = onContainerAppear
        self.onContainerDisappear = onContainerDisappear
        self._containerLifecycle = .init(
            wrappedValue: ContainerLifecycle(
                didLoadCommand: { store in
                    store.dispatch(Actions._OnContainerDidLoad(containerType: containerType, id: containerId()).silent(), priority: .userInteractive)
                    onContainerDidLoad(store)
                },
                didUnloadCommand: { store in
                    onContainerDidUnload(store)
                    store.dispatch(Actions._OnContainerDidUnLoad(containerType: containerType, id: containerId()).silent())
                },
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
