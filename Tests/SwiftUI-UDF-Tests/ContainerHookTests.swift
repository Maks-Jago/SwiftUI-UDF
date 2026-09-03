
import SwiftUI
@testable import UDF
import Testing
import UDFSwiftTesting

@MainActor
@Suite(.serialized)
struct ContainerHookTests {
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
        var hookForm = HookForm()
    }

    struct HookForm: UDF.Form {
        var triggerValue: String = ""
        var callbacksCount: Int = 0
    }

    @Test func oneTimeHook() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = RootContainer()
        let window = await PlatformWindow.render(view: rootContainer)

        #expect(store.state.hookForm.triggerValue == "")
        window.redraw()

        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "1"))

        let success = await waitForMainActorCondition { store.state.hookForm.triggerValue == "2" }
        #expect(success)
    }

    @Test func oneTimeHook_NotCalledAgainOnRedraw() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = RootContainer()
        let window = await PlatformWindow.render(view: rootContainer)

        #expect(store.state.hookForm.triggerValue == "")
        window.redraw()

        // Set triggerValue to "1" to activate the one-time hook
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "1"))

        let success = await waitForMainActorCondition { store.state.hookForm.triggerValue == "2" }
        #expect(success)

        // Change the state to cause a redraw
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "3"))
        await sleep()

        #expect(store.state.hookForm.triggerValue == "3")

        // Set triggerValue back to "1" to test if the one-time hook fires again
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "1"))
        await sleep()

        // The triggerValue should remain "1" because the one-time hook should not fire again
        #expect(store.state.hookForm.triggerValue == "1")
    }

    @Test func defaultHook_CalledCorrectNumberOfTimes() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = RootContainer()
        let window = await PlatformWindow.render(view: rootContainer)

        #expect(store.state.hookForm.triggerValue == "")
        window.redraw()

        // Reset the hook call counter
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.callbacksCount, value: 0))

        // Define how many times to trigger the condition
        let triggerCount = 5

        for _ in 1 ... triggerCount {
            // Set triggerValue to "3" to meet the hook's condition
            store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "3"))
            await waitForMainActorCondition { store.$state.hookForm.triggerValue.wrappedValue == "3" }

            // Reset triggerValue to allow the condition to be met again
            store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: ""))
            await waitForMainActorCondition { store.$state.hookForm.triggerValue.wrappedValue == "" }
        }

        // Assert that the hook was called the expected number of times
        #expect(store.state.hookForm.callbacksCount == triggerCount)
    }

    @Test func oneTimeHooksRecreatedWithNewContainers() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        // Create and use the first container
        let rootContainer = RootContainer()
        var window = await PlatformWindow.render(view: rootContainer)

        #expect(store.state.hookForm.triggerValue == "")
        window.redraw()

        // Activate the one-time hook
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "1"))

        var success = await waitForMainActorCondition { store.state.hookForm.triggerValue == "2" }
        #expect(success)

        // Reset triggerValue for further testing
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: ""))
        success = await waitForMainActorCondition { store.state.hookForm.triggerValue == "" }
        #expect(success)

        // Attempt to trigger the one-time hook again
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "1"))
        success = await waitForMainActorCondition { store.state.hookForm.triggerValue == "1" }
        #expect(success)

        // The one-time hook should not fire again, so triggerValue should remain "1"
        await sleep()
        #expect(store.state.hookForm.triggerValue == "1", "One-time hook should not fire again")

        let newRootContainer = RootContainer()
        window = await PlatformWindow.render(view: newRootContainer)

        #expect(store.state.hookForm.triggerValue == "1") // triggerValue from previous step
        window.redraw()

        // One-time hooks are recreated with each new container instance
        // So the hook will fire again when the condition is met in the new container
        success = await waitForMainActorCondition { store.state.hookForm.triggerValue == "2" }
        #expect(success)
    }

    @Test func hookFiresWhenConditionAlreadyTrueOnContainerAppear() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        // Set the trigger value BEFORE creating the container
        // This simulates the scenario where the condition is already true
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "1"))
        var success = await waitForMainActorCondition { store.state.hookForm.triggerValue == "1" }
        #expect(success)

        // Now create the container - the hook condition is already satisfied
        let rootContainer = RootContainer()
        let window = await PlatformWindow.render(view: rootContainer)

        window.redraw()

        // The hook should have fired even though the condition was already true
        // when the container appeared, changing "1" to "2"
        success = await waitForMainActorCondition { store.state.hookForm.triggerValue == "2" }
        #expect(success, "Hook should fire at least once even if condition was already true when container appeared")
    }

    @Test func removeHook() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = RemovableHookContainer()

        let window = await PlatformWindow.render(view: rootContainer)
        window.redraw()

        // Trigger the hook that removes itself
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "remove"))
        let success = await waitForMainActorCondition { store.state.hookForm.callbacksCount == 1 }
        #expect(success)

        // Try to trigger again - hook should be removed and not fire
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: ""))
        await sleep()

        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "remove"))
        await sleep()

        #expect(store.state.hookForm.callbacksCount == 1, "Hook should not fire after being removed")
    }

    @Test func hookWithAlwaysFalseCondition() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = AlwaysFalseHookContainer()

        let window = await PlatformWindow.render(view: rootContainer)
        window.redraw()

        // Change state multiple times
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "1"))
        await sleep()

        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "2"))
        await sleep()

        // Hook should never fire, so callbacksCount should remain 0
        #expect(store.state.hookForm.callbacksCount == 0)
    }

    @Test func multipleHooksWithDifferentConditions() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = MultipleHooksContainer()

        let window = await PlatformWindow.render(view: rootContainer)
        window.redraw()

        // Reset counters
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.callbacksCount, value: 0))

        // Trigger first hook condition
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "first"))
        var success = await waitForMainActorCondition { store.state.hookForm.callbacksCount == 1 }
        #expect(success)

        // Reset and trigger second hook condition
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: ""))
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.callbacksCount, value: 0))
        await sleep()

        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "second"))
        success = await waitForMainActorCondition { store.state.hookForm.callbacksCount == 10 }
        #expect(success) // Second hook adds 10
    }

    @Test func hookWithComplexCondition() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = ComplexConditionHookContainer()

        let window = await PlatformWindow.render(view: rootContainer)
        window.redraw()

        // Reset counters
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.callbacksCount, value: 0))

        // Test condition that checks both triggerValue and callbacksCount
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "complex"))
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.callbacksCount, value: 5))

        // Hook should have fired and incremented callbacksCount
        let success = await waitForMainActorCondition { store.state.hookForm.callbacksCount == 6 }
        #expect(success)
    }

    @Test func hookFiresOnlyOnConditionTransition() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = TransitionTestContainer()

        let window = await PlatformWindow.render(view: rootContainer)
        window.redraw()

        // Start with condition false, then true
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "false"))
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.callbacksCount, value: 0))

        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "true"))
        var success = await waitForMainActorCondition { store.state.hookForm.callbacksCount == 1 }
        #expect(success)

        // Keep condition true - hook should not fire again
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "true"))
        await sleep()

        #expect(store.state.hookForm.callbacksCount == 1, "Hook should not fire when condition remains true")

        // Change to false, then true again - hook should fire
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "false"))
        success = await waitForMainActorCondition { store.state.hookForm.triggerValue == "false" }
        #expect(success)

        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "true"))
        success = await waitForMainActorCondition { store.state.hookForm.triggerValue == "true" }
        #expect(success)

        success = await waitForMainActorCondition { store.state.hookForm.callbacksCount == 2 }
        #expect(success, "Hook should fire on false->true transition")
    }

    @Test
    func hookWithNilConditionCheck() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = NilSafeHookContainer()

        let window = await PlatformWindow.render(view: rootContainer)
        window.redraw()

        // This tests hooks that might deal with optional values safely
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: ""))
        var success = await waitForMainActorCondition { store.state.hookForm.triggerValue.isEmpty }
        #expect(success)

        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "valid"))
        success = await waitForMainActorCondition { store.state.hookForm.triggerValue == "valid" }
        #expect(success)

        success = await waitForMainActorCondition { store.state.hookForm.callbacksCount == 1 }
        #expect(success)
    }

    @Test func hookWithStateRollback() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = RollbackHookContainer()

        let window = await PlatformWindow.render(view: rootContainer)
        window.redraw()

        // Set up initial state
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "initial"))
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.callbacksCount, value: 5))

        // Trigger rollback condition
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "rollback"))

        // Hook should have reset the counter
        let success = await waitForMainActorCondition {
            store.state.hookForm.callbacksCount == 0 &&
            store.state.hookForm.triggerValue == "reset"
        }
        #expect(success)
    }

    @Test func conditionalHookActivation() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = ConditionalHookContainer()

        let window = await PlatformWindow.render(view: rootContainer)
        window.redraw()

        // Reset counters
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.callbacksCount, value: 0))

        // Only trigger when callbacksCount is even
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.callbacksCount, value: 2))
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "trigger"))
        var success = await waitForMainActorCondition { store.state.hookForm.callbacksCount == 3 } // 2 + 1
        #expect(success)

        // Reset triggerValue and try with odd number
        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: ""))
        success = await waitForMainActorCondition { store.state.hookForm.triggerValue.isEmpty }
        #expect(success)

        store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "trigger"))
        await sleep()

        #expect(store.state.hookForm.callbacksCount == 3, "Hook should not fire when callbacksCount is odd")
    }
}

