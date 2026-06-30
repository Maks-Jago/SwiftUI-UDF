
@testable import UDF
import UDFSwiftTesting
import Testing

@Suite(.serialized) struct DelayedActionTests {
    private struct TestStoreLogger: ActionLogger {
        var actionFilters: [ActionFilter] = [VerboseActionFilter()]
        var actionDescriptor: ActionDescriptor = StringDescribingActionDescriptor()

        func log(_ action: LoggingAction, description: String) {
            print("Reduce\t\t", description)
            print(
                "---------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
            )
        }
    }

    struct AppState: AppReducer {
        var dataForm = DataForm()
    }

    struct DataForm: Form {
        var title: String = ""
        var count: Int = 0
    }

    @Test func whenActionHasDelay_DataShouldBeUpdatedAfterDelay() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        let delayedTitle = "delayed title1"
        let updatedTitle = "updated title"
        store.dispatch(Actions.UpdateFormField(keyPath: \DataForm.title, value: delayedTitle).with(delay: 1))
        store.dispatch(Actions.UpdateFormField(keyPath: \DataForm.title, value: updatedTitle))
        var success = await waitForCondition { store.state.dataForm.title == updatedTitle }
        #expect(success)

        success = await waitForCondition { store.state.dataForm.title == delayedTitle }
        #expect(success)
    }

    @Test func whenActionsHaveDelayInGroup_DataShouldBeUpdatedAfterDelay() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        let delayedTitle = "delayed title2"
        let count = 1
        store.dispatch(
            ActionGroup {
                Actions.UpdateFormField(keyPath: \DataForm.title, value: delayedTitle)
                    .with(delay: 1)

                Actions.UpdateFormField(keyPath: \DataForm.count, value: count)
                    .with(delay: 2)
            }
        )

        #expect(store.state.dataForm.title.isEmpty)

        var success = await waitForCondition { store.state.dataForm.title == delayedTitle }
        #expect(success)
        #expect(store.state.dataForm.count == 0)

        success = await waitForCondition { store.state.dataForm.count == count }
        #expect(success)
    }

    @Test func whenActionGroupHasDelay_DataShouldBeUpdatedAfterDelay() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        let delayedTitle = "delayed title3"
        let count = 1
        store.dispatch(
            ActionGroup {
                Actions.UpdateFormField(keyPath: \DataForm.title, value: delayedTitle)
                Actions.UpdateFormField(keyPath: \DataForm.count, value: count)
            }
            .with(delay: 1)
        )

        #expect(store.state.dataForm.title.isEmpty)

        var success = await waitForCondition { store.state.dataForm.title == delayedTitle }
        #expect(success)

        success = await waitForCondition { store.state.dataForm.count == count }
        #expect(success)
    }

    @Test func whenSomeActionInGroupHasDelay_OnlyThatActionIsDelayed() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        let delayedTitle = "delayed title4"
        let count = 1
        store.dispatch(
            ActionGroup {
                Actions.UpdateFormField(keyPath: \DataForm.title, value: delayedTitle)
                    .with(delay: 1)

                Actions.UpdateFormField(keyPath: \DataForm.count, value: count)
            }
        )

        #expect(store.state.dataForm.count == 0)
        #expect(store.state.dataForm.title.isEmpty)

        var success = await waitForCondition { store.state.dataForm.count == count }
        #expect(success)
        #expect(store.state.dataForm.title.isEmpty)

        success = await waitForCondition { store.state.dataForm.title == delayedTitle }
        #expect(success)
    }

    @Test func delayedActionsDDOS() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        store.dispatch(Actions.UpdateFormField(keyPath: \DataForm.count, value: 1).with(delay: 1))
        store.dispatch(Actions.UpdateFormField(keyPath: \DataForm.count, value: 2).with(delay: 2))
        store.dispatch(Actions.UpdateFormField(keyPath: \DataForm.count, value: 3).with(delay: 3))
        store.dispatch(Actions.UpdateFormField(keyPath: \DataForm.count, value: 4).with(delay: 4))
        store.dispatch(Actions.UpdateFormField(keyPath: \DataForm.count, value: 5).with(delay: 5))

        #expect(store.state.dataForm.count == 0)

        var success = await waitForCondition { store.state.dataForm.count == 1 }
        #expect(success)

        success = await waitForCondition { store.state.dataForm.count == 2 }
        #expect(success)

        success = await waitForCondition { store.state.dataForm.count == 3 }
        #expect(success)

        success = await waitForCondition { store.state.dataForm.count == 4 }
        #expect(success)

        success = await waitForCondition { store.state.dataForm.count == 5 }
        #expect(success)
    }

    @Test func whenActionGroupHasDelayAndChildHasAnimation_BothShouldBePreserved() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        let delayedTitle = "delayed animated title"
        store.dispatch(
            ActionGroup {
                Actions.UpdateFormField(keyPath: \DataForm.title, value: delayedTitle)
                    .with(animation: .bouncy)
            }
            .with(delay: 1)
        )

        // Title should NOT be updated immediately (delay must be respected)
        #expect(store.state.dataForm.title.isEmpty)

        // Title should be updated after the delay
        let success = await waitForCondition { store.state.dataForm.title == delayedTitle }
        #expect(success)
    }
}
