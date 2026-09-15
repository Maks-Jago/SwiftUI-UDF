//===--- CrossModuleFeatureIntegrationTests.swift -----------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Testing
import UDF
@testable import UDFModularizationTestFeature
import UDFSwiftTesting

@Suite("Cross-module feature integration")
struct CrossModuleFeatureIntegrationTests {
    @Test("An externally composed feature completes the full normalized loading path")
    func externallyComposedFeatureCompletesLoadingPath() async throws {
        let page = 2
        let expectedItems = [
            ModularizationTestItem(id: 3, title: "Test item 3"),
            ModularizationTestItem(id: 4, title: "Test item 4"),
        ]
        let store = await TestStore(initial: AppState())

        await store.dispatch(Actions.LoadPage(pageNumber: page, id: ModularizationTestFlow.id))
        await store.wait()

        let state = await store.state
        #expect(state.modularizationTestFeature.flow == .none)
        #expect(state.modularizationTestFeature.form.paginator.elements == expectedItems.map(\.id))
        #expect(state.modularizationTestFeature.form.paginator.page == .number(page))
        #expect(state.allModularizationTestItems.byId.count == expectedItems.count)

        for expectedItem in expectedItems {
            let storedItem = try #require(state.allModularizationTestItems.byId[expectedItem.id])
            #expect(storedItem == expectedItem)
        }
    }

    @TestStoreActor
    @Test("A stateless feature has empty registration and preserves entry input")
    func statelessFeatureUsesDefaultsAndPreservesInput() async {
        let input = ModularizationTestSettingsInput(title: "Settings payload")
        let destination = ModularizationTestSettingsFeatureState<AppState>.entryPoint(
            input: input
        )
        let store = TestStore(initial: AppState())
        var wrappers: [MiddlewareWrapper<AppState>] = []
        await store.subscribe { store in
            wrappers = ModularizationTestSettingsFeatureState<AppState>.registerMiddlewares(in: store)
            return wrappers
        }

        #expect(destination.input == input)
        #expect(wrappers.isEmpty)
    }

    @Test("An externally composed feature recovers from errors and resets flow")
    func externallyComposedFeatureHandlesErrorAndResetsFlow() async throws {
        struct TestError: Error, Equatable {}

        let store = await TestStore(
            initial: AppState(),
            registerFeatureMiddlewares: false
        )
        await store.subscribe(
            ModularizationTestMiddleware<AppState>.self,
            environment: .test { _ in throw TestError() }
        )

        await store.dispatch(Actions.LoadPage(pageNumber: 1, id: ModularizationTestFlow.id))
        await store.wait()

        let state = await store.state
        #expect(state.modularizationTestFeature.flow == .none)
        #expect(state.actionTracker.didCatchError)
        #expect(state.modularizationTestFeature.form.paginator.elements.isEmpty)
    }

    @Test("An externally composed feature cancels in-flight load and resets flow")
    func externallyComposedFeatureHandlesCancellation() async throws {
        let store = await TestStore(
            initial: AppState(),
            registerFeatureMiddlewares: false
        )
        await store.subscribe(
            ModularizationTestMiddleware<AppState>.self,
            environment: .test { _ in throw CancellationError() }
        )

        await store.dispatch(Actions.LoadPage(pageNumber: 1, id: ModularizationTestFlow.id))
        await store.wait()

        let state = await store.state
        #expect(state.modularizationTestFeature.flow == .none)
        #expect(state.actionTracker.didCancel)
        #expect(state.modularizationTestFeature.form.paginator.elements.isEmpty)
    }

    @Test("An externally composed feature loads subsequent pages accumulating items")
    func externallyComposedFeatureLoadsSubsequentPages() async throws {
        let page1Items = [
            ModularizationTestItem(id: 1, title: "Test item 1"),
            ModularizationTestItem(id: 2, title: "Test item 2"),
        ]
        let page2Items = [
            ModularizationTestItem(id: 3, title: "Test item 3"),
            ModularizationTestItem(id: 4, title: "Test item 4"),
        ]
        let store = await TestStore(initial: AppState())

        await store.dispatch(Actions.LoadPage(pageNumber: 1, id: ModularizationTestFlow.id))
        await store.wait()

        var state = await store.state
        #expect(state.modularizationTestFeature.flow == .none)
        #expect(state.modularizationTestFeature.form.paginator.elements == [1, 2])
        #expect(state.modularizationTestFeature.form.paginator.page == .number(1))

        await store.dispatch(Actions.LoadPage(pageNumber: 2, id: ModularizationTestFlow.id))
        await store.wait()

        state = await store.state
        #expect(state.modularizationTestFeature.flow == .none)
        #expect(state.modularizationTestFeature.form.paginator.elements == [1, 2, 3, 4])
        #expect(state.modularizationTestFeature.form.paginator.page == .number(2))
        #expect(state.allModularizationTestItems.byId.count == 4)

        for item in page1Items + page2Items {
            let storedItem = try #require(state.allModularizationTestItems.byId[item.id])
            #expect(storedItem == item)
        }
    }
}

// MARK: - App State & Composition

private struct AppState:
    AppReducer,
    ModularizationTestFeature,
    ModularizationTestSettingsFeature
{
    typealias Environments = TestEnvironments

    var allModularizationTestItems = AllModularizationTestItems()
    var modularizationTestFeature = ModularizationTestFeatureState<AppState>()
    var modularizationTestSettings = ModularizationTestSettingsFeatureState<AppState>()
    var actionTracker = ActionTrackerForm()
}

private struct ActionTrackerForm: Form {
    var didCatchError = false
    var didCancel = false

    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.Error where action.id == ModularizationTestFlow.id:
            didCatchError = true

        case let action as Actions.DidCancelEffect
            where action.cancellation == AnyHashable(ModularizationTestMiddlewareCancellation.loadItems):
            didCancel = true

        default:
            break
        }
    }
}

private struct AllModularizationTestItems: Storage {
    var byId: [ModularizationTestItem.ID: ModularizationTestItem] = [:]

    mutating func reduce(_ action: some Action) {
        guard let action = action as? Actions.DidLoadItems<ModularizationTestItem> else {
            return
        }

        for item in action.items {
            byId[item.id] = item
        }
    }
}

private enum TestEnvironments: ModularizationTestEnvironmentProviding {
    static let modularizationTestFeature = ModularizationTestEnvironment { page in
        [ModularizationTestItem(id: page * 1_000, title: "Live namespace sentinel")]
    }
}
