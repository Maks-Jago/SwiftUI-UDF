//
//  DispatchActionsTests.swift
//  SwiftUI-UDF-ConcurrencyTests
//
//  Created by Max Kuznetsov on 20.10.2022.
//

@testable import UDF
import XCTest

final class DispatchActionsTests: XCTestCase {
    struct AppState: AppReducer {
        var plainForm = PlainForm()
    }

    struct PlainForm: Form {
        var title: String = ""
    }

    func test_UpdateFormFieldDispatch() async {
        let store = InternalStore(initial: AppState(), loggers: [])
        var formTitle = await store.state.plainForm.title
        XCTAssertEqual(formTitle, "")

        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "new form title"))
        await fulfill(description: "Waiting for middlewares subscription", sleep: 0.5)

        formTitle = await store.state.plainForm.title
        XCTAssertEqual(formTitle, "new form title")
    }

    func test_silentActionDispatch() async throws {
        let messageAction = Actions.Message(message: "Message 1", id: "1")
        let messageInternalAction = messageAction.silent()

        let messageInternalGroup: ActionGroup = try XCTUnwrap(messageInternalAction as? ActionGroup)
        let messageInternalUnwrappedAction: InternalAction = try XCTUnwrap(messageInternalGroup._actions.first)

        XCTAssertTrue(messageInternalUnwrappedAction.silent)

        let testStore = await XCTestStore(initial: AppState())
        await testStore.dispatch(Actions.Message(id: "1"))
        await testStore.dispatch(Actions.Message(id: "2").silent())
        await testStore.dispatch(Actions.Message(id: "3"))
    }

    func test_silentAnimatedActionDispatch() throws {
        let animatedMessageAction1 = Actions.Message(message: "Message 1", id: "1")
            .with(animation: .linear)
            .silent()

        let animatedMessageAction1Group: ActionGroup = try XCTUnwrap(animatedMessageAction1 as? ActionGroup)
        let animatedMessageAction1UnwrappedAction: InternalAction = try XCTUnwrap(animatedMessageAction1Group._actions.first)

        XCTAssertTrue(animatedMessageAction1UnwrappedAction.silent)

        let animatedMessageAction2 = Actions.Message(message: "Message 2", id: "2")
            .silent()
            .with(animation: .linear)

        let animatedMessageAction2Group: ActionGroup = try XCTUnwrap(animatedMessageAction2 as? ActionGroup)
        let animatedMessageAction2UnwrappedAction: InternalAction = try XCTUnwrap(animatedMessageAction2Group._actions.first)

        XCTAssertTrue(animatedMessageAction2UnwrappedAction.silent)
    }
}
