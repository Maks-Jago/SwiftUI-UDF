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
    @HookBuilder<ContainerState> func useHooks() -> [Hook<ContainerState>]
}

public extension Container {
    func onContainerAppear(store: EnvironmentStore<ContainerState>) {}
    func onContainerDisappear(store: EnvironmentStore<ContainerState>) {}
    func onContainerDidLoad(store: EnvironmentStore<ContainerState>) {}
    func onContainerDidUnload(store: EnvironmentStore<ContainerState>) {}
    func useHooks() -> [Hook<ContainerState>] { [] }
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
            onContainerDidUnload: onContainerDidUnload,
            useHooks: useHooks
        )
    }
}
