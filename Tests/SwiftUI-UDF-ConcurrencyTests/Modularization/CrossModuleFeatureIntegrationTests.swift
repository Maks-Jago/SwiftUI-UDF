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
import UDFModularizationTestFeature
import UDFSwiftTesting

@Suite("Cross-module feature integration")
struct CrossModuleFeatureIntegrationTests {
    @Test("An externally composed feature completes the full normalized loading path")
    func externallyComposedFeatureCompletesLoadingPath() async throws {
        let page = 2
        let expectedItems = [
            ModularizationTestItem(id: 21, title: "Data-layer item 21"),
            ModularizationTestItem(id: 22, title: "Data-layer item 22"),
        ]
        let environment = ModularizationTestEnvironment { requestedPage in
            expectedItems
        }

        try await ModularizationTestEnvironmentContext.$environment.withValue(environment) {
            let store = EnvironmentStore(initial: AppState(), loggers: [])

            store.dispatch(Actions.LoadPage(pageNumber: page, id: ModularizationTestFlow.id))

            let completedLoadingPath = await waitForCondition {
                let state = store.state
                return state.modularizationTestFeature.flow == .none
                    && state.modularizationTestFeature.form.paginator.elements == expectedItems.map(\.id)
                    && state.modularizationTestFeature.form.paginator.page == .number(page)
                    && state.allModularizationTestItems.byId.count == expectedItems.count
            }
            #expect(completedLoadingPath)

            for expectedItem in expectedItems {
                let storedItem = try #require(
                    store.state.allModularizationTestItems.byId[expectedItem.id]
                )
                #expect(storedItem == expectedItem)
            }
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

        let environment = ModularizationTestEnvironment { _ in
            throw TestError()
        }

        await ModularizationTestEnvironmentContext.$environment.withValue(environment) {
            let store = EnvironmentStore(initial: AppState(), loggers: [])

            store.dispatch(Actions.LoadPage(pageNumber: 1, id: ModularizationTestFlow.id))

            let resetToIdle = await waitForCondition {
                store.state.modularizationTestFeature.flow == .none
                    && store.state.actionTracker.didCatchError
            }
            #expect(resetToIdle)
            #expect(store.state.modularizationTestFeature.form.paginator.elements.isEmpty)
        }
    }

    @Test("An externally composed feature cancels in-flight load and resets flow")
    func externallyComposedFeatureHandlesCancellation() async throws {
        let environment = ModularizationTestEnvironment { _ in
            throw CancellationError()
        }

        await ModularizationTestEnvironmentContext.$environment.withValue(environment) {
            let store = EnvironmentStore(initial: AppState(), loggers: [])

            store.dispatch(Actions.LoadPage(pageNumber: 1, id: ModularizationTestFlow.id))

            let resetToIdle = await waitForCondition {
                store.state.modularizationTestFeature.flow == .none
                    && store.state.actionTracker.didCancel
            }
            #expect(resetToIdle)
            #expect(store.state.modularizationTestFeature.form.paginator.elements.isEmpty)
        }
    }

    @Test("An externally composed feature loads subsequent pages accumulating items")
    func externallyComposedFeatureLoadsSubsequentPages() async throws {
        let page1Items = [
            ModularizationTestItem(id: 1, title: "Item 1"),
            ModularizationTestItem(id: 2, title: "Item 2"),
        ]
        let page2Items = [
            ModularizationTestItem(id: 3, title: "Item 3"),
            ModularizationTestItem(id: 4, title: "Item 4"),
        ]
        let environment = ModularizationTestEnvironment { page in
            page == 1 ? page1Items : page2Items
        }

        try await ModularizationTestEnvironmentContext.$environment.withValue(environment) {
            let store = EnvironmentStore(initial: AppState(), loggers: [])

            // Load Page 1
            store.dispatch(Actions.LoadPage(pageNumber: 1, id: ModularizationTestFlow.id))

            let completedPage1 = await waitForCondition {
                store.state.modularizationTestFeature.flow == .none
                    && store.state.modularizationTestFeature.form.paginator.elements == [1, 2]
                    && store.state.modularizationTestFeature.form.paginator.page == .number(1)
            }
            #expect(completedPage1)

            // Load Page 2
            store.dispatch(Actions.LoadPage(pageNumber: 2, id: ModularizationTestFlow.id))

            let completedPage2 = await waitForCondition {
                store.state.modularizationTestFeature.flow == .none
                    && store.state.modularizationTestFeature.form.paginator.elements == [1, 2, 3, 4]
                    && store.state.modularizationTestFeature.form.paginator.page == .number(2)
                    && store.state.allModularizationTestItems.byId.count == 4
            }
            #expect(completedPage2)

            for item in page1Items + page2Items {
                let storedItem = try #require(store.state.allModularizationTestItems.byId[item.id])
                #expect(storedItem == item)
            }
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
    static var modularizationTestFeature: ModularizationTestEnvironment {
        guard let environment = ModularizationTestEnvironmentContext.environment else {
            fatalError("A test environment must be scoped before creating the store.")
        }
        return environment
    }
}

private enum ModularizationTestEnvironmentContext {
    @TaskLocal static var environment: ModularizationTestEnvironment?
}