// MARK: - Containers
extension ContainerHookTests {
    struct RemovableHookContainer: Container {
        typealias ContainerComponent = RootComponent

        func scope(for state: AppState) -> Scope {
            state.hookForm
        }

        func map(store: EnvironmentStore<AppState>) -> RootComponent.Props {
            .init()
        }

        func useHooks() -> [Hook<AppState>] {
            Hook.oneTimeHook(id: "RemovableHook") { state in
                state.hookForm.triggerValue == "remove"
            } block: { store in
                store.$state.hookForm.callbacksCount.wrappedValue += 1
            }
        }
    }

    struct AlwaysFalseHookContainer: Container {
        typealias ContainerComponent = RootComponent

        func scope(for state: AppState) -> Scope {
            state.hookForm
        }

        func map(store: EnvironmentStore<AppState>) -> RootComponent.Props {
            .init()
        }

        func useHooks() -> [Hook<AppState>] {
            Hook.hook(id: "AlwaysFalseHook") { _ in
                false
            } block: { store in
                store.$state.hookForm.callbacksCount.wrappedValue += 1
            }
        }
    }

    struct MultipleHooksContainer: Container {
        typealias ContainerComponent = RootComponent

        func scope(for state: AppState) -> Scope {
            state.hookForm
        }

        func map(store: EnvironmentStore<AppState>) -> RootComponent.Props {
            .init()
        }

