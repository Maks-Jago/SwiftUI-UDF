//===--- FeatureStateBindableContainerLifecycleTests.swift --------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI
import Testing
@testable import UDF
import UDFSwiftTesting

/// Renders real `BindableContainer`s whose reducers live in a `FeatureState`, covering the three ways a
/// feature can own bindable state: declared directly in the feature, grouped in a nested `Reducible`, and
/// the feature mounted as a bindable reducer itself.
@MainActor
@Suite("Bindable container lifecycle with reducers in a FeatureState")
struct FeatureStateBindableContainerLifecycleTests {
    @Test("Bindable reducers declared in a FeatureState are created and released with their container")
    func bindablesDeclaredInFeatureState() async {
        let store = EnvironmentStore(initial: DirectAppState(), loggers: [])
        let events = LifecycleEvents()
        let id = 1

        var window: PlatformWindow? = await PlatformWindow.render(
            view: DirectContainer(id: id, events: events).with(store: store)
        )
        window?.redraw()

        let created = await waitForMainActorCondition {
            store.state.feature.form.reducers[id] != nil && store.state.feature.flow.reducers[id] != nil
        }
        #expect(created)

        // `ConnectedContainer.getBoundReducer` only searches the app state's own properties, so it never finds
        // a bindable reducer inside a feature and the did-load hook is never created.
        await withKnownIssue("onBindableReducerDidLoad never fires for bindable reducers inside a FeatureState") {
            #expect(await waitForMainActorCondition(timeout: 1) { events.didLoadCount == 1 })
        }

        window?.release()
        window = nil

        let released = await waitForMainActorCondition {
            store.state.feature.form.reducers[id] == nil && store.state.feature.flow.reducers[id] == nil
        }
        #expect(released)
        #expect(await waitForMainActorCondition { events.didUnloadCount == 1 })
    }

    @Test("Bindable reducers grouped in a Reducible inside a FeatureState are created and released with their container")
    func bindablesGroupedInFeatureState() async {
        let store = EnvironmentStore(initial: GroupedAppState(), loggers: [])
        let events = LifecycleEvents()
        let id = 1

        var window: PlatformWindow? = await PlatformWindow.render(
            view: GroupedContainer(id: id, events: events).with(store: store)
        )
        window?.redraw()

        let created = await waitForMainActorCondition {
            store.state.feature.details.form.reducers[id] != nil && store.state.feature.details.flow.reducers[id] != nil
        }
        #expect(created)

        await withKnownIssue("onBindableReducerDidLoad never fires for bindable reducers inside a FeatureState") {
            #expect(await waitForMainActorCondition(timeout: 1) { events.didLoadCount == 1 })
        }

        window?.release()
        window = nil

        let released = await waitForMainActorCondition {
            store.state.feature.details.form.reducers[id] == nil && store.state.feature.details.flow.reducers[id] == nil
        }
        #expect(released)
        #expect(await waitForMainActorCondition { events.didUnloadCount == 1 })
    }

    @Test("A FeatureState mounted as a bindable reducer is created and released with its container")
    func featureStateMountedAsBindableReducer() async {
        let store = EnvironmentStore(initial: BindableFeatureAppState(), loggers: [])
        let events = LifecycleEvents()
        let id = 1

        var window: PlatformWindow? = await PlatformWindow.render(
            view: BindableFeatureContainer(id: id, events: events).with(store: store)
        )
        window?.redraw()

        #expect(await waitForMainActorCondition { store.state.item.reducers[id] != nil })
        #expect(await waitForMainActorCondition { events.didLoadCount == 1 })

        window?.release()
        window = nil

        #expect(await waitForMainActorCondition { store.state.item.reducers[id] == nil })
        #expect(await waitForMainActorCondition { events.didUnloadCount == 1 })
    }
}

// MARK: - Shared fixtures

@MainActor
private final class LifecycleEvents {
    var didLoadCount = 0
    var didUnloadCount = 0
}

private struct ItemForm: UDF.Form {
    var title = ""
}

private enum ItemFlow: IdentifiableFlow {
    case none
    case loading

    init() {
        self = .none
    }
}

