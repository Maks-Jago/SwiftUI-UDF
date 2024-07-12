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
}

public extension Container {
    func onContainerAppear(store: EnvironmentStore<ContainerState>) {}
    func onContainerDisappear(store: EnvironmentStore<ContainerState>) {}
    func onContainerDidLoad(store: EnvironmentStore<ContainerState>) {}
    func onContainerDidUnload(store: EnvironmentStore<ContainerState>) {}
}

public extension Container {

    var store: EnvironmentStore<ContainerState> { .global }

    @MainActor
    var body: some View {
        ConnectedContainer<ContainerComponent, ContainerState>(
            map: map,
            scope: scope(for:),
            onContainerAppear: onContainerAppear,
            onContainerDisappear: onContainerDisappear,
            onContainerDidLoad: onContainerDidLoad,
            onContainerDidUnload: onContainerDidUnload
        )
    }

    @MainActor
    func addHoook(
        id: some Hashable,
        type: HookType = .default,
        condition: @escaping (_ state: ContainerState) -> Bool, 
        block: @escaping (_ store: EnvironmentStore<ContainerState>) -> Void
    ) {
        (self.body as? ConnectedContainer<ContainerComponent, ContainerState>)?
            .addHoook(id: id, type: type, condition: condition, block: block)
    }
}


fileprivate struct ConnectedContainer<C: Component, State: AppReducer>: View {
    let map: (_ store: EnvironmentStore<State>) -> C.Props
    let scope: (_ state: State) -> Scope
    
    var onContainerAppear: (EnvironmentStore<State>) -> Void
    var onContainerDisappear: (EnvironmentStore<State>) -> Void

    @StateObject var containerLifecycle: ContainerLifecycle<State>
//    @StateObject var containerHooks: ContainerHooks<State>
    @ObservedObject var containerState: ContainerState<State>

    private var store: EnvironmentStore<State> { .global }

    init(
        map: @escaping (EnvironmentStore<State>) -> C.Props,
        scope: @escaping (State) -> Scope,
        onContainerAppear: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDisappear: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDidLoad: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDidUnload: @escaping (EnvironmentStore<State>) -> Void
    ) {
        self.map = map
        self.scope = scope
        self.onContainerAppear = onContainerAppear
        self.onContainerDisappear = onContainerDisappear
        self._containerLifecycle = .init(
            wrappedValue: ContainerLifecycle(
                didLoadCommand: onContainerDidLoad,
                didUnloadCommand: onContainerDidUnload
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

    func addHoook(
        id: some Hashable,
        type: HookType = .default,
        condition: @escaping (_ state: State) -> Bool,
        block: @escaping (_ store: EnvironmentStore<State>) -> Void
    ) {
        let hook = Hook(type: type, condition: condition, block: block)
        containerLifecycle.containerHooks.add(hook: hook, id: id)
    }
}
