//===--- FeatureStateNestedBindableLookupTests.swift --------------===//
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

/// Renders real `BindableContainer`s whose bindable reducers sit deeper than one level inside a `FeatureState`,
/// next to a second feature, and loads a second container after the first one.
@MainActor
@Suite("Bindable container lifecycle with bindable reducers nested in several reducers")
struct FeatureStateNestedBindableLookupTests {
    @Test("A bindable reducer nested three levels deep in a FeatureState reports load and unload once")
    func deeplyNested() async {
        let store = EnvironmentStore(initial: DeepAppState(), loggers: [])
        let events = LookupEvents()

        var window: PlatformWindow? = await PlatformWindow.render(
            view: DeepContainer(id: 1, events: events).with(store: store)
        )
        window?.redraw()

        #expect(await waitForMainActorCondition { store.state.feature.outer.inner.deeper.form.reducers[1] != nil })

        await withKnownIssue("onBindableReducerDidLoad never fires for bindable reducers inside a FeatureState") {
            #expect(await waitForMainActorCondition(timeout: 1) { events.didLoadCount == 1 })
        }

        window?.release()
        window = nil

        #expect(await waitForMainActorCondition { store.state.feature.outer.inner.deeper.form.reducers[1] == nil })
        #expect(await waitForMainActorCondition { events.didUnloadCount == 1 })
    }

    @Test("Bindable reducers in two different FeatureStates each report load and unload")
    func twoFeatures() async {
        let store = EnvironmentStore(initial: TwoFeaturesAppState(), loggers: [])
        let eventsA = LookupEvents()
        let eventsB = LookupEvents()

        var window: PlatformWindow? = await PlatformWindow.render(
            view: VStack {
                LookupContainerA(id: 1, events: eventsA).with(store: store)
                LookupContainerB(id: 1, events: eventsB).with(store: store)
            }
        )
        window?.redraw()

        #expect(await waitForMainActorCondition { store.state.featureA.form.reducers[1] != nil })
        #expect(await waitForMainActorCondition { store.state.featureB.form.reducers[1] != nil })

        await withKnownIssue("onBindableReducerDidLoad never fires for bindable reducers inside a FeatureState") {
            #expect(await waitForMainActorCondition(timeout: 1) { eventsA.didLoadCount == 1 })
        }
        await withKnownIssue("onBindableReducerDidLoad never fires for bindable reducers inside a FeatureState") {
            #expect(await waitForMainActorCondition(timeout: 1) { eventsB.didLoadCount == 1 })
        }

        window?.release()
        window = nil

        #expect(await waitForMainActorCondition { eventsA.didUnloadCount == 1 })
        #expect(await waitForMainActorCondition { eventsB.didUnloadCount == 1 })
    }

    @Test("A container with another ID loaded later reports load once and does not repeat it for the first one")
    func secondContainerLoadedLater() async {
        let store = EnvironmentStore(initial: DeepAppState(), loggers: [])
        let first = LookupEvents()
        let second = LookupEvents()

        var window: PlatformWindow? = await PlatformWindow.render(
            view: DeepContainer(id: 1, events: first).with(store: store)
        )
        window?.redraw()

        await withKnownIssue("onBindableReducerDidLoad never fires for bindable reducers inside a FeatureState") {
            #expect(await waitForMainActorCondition(timeout: 1) { first.didLoadCount == 1 })
        }

        var other: PlatformWindow? = await PlatformWindow.render(
            view: DeepContainer(id: 2, events: second).with(store: store)
        )
        other?.redraw()

        await withKnownIssue("onBindableReducerDidLoad never fires for bindable reducers inside a FeatureState") {
            #expect(await waitForMainActorCondition(timeout: 1) { second.didLoadCount == 1 })
        }
        await withKnownIssue("onBindableReducerDidLoad never fires for bindable reducers inside a FeatureState") {
            #expect(first.didLoadCount == 1, "The first container must not report load again")
        }

        window?.release()
        window = nil
        other?.release()
        other = nil

        #expect(await waitForMainActorCondition { first.didUnloadCount == 1 && second.didUnloadCount == 1 })
    }
}

// MARK: - Shared fixtures