        func useHooks() -> [Hook<AppState>] {
            Hook.hook(id: "FirstHook") { state in
                state.hookForm.triggerValue == "first"
            } block: { store in
                store.$state.hookForm.callbacksCount.wrappedValue += 1
            }

            Hook.hook(id: "SecondHook") { state in
                state.hookForm.triggerValue == "second"
            } block: { store in
                store.$state.hookForm.callbacksCount.wrappedValue += 10
            }
        }
    }

    struct ComplexConditionHookContainer: Container {
        typealias ContainerComponent = RootComponent

        func scope(for state: AppState) -> Scope {
            state.hookForm
        }

        func map(store: EnvironmentStore<AppState>) -> RootComponent.Props {
            .init()
        }

        func useHooks() -> [Hook<AppState>] {
            Hook.hook(id: "ComplexConditionHook") { state in
                state.hookForm.triggerValue == "complex" && state.hookForm.callbacksCount == 5
            } block: { store in
                store.$state.hookForm.callbacksCount.wrappedValue += 1
            }
        }
    }

    struct TransitionTestContainer: Container {
        typealias ContainerComponent = RootComponent

        func scope(for state: AppState) -> Scope {
            state.hookForm
        }

        func map(store: EnvironmentStore<AppState>) -> RootComponent.Props {
            .init()
        }

        func useHooks() -> [Hook<AppState>] {
            Hook.hook(id: "TransitionHook") { state in
                state.hookForm.triggerValue == "true"
            } block: { store in
                store.$state.hookForm.callbacksCount.wrappedValue += 1
            }
        }
    }

    struct NilSafeHookContainer: Container {
        typealias ContainerComponent = RootComponent

        func scope(for state: AppState) -> Scope {
            state.hookForm
        }

        func map(store: EnvironmentStore<AppState>) -> RootComponent.Props {
            .init()
        }

        func useHooks() -> [Hook<AppState>] {
            Hook.hook(id: "NilSafeHook") { state in
                !state.hookForm.triggerValue.isEmpty && state.hookForm.triggerValue == "valid"
            } block: { store in
                store.$state.hookForm.callbacksCount.wrappedValue += 1
            }
        }
    }

    struct RollbackHookContainer: Container {
        typealias ContainerComponent = RootComponent

        func scope(for state: AppState) -> Scope {
            state.hookForm
        }

        func map(store: EnvironmentStore<AppState>) -> RootComponent.Props {
            .init()
        }

        func useHooks() -> [Hook<AppState>] {
            Hook.hook(id: "RollbackHook") { state in
                state.hookForm.triggerValue == "rollback"
            } block: { store in
                store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.callbacksCount, value: 0))
                store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "reset"))
            }
        }
    }

    struct ConditionalHookContainer: Container {
        typealias ContainerComponent = RootComponent

        func scope(for state: AppState) -> Scope {
            state.hookForm
        }

        func map(store: EnvironmentStore<AppState>) -> RootComponent.Props {
            .init()
        }

        func useHooks() -> [Hook<AppState>] {
            Hook.hook(id: "ConditionalHook") { state in
                state.hookForm.triggerValue == "trigger" && state.hookForm.callbacksCount % 2 == 0
            } block: { store in
                store.$state.hookForm.callbacksCount.wrappedValue += 1
            }
        }
    }

    struct RootContainer: Container {
        typealias ContainerComponent = RootComponent

        func scope(for state: AppState) -> Scope {
            state.hookForm
        }

        func map(store: EnvironmentStore<AppState>) -> RootComponent.Props {
            .init()
        }

        func useHooks() -> [Hook<ContainerHookTests.AppState>] {
            Hook.oneTimeHook(id: "OneTimeHook") { state in
                state.hookForm.triggerValue == "1"
            } block: { store in
                store.dispatch(Actions.UpdateFormField<HookForm>(keyPath: \HookForm.triggerValue, value: "2"))
            }

            Hook.hook(id: "DefaultHook") { state in
                state.hookForm.triggerValue == "3"
            } block: { store in
                store.$state.hookForm.callbacksCount.wrappedValue += 1
            }
        }
    }

    struct RootComponent: Component {
        struct Props {}

        var props: Props

        var body: some View {
            Text("RootComponent")
        }
    }
}
