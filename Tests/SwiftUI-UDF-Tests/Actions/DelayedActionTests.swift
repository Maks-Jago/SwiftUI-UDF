@testable import UDF
import UDFSwiftTesting
import Testing
import Foundation
import os

@Suite(.serialized, .timeLimit(.minutes(1))) struct DelayedActionTests {
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

    private final class ActionCollectorLogger: ActionLogger, @unchecked Sendable {
        var actionFilters: [ActionFilter] = [VerboseActionFilter()]
        var actionDescriptor: ActionDescriptor = StringDescribingActionDescriptor()

        private let lock = OSAllocatedUnfairLock(initialState: [LoggingAction]())

        var actions: [LoggingAction] {
            lock.withLock { $0 }
        }

        func log(_ action: LoggingAction, description: String) {
            lock.withLock { $0.append(action) }
            print("Reduce\t\t", description)
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
        let sentinelTitle = "sentinel title"
        
        let clock = ContinuousClock()
        let start = clock.now

        store.dispatch(
            ActionGroup {
                Actions.UpdateFormField(keyPath: \DataForm.title, value: delayedTitle)
                    .with(animation: .bouncy)
            }
            .with(delay: 1)
        )

        // Dispatch an immediate action after the delayed action
        store.dispatch(Actions.UpdateFormField(keyPath: \DataForm.title, value: sentinelTitle))

        // Wait for the immediate action to be reduced first (proves the delayed action is delayed)
        let sentinelSuccess = await waitForCondition { store.state.dataForm.title == sentinelTitle }
        #expect(sentinelSuccess)

        // Wait for the delayed action to be reduced
        let success = await waitForCondition { store.state.dataForm.title == delayedTitle }
        #expect(success)

        let elapsed = start.duration(to: clock.now)
        #expect(
            elapsed >= .seconds(1),
            "expected delayed action to be applied after at least 1 second"
        )
    }

    private func getDismissAction(title: String, count: Int) -> any Action {
        ActionGroup {
            Actions.UpdateFormField(keyPath: \DataForm.title, value: title)
            Actions.UpdateFormField(keyPath: \DataForm.count, value: count)
        }
    }

    @Test func whenFunctionReturnsAnyActionWithNestedGroupsAndDelay_DataShouldBeUpdatedAfterDelay() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        let delayedTitle = "delayed group-in-group title"
        let count = 42
        
        let action = getDismissAction(title: delayedTitle, count: count)
        
        let clock = ContinuousClock()
        let start = clock.now

        store.dispatch(
            ActionGroup {
                action
            }
            .with(delay: 1)
        )

        #expect(store.state.dataForm.title.isEmpty)
        #expect(store.state.dataForm.count == 0)

        let successTitle = await waitForCondition { store.state.dataForm.title == delayedTitle }
        #expect(successTitle)

        let successCount = await waitForCondition { store.state.dataForm.count == count }
        #expect(successCount)

        let elapsed = start.duration(to: clock.now)
        #expect(
            elapsed >= .seconds(1),
            "expected delayed action to be applied after at least 1 second"
        )
    }

    @Test func whenDeeplyNestedActionGroupsHaveDelay_DataShouldBeUpdatedAfterDelay() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        let delayedTitle = "deeply delayed title"
        let count = 100
        
        // Level 4 nested groups
        let action = ActionGroup {
            ActionGroup {
                ActionGroup {
                    ActionGroup {
                        Actions.UpdateFormField(keyPath: \DataForm.title, value: delayedTitle)
                        Actions.UpdateFormField(keyPath: \DataForm.count, value: count)
                    }
                }
            }
        }
        
        let clock = ContinuousClock()
        let start = clock.now

        store.dispatch(action.with(delay: 1))

        #expect(store.state.dataForm.title.isEmpty)
        #expect(store.state.dataForm.count == 0)

        let successTitle = await waitForCondition { store.state.dataForm.title == delayedTitle }
        #expect(successTitle)

        let successCount = await waitForCondition { store.state.dataForm.count == count }
        #expect(successCount)

        let elapsed = start.duration(to: clock.now)
        #expect(
            elapsed >= .seconds(1),
            "expected delayed action to be applied after at least 1 second"
        )
    }

    @Test func whenNestedGroupsHaveDifferentModifiersAndOuterHasDelay_AllModifiersShouldBePreserved() async throws {
        let logger = ActionCollectorLogger()
        let store = EnvironmentStore(initial: AppState(), logger: logger)

        let delayedTitle = "delayed title"
        let count = 42
        
        let clock = ContinuousClock()
        let start = clock.now

        store.dispatch(
            ActionGroup {
                // Animated group
                ActionGroup {
                    Actions.UpdateFormField(keyPath: \DataForm.title, value: delayedTitle)
                }
                .with(animation: .bouncy)

                // Silent group
                ActionGroup {
                    Actions.UpdateFormField(keyPath: \DataForm.count, value: count)
                }
                .silent()
            }
            .with(delay: 1)
        )

        // Wait for both updates to be reduced
        let success1 = await waitForCondition { store.state.dataForm.title == delayedTitle }
        #expect(success1)

        let success2 = await waitForCondition { store.state.dataForm.count == count }
        #expect(success2)

        let elapsed = start.duration(to: clock.now)
        #expect(
            elapsed >= .seconds(1),
            "expected delayed action to be applied after at least 1 second"
        )

        // Verify the properties on the leaf actions recorded by the logger
        let animatedAction = logger.actions.first { action in
            if let updateAction = action.value as? Actions.UpdateFormField<DataForm> {
                return updateAction.keyPath == \DataForm.title
            }
            return false
        }
        #expect(animatedAction != nil)
        #expect(animatedAction?.internalAction.animation != nil)

        let silentAction = logger.actions.first { action in
            if let updateAction = action.value as? Actions.UpdateFormField<DataForm> {
                return updateAction.keyPath == \DataForm.count
            }
            return false
        }
        #expect(silentAction != nil)
        #expect(silentAction?.internalAction.silent == true)
    }

    @Test func whenEmptyActionGroupHasDelay_ShouldNotCrash() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        
        store.dispatch(
            ActionGroup {}
                .with(delay: 1)
        )
        
        // Ensure execution continues normally
        #expect(true)
    }
}

