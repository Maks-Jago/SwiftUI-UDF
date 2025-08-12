
import SwiftUI
@testable import UDF
import Testing
import UDFSwiftTesting

@Suite(.serialized) struct ContainerHookTests {
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
        let window = await PlatformWindow.render(container: rootContainer)

        #expect(store.state.hookForm.triggerValue == "")
        await window.redraw()

        await fulfill(description: "waiting for rendering", sleep: 0.3)
        store.$state.hookForm.triggerValue.wrappedValue = "1"

        await fulfill(description: "waiting for dispatch", sleep: 0.5)
        #expect(store.state.hookForm.triggerValue == "2")
    }

    @Test func oneTimeHook_NotCalledAgainOnRedraw() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = RootContainer()
        let window = await PlatformWindow.render(container: rootContainer)

        #expect(store.state.hookForm.triggerValue == "")
        await window.redraw()

        await fulfill(description: "waiting for rendering", sleep: 0.3)

        // Set triggerValue to "1" to activate the one-time hook
        store.$state.hookForm.triggerValue.wrappedValue = "1"

        await fulfill(description: "waiting for hook execution", sleep: 0.3)
        #expect(store.state.hookForm.triggerValue == "2")

        // Change the state to cause a redraw
        store.$state.hookForm.triggerValue.wrappedValue = "3"
        await fulfill(description: "waiting for redraw", sleep: 0.3)

        #expect(store.state.hookForm.triggerValue == "3")

        // Set triggerValue back to "1" to test if the one-time hook fires again
        store.$state.hookForm.triggerValue.wrappedValue = "1"
        await fulfill(description: "waiting for hook execution", sleep: 0.3)

        // The triggerValue should remain "1" because the one-time hook should not fire again
        #expect(store.state.hookForm.triggerValue == "1")
    }

    @Test func defaultHook_CalledCorrectNumberOfTimes() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = RootContainer()
        let window = await PlatformWindow.render(container: rootContainer)

        #expect(store.state.hookForm.triggerValue == "")
        await window.redraw()

        await fulfill(description: "waiting for rendering", sleep: 0.3)

        // Reset the hook call counter
        store.$state.hookForm.callbacksCount.wrappedValue = 0

        // Define how many times to trigger the condition
        let triggerCount = 5

        for _ in 1 ... triggerCount {
            // Set triggerValue to "3" to meet the hook's condition
            store.$state.hookForm.triggerValue.wrappedValue = "3"

            await fulfill(description: "waiting for hook execution", sleep: 0.3)

            // Reset triggerValue to allow the condition to be met again
            store.$state.hookForm.triggerValue.wrappedValue = ""
            await fulfill(description: "waiting for reset", sleep: 0.3)
        }

        // Assert that the hook was called the expected number of times
        #expect(store.state.hookForm.callbacksCount == triggerCount)
    }

    @Test func hooksPersistAcrossContainers() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        
        // Create and use the first container
        let rootContainer = RootContainer()
        var window = await PlatformWindow.render(container: rootContainer)

        #expect(store.state.hookForm.triggerValue == "")
        await window.redraw()

        // Activate the one-time hook
        store.$state.hookForm.triggerValue.wrappedValue = "1"

        await waitForCondition {
            store.state.hookForm.triggerValue == "2"
        }
        #expect(store.state.hookForm.triggerValue == "2")

        // Reset triggerValue for further testing
        store.$state.hookForm.triggerValue.wrappedValue = ""
        await waitForCondition {
            store.state.hookForm.triggerValue == ""
        }
        #expect(store.state.hookForm.triggerValue == "")

        // Attempt to trigger the one-time hook again
        store.$state.hookForm.triggerValue.wrappedValue = "1"
        await waitForCondition {
            store.state.hookForm.triggerValue == "1"
        }

        // The one-time hook should not fire again, so triggerValue should remain "1"
        #expect(store.state.hookForm.triggerValue == "1", "One-time hook should not fire again")

        let newRootContainer = RootContainer()
        window = await PlatformWindow.render(container: newRootContainer)

        #expect(store.state.hookForm.triggerValue == "1") // triggerValue from previous step
        await window.redraw()

        // Since hooks are persistent, the one-time hook will not fire again
        // So triggerValue should remain "1"
        #expect(store.state.hookForm.triggerValue == "1", "One-time hook should not fire again in new container")
    }

    @Test func hookFiresWhenConditionAlreadyTrueOnContainerAppear() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        // Set the trigger value BEFORE creating the container
        // This simulates the scenario where the condition is already true
        store.$state.hookForm.triggerValue.wrappedValue = "1"

        await fulfill(description: "waiting for settings initial value", sleep: 0.3)

        #expect(store.state.hookForm.triggerValue == "1")

        // Now create the container - the hook condition is already satisfied
        let rootContainer = RootContainer()
        let window = await PlatformWindow.render(container: rootContainer)

        await window.redraw()
        await fulfill(description: "waiting for hook execution", sleep: 0.3)

        // The hook should have fired even though the condition was already true
        // when the container appeared, changing "1" to "2"
        #expect(
            store.state.hookForm.triggerValue == "2", 
            "Hook should fire at least once even if condition was already true when container appeared"
        )
    }

    @Test func removeHook() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = RemovableHookContainer()

        let window = await PlatformWindow.render(container: rootContainer)
        await window.redraw()

        await fulfill(description: "waiting for rendering", sleep: 0.3)

        // Trigger the hook that removes itself
        store.$state.hookForm.triggerValue.wrappedValue = "remove"
        await fulfill(description: "waiting for hook execution", sleep: 0.3)

        #expect(store.state.hookForm.callbacksCount == 1)

        // Try to trigger again - hook should be removed and not fire
        store.$state.hookForm.triggerValue.wrappedValue = ""
        await fulfill(description: "waiting for reset", sleep: 0.3)

        store.$state.hookForm.triggerValue.wrappedValue = "remove"
        await fulfill(description: "waiting for hook execution", sleep: 0.3)

        #expect(store.state.hookForm.callbacksCount == 1, "Hook should not fire after being removed")
    }

    @Test func hookWithAlwaysFalseCondition() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = AlwaysFalseHookContainer()

        let window = await PlatformWindow.render(container: rootContainer)
        await window.redraw()

        await fulfill(description: "waiting for rendering", sleep: 0.3)

        // Change state multiple times
        store.$state.hookForm.triggerValue.wrappedValue = "1"
        await fulfill(description: "waiting for state change", sleep: 0.3)

        store.$state.hookForm.triggerValue.wrappedValue = "2"
        await fulfill(description: "waiting for state change", sleep: 0.3)

        // Hook should never fire, so callbacksCount should remain 0
        #expect(store.state.hookForm.callbacksCount == 0)
    }

    @Test func multipleHooksWithDifferentConditions() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = MultipleHooksContainer()

        let window = await PlatformWindow.render(container: rootContainer)
        await window.redraw()

        await fulfill(description: "waiting for rendering", sleep: 0.3)

        // Reset counters
        store.$state.hookForm.callbacksCount.wrappedValue = 0

        // Trigger first hook condition
        store.$state.hookForm.triggerValue.wrappedValue = "first"
        await fulfill(description: "waiting for first hook", sleep: 0.3)

        #expect(store.state.hookForm.callbacksCount == 1)

        // Reset and trigger second hook condition
        store.$state.hookForm.triggerValue.wrappedValue = ""
        store.$state.hookForm.callbacksCount.wrappedValue = 0
        await fulfill(description: "waiting for reset", sleep: 0.3)

        store.$state.hookForm.triggerValue.wrappedValue = "second"
        await fulfill(description: "waiting for second hook", sleep: 0.3)

        #expect(store.state.hookForm.callbacksCount == 10) // Second hook adds 10
    }

    @Test func hookWithComplexCondition() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = ComplexConditionHookContainer()

        let window = await PlatformWindow.render(container: rootContainer)
        await window.redraw()

        await fulfill(description: "waiting for rendering", sleep: 0.3)

        // Reset counters
        store.$state.hookForm.callbacksCount.wrappedValue = 0

        // Test condition that checks both triggerValue and callbacksCount
        store.$state.hookForm.triggerValue.wrappedValue = "complex"
        store.$state.hookForm.callbacksCount.wrappedValue = 5
        await fulfill(description: "waiting for hook execution", sleep: 0.3)

        // Hook should have fired and incremented callbacksCount
        #expect(store.state.hookForm.callbacksCount == 6)
    }

    @Test func hookFiresOnlyOnConditionTransition() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = TransitionTestContainer()

        let window = await PlatformWindow.render(container: rootContainer)
        await window.redraw()

        await fulfill(description: "waiting for rendering", sleep: 0.3)

        // Start with condition false, then true
        store.$state.hookForm.triggerValue.wrappedValue = "false"
        store.$state.hookForm.callbacksCount.wrappedValue = 0
        await fulfill(description: "waiting for state change", sleep: 0.3)

        store.$state.hookForm.triggerValue.wrappedValue = "true"
        await fulfill(description: "waiting for hook execution", sleep: 0.3)

        #expect(store.state.hookForm.callbacksCount == 1)

        // Keep condition true - hook should not fire again
        store.$state.hookForm.triggerValue.wrappedValue = "true"
        await fulfill(description: "waiting for state change", sleep: 0.3)

        #expect(store.state.hookForm.callbacksCount == 1, "Hook should not fire when condition remains true")

        // Change to false, then true again - hook should fire
        store.$state.hookForm.triggerValue.wrappedValue = "false"
        await fulfill(description: "waiting for state change", sleep: 0.3)

        store.$state.hookForm.triggerValue.wrappedValue = "true"
        await fulfill(description: "waiting for hook execution", sleep: 0.3)

        #expect(store.state.hookForm.callbacksCount == 2, "Hook should fire on false->true transition")
    }

    @Test func hookWithNilConditionCheck() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = NilSafeHookContainer()

        let window = await PlatformWindow.render(container: rootContainer)
        await window.redraw()

        await fulfill(description: "waiting for rendering", sleep: 0.3)

        // This tests hooks that might deal with optional values safely
        store.$state.hookForm.triggerValue.wrappedValue = ""
        await fulfill(description: "waiting for state change", sleep: 0.3)

        store.$state.hookForm.triggerValue.wrappedValue = "valid"
        await fulfill(description: "waiting for hook execution", sleep: 0.3)

        #expect(store.state.hookForm.callbacksCount == 1)
    }

    @Test func hookWithStateRollback() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = RollbackHookContainer()

        let window = await PlatformWindow.render(container: rootContainer)
        await window.redraw()

        await fulfill(description: "waiting for rendering", sleep: 0.3)

        // Set up initial state
        store.$state.hookForm.triggerValue.wrappedValue = "initial"
        store.$state.hookForm.callbacksCount.wrappedValue = 5
        await fulfill(description: "waiting for initial state", sleep: 0.3)

        // Trigger rollback condition
        store.$state.hookForm.triggerValue.wrappedValue = "rollback"
        await fulfill(description: "waiting for rollback hook", sleep: 0.3)

        // Hook should have reset the counter
        #expect(store.state.hookForm.callbacksCount == 0)
        #expect(store.state.hookForm.triggerValue == "reset")
    }

    @Test func conditionalHookActivation() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = ConditionalHookContainer()

        let window = await PlatformWindow.render(container: rootContainer)
        await window.redraw()

        await fulfill(description: "waiting for rendering", sleep: 0.3)

        // Reset counters
        store.$state.hookForm.callbacksCount.wrappedValue = 0

        // Only trigger when callbacksCount is even
        store.$state.hookForm.callbacksCount.wrappedValue = 2
        store.$state.hookForm.triggerValue.wrappedValue = "trigger"
        await fulfill(description: "waiting for hook execution", sleep: 0.3)

        #expect(store.state.hookForm.callbacksCount == 3) // 2 + 1

        // Reset triggerValue and try with odd number
        store.$state.hookForm.triggerValue.wrappedValue = ""
        await fulfill(description: "waiting for reset", sleep: 0.3)

        store.$state.hookForm.triggerValue.wrappedValue = "trigger"
        await fulfill(description: "waiting for hook execution", sleep: 0.3)

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
                store.$state.hookForm.callbacksCount.wrappedValue = 0
                store.$state.hookForm.triggerValue.wrappedValue = "reset"
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
                store.$state.hookForm.triggerValue.wrappedValue = "2"
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
