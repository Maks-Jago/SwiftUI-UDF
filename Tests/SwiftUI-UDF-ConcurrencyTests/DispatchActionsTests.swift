//
//  DispatchActionsTests.swift
//  SwiftUI-UDF-ConcurrencyTests
//
//  Created by Max Kuznetsov on 20.10.2022.
//

@testable import UDF
import Testing

@Suite struct DispatchActionsTests {
    struct AppState: AppReducer {
        var plainForm = PlainForm()
    }

    struct PlainForm: Form {
        var title: String = ""
    }

    #test("UpdateFormFieldDispatch")
    func updateFormFieldDispatch() async throws {
        let store = InternalStore(initial: AppState(), loggers: [])
        var formTitle = await store.state.plainForm.title
        #expect(formTitle == "")

        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "new form title"))
        await fulfill(description: "Waiting for middlewares subscription", sleep: 0.5)

        formTitle = await store.state.plainForm.title
        #expect(formTitle == "new form title")
    }

    #test("silentActionDispatch")
    func silentActionDispatch() async throws {
        let messageAction = Actions.Message(message: "Message 1", id: "1")
        let messageInternalAction = messageAction.silent()

        let messageInternalGroup: ActionGroup = try await unwrapAsync(messageInternalAction as? ActionGroup)
        let messageInternalUnwrappedAction: InternalAction = try await unwrapAsync(messageInternalGroup._actions.first)

        #expect(messageInternalUnwrappedAction.silent)

        let testStore = await XCTestStore(initial: AppState())
        await testStore.dispatch(Actions.Message(id: "1"))
        await testStore.dispatch(Actions.Message(id: "2").silent())
        await testStore.dispatch(Actions.Message(id: "3"))
    }

    #test("silentAnimatedActionDispatch")
    func silentAnimatedActionDispatch() throws {
        let animatedMessageAction1 = Actions.Message(message: "Message 1", id: "1")
            .with(animation: .linear)
            .silent()

        let animatedMessageAction1Group: ActionGroup = try unwrapAsync(animatedMessageAction1 as? ActionGroup)
        let animatedMessageAction1UnwrappedAction: InternalAction = try unwrapAsync(animatedMessageAction1Group._actions.first)

        #expect(animatedMessageAction1UnwrappedAction.silent)

        let animatedMessageAction2 = Actions.Message(message: "Message 2", id: "2")
            .silent()
            .with(animation: .linear)

        let animatedMessageAction2Group: ActionGroup = try unwrapAsync(animatedMessageAction2 as? ActionGroup)
        let animatedMessageAction2UnwrappedAction: InternalAction = try unwrapAsync(animatedMessageAction2Group._actions.first)

        #expect(animatedMessageAction2UnwrappedAction.silent)
    }
}