@MainActor
private final class LookupEvents {
    var didLoadCount = 0
    var didUnloadCount = 0
}

private struct LookupForm: UDF.Form {
    var title = ""
}

private struct LookupComponent: Component {
    struct Props {}

    var props: Props

    var body: some View {
        Text("body")
    }
}

// MARK: - Three levels deep: feature -> outer -> inner -> deeper -> @BindableReducer

private struct DeepAppState: AppReducer {
    var feature = DeepFeatureState()
}

private struct DeepFeatureState: FeatureState {
    typealias AppState = DeepAppState
    typealias FeatureRouting = EmptyRouting

    var outer = DeepOuter()

    static func entryPoint(input: Int) -> EmptyView {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<DeepAppState>) -> [MiddlewareWrapper<DeepAppState>] {}
}

private struct DeepOuter: Reducible {
    var inner = DeepInner()
}

private struct DeepInner: Reducible {
    var deeper = DeepDeeper()
}

private struct DeepDeeper: Reducible {
    @BindableReducer(LookupForm.self, bindedTo: DeepContainer.self)
    var form
}

private struct DeepContainer: BindableContainer {
    typealias ContainerComponent = LookupComponent

    let id: Int
    let events: LookupEvents

    func scope(for state: DeepAppState) -> Scope {
        state.feature.outer.inner.deeper.form[id]
    }

    func map(store: EnvironmentStore<DeepAppState>) -> LookupComponent.Props {
        .init()
    }

    func onBindableReducerDidLoad(store: EnvironmentStore<DeepAppState>) {
        events.didLoadCount += 1
    }

    func onBindableReducerDidUnload(store: EnvironmentStore<DeepAppState>) {
        events.didUnloadCount += 1
    }
}

// MARK: - Two features, each with its own bindable reducer and container type

private struct TwoFeaturesAppState: AppReducer {
    var featureA = LookupFeatureA()
    var featureB = LookupFeatureB()
}

private struct LookupFeatureA: FeatureState {
    typealias AppState = TwoFeaturesAppState
    typealias FeatureRouting = EmptyRouting

    @BindableReducer(LookupForm.self, bindedTo: LookupContainerA.self)
    var form

    static func entryPoint(input: Int) -> EmptyView {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<TwoFeaturesAppState>) -> [MiddlewareWrapper<TwoFeaturesAppState>] {}
}

private struct LookupFeatureB: FeatureState {
    typealias AppState = TwoFeaturesAppState
    typealias FeatureRouting = EmptyRouting

    @BindableReducer(LookupForm.self, bindedTo: LookupContainerB.self)
    var form

    static func entryPoint(input: Int) -> EmptyView {
        EmptyView()
    }

    static func registerMiddlewares(in store: any Store<TwoFeaturesAppState>) -> [MiddlewareWrapper<TwoFeaturesAppState>] {}
}

private struct LookupContainerA: BindableContainer {
    typealias ContainerComponent = LookupComponent

    let id: Int
    let events: LookupEvents

    func scope(for state: TwoFeaturesAppState) -> Scope {
        state.featureA.form[id]
    }

    func map(store: EnvironmentStore<TwoFeaturesAppState>) -> LookupComponent.Props {
        .init()
    }

    func onBindableReducerDidLoad(store: EnvironmentStore<TwoFeaturesAppState>) {
        events.didLoadCount += 1
    }

    func onBindableReducerDidUnload(store: EnvironmentStore<TwoFeaturesAppState>) {
        events.didUnloadCount += 1
    }
}

private struct LookupContainerB: BindableContainer {
    typealias ContainerComponent = LookupComponent

    let id: Int
    let events: LookupEvents

    func scope(for state: TwoFeaturesAppState) -> Scope {
        state.featureB.form[id]
    }

    func map(store: EnvironmentStore<TwoFeaturesAppState>) -> LookupComponent.Props {
        .init()
    }

    func onBindableReducerDidLoad(store: EnvironmentStore<TwoFeaturesAppState>) {
        events.didLoadCount += 1
    }

    func onBindableReducerDidUnload(store: EnvironmentStore<TwoFeaturesAppState>) {
        events.didUnloadCount += 1
    }
}
