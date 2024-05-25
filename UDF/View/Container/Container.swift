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

    func onContainerAppear(store: EnvironmentStore<ContainerState>)
    func onContainerDisappear(store: EnvironmentStore<ContainerState>)

    func onContainerDidLoad(store: EnvironmentStore<ContainerState>)
}

public extension Container {
    @MainActor func onContainerAppear(store: EnvironmentStore<ContainerState>) {}
    @MainActor func onContainerDisappear(store: EnvironmentStore<ContainerState>) {}
    @MainActor func onContainerDidLoad(store: EnvironmentStore<ContainerState>) {}
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
            onContainerDidLoad: onContainerDidLoad
        )
    }
}

fileprivate struct ConnectedContainer<C: Component, State: AppReducer>: View {
    let map: (_ store: EnvironmentStore<State>) -> C.Props
    let scope: (_ state: State) -> Scope
    
    var onContainerAppear: (EnvironmentStore<State>) -> Void
    var onContainerDisappear: (EnvironmentStore<State>) -> Void

    @StateObject var containerDidLoad: ContainerDidLoad<State>
    @ObservedObject var containerState: ContainerState<State>

    private var store: EnvironmentStore<State> { .global }

    init(
        map: @escaping (EnvironmentStore<State>) -> C.Props,
        scope: @escaping (State) -> Scope,
        onContainerAppear: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDisappear: @escaping (EnvironmentStore<State>) -> Void,
        onContainerDidLoad: @escaping (EnvironmentStore<State>) -> Void
    ) {
        self.map = map
        self.scope = scope
        self.onContainerAppear = onContainerAppear
        self.onContainerDisappear = onContainerDisappear
        self._containerDidLoad = .init(wrappedValue: ContainerDidLoad(command: onContainerDidLoad))
        self._containerState = .init(wrappedValue: .init(store: EnvironmentStore<State>.global, scope: scope))
    }

    var body: some View {
        containerDidLoad.set(didLoad: true, store: store)

        return C(props: map(store))
            .onAppear { onContainerAppear(store) }
            .onDisappear { onContainerDisappear(store) }
    }
}

fileprivate final class ContainerDidLoad<State: AppReducer>: ObservableObject {
    private var didLoad: Bool = false

    func set(didLoad: Bool, store: EnvironmentStore<State>) {
        if !self.didLoad, didLoad {
            didLoadCommand(store)
        }

        self.didLoad = didLoad
    }

    var didLoadCommand: CommandWith<EnvironmentStore<State>>

    init(command: @escaping CommandWith<EnvironmentStore<State>>) {
        didLoadCommand = command
    }
}
