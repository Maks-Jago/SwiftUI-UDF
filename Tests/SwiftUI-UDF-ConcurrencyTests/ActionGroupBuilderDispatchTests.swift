//
//  ActionGroupBuilderDispatchTests.swift
//  SwiftUI-UDF
//
//  Created by Oleksandr Bodnar on 20.05.2026.
//

@testable import UDF
import Testing
import UDFSwiftTesting

@Suite struct ActionGroupBuilderDispatchTests {
    // MARK: - EnvironmentStore
    @Test func dispatchActionGroupBuilder_EnvironmentStore() async {
        let store = EnvironmentStore(initial: AppState(), loggers: [])

        store.dispatch {
            Actions.UpdateFormField(keyPath: \PlainForm.title, value: "env title")
            Actions.UpdateFormField(keyPath: \PlainForm.subtitle, value: "env subtitle")
        }

        await waitForCondition {
            store.state.plainForm.title == "env title" &&
            store.state.plainForm.subtitle == "env subtitle"
        }

        #expect(store.state.plainForm.title == "env title")
        #expect(store.state.plainForm.subtitle == "env subtitle")
    }

    // MARK: - TestStore
    @Test func dispatchActionGroupBuilder_TestStore() async {
        let store = await TestStore(initial: AppState())

        await store.dispatch(ActionGroup {
            Actions.UpdateFormField(keyPath: \PlainForm.title, value: "test title")
            Actions.UpdateFormField(keyPath: \PlainForm.subtitle, value: "test subtitle")
        })

        let title = await store.state.plainForm.title
        let subtitle = await store.state.plainForm.subtitle
        #expect(title == "test title")
        #expect(subtitle == "test subtitle")
    }

    // MARK: - Store from Middleware
    @Test func dispatchActionGroupBuilder_StoreFromMiddleware() async {
        let store = await TestStore(initial: AppState())
        await store.subscribe { store in ActionGroupBuilderMiddleware(store: store) }

        await store.dispatch(TriggerAction())
        await store.wait()

        let title = await store.state.plainForm.title
        let subtitle = await store.state.plainForm.subtitle
        #expect(title == "middleware title")
        #expect(subtitle == "middleware subtitle")
    }
}

private extension ActionGroupBuilderDispatchTests {
    struct AppState: AppReducer {
        var plainForm = PlainForm()
    }

    struct PlainForm: Form {
        var title: String = ""
        var subtitle: String = ""
    }

    struct TriggerAction: Action {}

    final class ActionGroupBuilderMiddleware: Middleware<AppState>, @unchecked Sendable {
        struct Environment {}
        var environment: Environment!

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment { .init() }
        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment { .init() }

        func reduce(_ action: some Action, for state: AppState) {
            guard action is TriggerAction else { return }
            store.dispatch {
                Actions.UpdateFormField(keyPath: \PlainForm.title, value: "middleware title")
                Actions.UpdateFormField(keyPath: \PlainForm.subtitle, value: "middleware subtitle")
            }
        }
    }
}