private struct EmptyComponent: Component {
    struct Props {}

    var props: Props

    var body: some View {
        EmptyView()
    }
}

// MARK: - Bindable reducers declared in a FeatureState

private struct DirectAppState: AppReducer {
    var feature = DirectFeatureState()
}

private struct DirectFeatureState: FeatureState {
    typealias AppState = DirectAppState
    typealias FeatureRouting = EmptyRouting

    @BindableReducer(ItemForm.self, bindedTo: DirectContainer.self)
    var form

    @BindableReducer(ItemFlow.self, bindedTo: DirectContainer.self)
    var flow

    static func entryPoint(input: Int) -> EmptyView {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<DirectAppState>) -> [MiddlewareWrapper<DirectAppState>] {}
}

private struct DirectContainer: BindableContainer {
    typealias ContainerComponent = EmptyComponent

    let id: Int
    let events: LifecycleEvents

    func scope(for state: DirectAppState) -> Scope {
        state.feature.form[id]
        state.feature.flow[id]
    }

    func map(store: EnvironmentStore<DirectAppState>) -> EmptyComponent.Props {
        .init()
    }

    func onBindableReducerDidLoad(store: EnvironmentStore<DirectAppState>) {
        events.didLoadCount += 1
    }

    func onBindableReducerDidUnload(store: EnvironmentStore<DirectAppState>) {
        events.didUnloadCount += 1
    }
}

// MARK: - Bindable reducers grouped in a Reducible inside a FeatureState

private struct GroupedAppState: AppReducer {
    var feature = GroupedFeatureState()
}

private struct GroupedFeatureState: FeatureState {
    typealias AppState = GroupedAppState
    typealias FeatureRouting = EmptyRouting

    var details = ItemReducers<GroupedContainer>()

    static func entryPoint(input: Int) -> EmptyView {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<GroupedAppState>) -> [MiddlewareWrapper<GroupedAppState>] {}
}

private struct ItemReducers<Container: BindableContainer>: Reducible {
    @BindableReducer(ItemForm.self, bindedTo: Container.self)
    var form

    @BindableReducer(ItemFlow.self, bindedTo: Container.self)
    var flow
}

private struct GroupedContainer: BindableContainer {
    typealias ContainerComponent = EmptyComponent

    let id: Int
    let events: LifecycleEvents

    func scope(for state: GroupedAppState) -> Scope {
        state.feature.details.form[id]
        state.feature.details.flow[id]
    }

    func map(store: EnvironmentStore<GroupedAppState>) -> EmptyComponent.Props {
        .init()
    }

    func onBindableReducerDidLoad(store: EnvironmentStore<GroupedAppState>) {
        events.didLoadCount += 1
    }

    func onBindableReducerDidUnload(store: EnvironmentStore<GroupedAppState>) {
        events.didUnloadCount += 1
    }
}

// MARK: - FeatureState mounted as a bindable reducer

private struct BindableFeatureAppState: AppReducer {
    @BindableReducer(ItemFeatureState.self, bindedTo: BindableFeatureContainer.self)
    var item
}

private struct ItemFeatureState: FeatureState {
    typealias AppState = BindableFeatureAppState
    typealias FeatureRouting = EmptyRouting

    var form = ItemForm()
    var flow = ItemFlow()

    static func entryPoint(input: Int) -> EmptyView {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<BindableFeatureAppState>) -> [MiddlewareWrapper<BindableFeatureAppState>] {}
}

private struct BindableFeatureContainer: BindableContainer {
    typealias ContainerComponent = EmptyComponent

    let id: Int
    let events: LifecycleEvents

    func scope(for state: BindableFeatureAppState) -> Scope {
        state.item[id]
    }

    func map(store: EnvironmentStore<BindableFeatureAppState>) -> EmptyComponent.Props {
        .init()
    }

    func onBindableReducerDidLoad(store: EnvironmentStore<BindableFeatureAppState>) {
        events.didLoadCount += 1
    }

    func onBindableReducerDidUnload(store: EnvironmentStore<BindableFeatureAppState>) {
        events.didUnloadCount += 1
    }
}
