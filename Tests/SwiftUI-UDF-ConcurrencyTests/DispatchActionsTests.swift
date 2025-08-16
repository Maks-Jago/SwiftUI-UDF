//
//  DispatchActionsTests.swift
//  SwiftUI-UDF-ConcurrencyTests
//
//  Created by Max Kuznetsov on 20.10.2022.
//

@testable import UDF
import Testing
import UDFSwiftTesting

@Suite struct DispatchActionsTests {
    struct AppState: AppReducer {
        var plainForm = PlainForm()
    }

    struct PlainForm: Form {
        var title: String = ""
    }

    @Test func updateFormFieldDispatch() async {
        let store = InternalStore(initial: AppState(), loggers: [])
        let formTitle = await store.state.plainForm.title
        #expect(formTitle == "")

        let newFormTitle = "new form title"
        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: newFormTitle))
        let success = await waitForAsyncCondition { await store.state.plainForm.title == newFormTitle}
        #expect(success)
    }

    @Test func silentActionDispatch() async throws {
        let messageAction = Actions.Message(message: "Message 1", id: "1")
        let messageInternalAction = messageAction.silent()

        let messageInternalGroup: ActionGroup = try #require(messageInternalAction as? ActionGroup)
        let messageInternalUnwrappedAction: InternalAction = try #require(messageInternalGroup._actions.first)

        #expect(messageInternalUnwrappedAction.silent)

        let testStore = EnvironmentStore(initial: AppState(), loggers: [])
        testStore.dispatch(Actions.Message(id: "1"))
        testStore.dispatch(Actions.Message(id: "2").silent())
        testStore.dispatch(Actions.Message(id: "3"))
    }

    @Test func silentAnimatedActionDispatch() throws {
        let animatedMessageAction1 = Actions.Message(message: "Message 1", id: "1")
            .with(animation: .linear)
            .silent()

        let animatedMessageAction1Group: ActionGroup = try #require(animatedMessageAction1 as? ActionGroup)
        let animatedMessageAction1UnwrappedAction: InternalAction = try #require(animatedMessageAction1Group._actions.first)

        #expect(animatedMessageAction1UnwrappedAction.silent)

        let animatedMessageAction2 = Actions.Message(message: "Message 2", id: "2")
            .silent()
            .with(animation: .linear)

        let animatedMessageAction2Group: ActionGroup = try #require(animatedMessageAction2 as? ActionGroup)
        let animatedMessageAction2UnwrappedAction: InternalAction = try #require(animatedMessageAction2Group._actions.first)

        #expect(animatedMessageAction2UnwrappedAction.silent)
    }
}
