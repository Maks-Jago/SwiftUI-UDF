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
            TestItem(id: 3, title: "Test item 3"),
            TestItem(id: 4, title: "Test item 4"),
        ]
        let store = await TestStore(initial: AppState())

        await store.dispatch(Actions.LoadPage(pageNumber: page, id: TestFlow.id))
        await store.wait()

        let state = await store.state
        #expect(state.testFeature.flow == .none)
        #expect(state.testFeature.form.paginator.elements == expectedItems.map(\.id))
        #expect(state.testFeature.form.paginator.page == .number(page))
        #expect(state.allTestItems.byId.count == expectedItems.count)

        for expectedItem in expectedItems {
            let storedItem = try #require(state.allTestItems.byId[expectedItem.id])
            #expect(storedItem == expectedItem)
        }
    }

    @TestStoreActor
    @Test("A stateless feature has empty registration and preserves entry input")
    func statelessFeatureUsesDefaultsAndPreservesInput() async {
        let input = TestSettingsInput(title: "Settings payload")
        let destination = TestSettingsFeatureState<AppState>.entryPoint(
            input: input
        )
        let store = TestStore(initial: AppState())
        var wrappers: [MiddlewareWrapper<AppState>] = []
        await store.subscribe { store in
            wrappers = TestSettingsFeatureState<AppState>.registerMiddlewares(in: store)
            return wrappers
        }

        #expect(destination.input == input)
        #expect(wrappers.isEmpty)
    }

    @Test("An externally composed feature recovers from errors and resets flow")
    func externallyComposedFeatureHandlesErrorAndResetsFlow() async {
        struct TestError: Error, Equatable {}

        let store = await TestStore(
            initial: AppState(),
            registerFeatureMiddlewares: false
        )
        await store.subscribe(
            TestMiddleware<AppState>.self,
            environment: .test { _ in throw TestError() }
        )

        await store.dispatch(Actions.LoadPage(pageNumber: 1, id: TestFlow.id))
        await store.wait()

        let state = await store.state
        #expect(state.testFeature.flow == .none)
        #expect(state.actionTracker.didCatchError)
        #expect(state.testFeature.form.paginator.elements.isEmpty)
    }

    @Test("An externally composed feature cancels in-flight load and resets flow")
    func externallyComposedFeatureHandlesCancellation() async {
        let store = await TestStore(
            initial: AppState(),
            registerFeatureMiddlewares: false
        )
        await store.subscribe(
            TestMiddleware<AppState>.self,
            environment: .test { _ in throw CancellationError() }
        )

        await store.dispatch(Actions.LoadPage(pageNumber: 1, id: TestFlow.id))
        await store.wait()

        let state = await store.state
        #expect(state.testFeature.flow == .none)
        #expect(state.actionTracker.didCancel)
        #expect(state.testFeature.form.paginator.elements.isEmpty)
    }

    @Test("An externally composed feature loads subsequent pages accumulating items")
    func externallyComposedFeatureLoadsSubsequentPages() async throws {
        let page1Items = [
            TestItem(id: 1, title: "Test item 1"),
            TestItem(id: 2, title: "Test item 2"),
        ]
        let page2Items = [
            TestItem(id: 3, title: "Test item 3"),
            TestItem(id: 4, title: "Test item 4"),
        ]
        let store = await TestStore(initial: AppState())

        await store.dispatch(Actions.LoadPage(pageNumber: 1, id: TestFlow.id))
        await store.wait()

        var state = await store.state
        #expect(state.testFeature.flow == .none)
        #expect(state.testFeature.form.paginator.elements == [1, 2])
        #expect(state.testFeature.form.paginator.page == .number(1))

        await store.dispatch(Actions.LoadPage(pageNumber: 2, id: TestFlow.id))
        await store.wait()

        state = await store.state
        #expect(state.testFeature.flow == .none)
        #expect(state.testFeature.form.paginator.elements == [1, 2, 3, 4])
        #expect(state.testFeature.form.paginator.page == .number(2))
        #expect(state.allTestItems.byId.count == 4)

        for item in page1Items + page2Items {
            let storedItem = try #require(state.allTestItems.byId[item.id])
            #expect(storedItem == item)
        }
    }
}

// MARK: - App State & Composition

private struct AppState:
    AppReducer,
    TestFeature,
    TestSettingsFeature
{
    typealias Environments = TestEnvironments

    var allTestItems = AllTestItems()
    var testFeature = TestFeatureState<AppState>()
    var testSettings = TestSettingsFeatureState<AppState>()
    var actionTracker = ActionTrackerForm()
}

private struct ActionTrackerForm: Form {
    var didCatchError = false
    var didCancel = false

    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.Error where action.id == TestFlow.id:
            didCatchError = true

        case let action as Actions.DidCancelEffect
            where action.cancellation == AnyHashable(TestMiddlewareCancellation.loadItems):
            didCancel = true

        default:
            break
        }
    }
}

private struct AllTestItems: Storage {
    var byId: [TestItem.ID: TestItem] = [:]

    mutating func reduce(_ action: some Action) {
        guard let action = action as? Actions.DidLoadItems<TestItem> else {
            return
        }

        for item in action.items {
            byId[item.id] = item
        }
    }
}

private enum TestEnvironments: TestEnvironmentProviding {
    static let testFeature = TestEnvironment { page in
        [TestItem(id: page * 1000, title: "Live namespace sentinel")]
    }
}
