
import XCTest
import SwiftUI
@testable import UDF

final class ContainerHookTests: XCTestCase {
    private struct TestStoreLogger: ActionLogger {
        var actionFilters: [ActionFilter] = [VerboseActionFilter()]
        var actionDescriptor: ActionDescriptor = StringDescribingActionDescriptor()

        func log(_ action: LoggingAction, description: String) {
            print("Reduce\t\t", description)
            print("---------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
        }
    }

    struct AppState: AppReducer {
        var hookForm = HookForm()
    }

    struct HookForm: UDF.Form {
        var triggerValue: String = ""
        var callbacksCount: Int = 0
    }

    func test_OneTimeHook() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = RootContainer()

        let window = await UIWindow.render(container: rootContainer)

        XCTAssertEqual(store.state.hookForm.triggerValue, "")
        print(window) //To force a window redraw

        await fulfill(description: "waiting for rendering", sleep: 1)
        store.$state.hookForm.triggerValue.wrappedValue = "1"

        await fulfill(description: "waiting for dispatch", sleep: 1)
        XCTAssertEqual(store.state.hookForm.triggerValue, "2")
    }
    
    func test_OneTimeHook_NotCalledAgainOnRedraw() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = RootContainer()
        
        let window = await UIWindow.render(container: rootContainer)
        
        XCTAssertEqual(store.state.hookForm.triggerValue, "")
        print(window) // To force a window redraw
        
        await fulfill(description: "waiting for rendering", sleep: 1)
        
        // Set triggerValue to "1" to activate the one-time hook
        store.$state.hookForm.triggerValue.wrappedValue = "1"
        
        await fulfill(description: "waiting for hook execution", sleep: 1)
        XCTAssertEqual(store.state.hookForm.triggerValue, "2")
        
        // Change the state to cause a redraw
        store.$state.hookForm.triggerValue.wrappedValue = "3"
        await fulfill(description: "waiting for redraw", sleep: 1)
        
        XCTAssertEqual(store.state.hookForm.triggerValue, "3")
        
        // Set triggerValue back to "1" to test if the one-time hook fires again
        store.$state.hookForm.triggerValue.wrappedValue = "1"
        await fulfill(description: "waiting for hook execution", sleep: 1)
        
        // The triggerValue should remain "1" because the one-time hook should not fire again
        XCTAssertEqual(store.state.hookForm.triggerValue, "1")
    }
    
    func test_DefaultHook_CalledCorrectNumberOfTimes() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = RootContainer()
        
        let window = await UIWindow.render(container: rootContainer)
        
        XCTAssertEqual(store.state.hookForm.triggerValue, "")
        print(window) // To force a window redraw
        
        await fulfill(description: "waiting for rendering", sleep: 1)
        
        // Reset the hook call counter
        store.$state.hookForm.callbacksCount.wrappedValue = 0
        
        // Define how many times to trigger the condition
        let triggerCount = 5
        
        for _ in 1...triggerCount {
            // Set triggerValue to "3" to meet the hook's condition
            store.$state.hookForm.triggerValue.wrappedValue = "3"
            
            await fulfill(description: "waiting for hook execution", sleep: 1)
            
            // Reset triggerValue to allow the condition to be met again
            store.$state.hookForm.triggerValue.wrappedValue = ""
            await fulfill(description: "waiting for reset", sleep: 1)
        }
        
        // Assert that the hook was called the expected number of times
        XCTAssertEqual(store.state.hookForm.callbacksCount, triggerCount)
    }
    
    func test_HooksPersistAcrossContainers() async throws {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        
        // Create and use the first container
        let rootContainer = RootContainer()
        let window = await UIWindow.render(container: rootContainer)
        
        XCTAssertEqual(store.state.hookForm.triggerValue, "")
        print(window) // To force a window redraw
        
        await fulfill(description: "waiting for rendering", sleep: 1)
        
        // Activate the one-time hook
        store.$state.hookForm.triggerValue.wrappedValue = "1"
        
        await fulfill(description: "waiting for hook execution", sleep: 1)
        XCTAssertEqual(store.state.hookForm.triggerValue, "2")
        
        // Reset triggerValue for further testing
        store.$state.hookForm.triggerValue.wrappedValue = ""
        await fulfill(description: "waiting for rendering", sleep: 1)
        XCTAssertEqual(store.state.hookForm.triggerValue, "")
        
        // Attempt to trigger the one-time hook again
        store.$state.hookForm.triggerValue.wrappedValue = "1"
        await fulfill(description: "waiting for hook execution", sleep: 1)
        
        // The one-time hook should not fire again, so triggerValue should remain "1"
        XCTAssertEqual(store.state.hookForm.triggerValue, "1", "One-time hook should not fire again")
        
        // Create and use the second container
        do {
            let newRootContainer = RootContainer()
            let window = await UIWindow.render(container: newRootContainer)
            
            XCTAssertEqual(store.state.hookForm.triggerValue, "1") // triggerValue from previous step
            print(window) // To force a window redraw
            
            await fulfill(description: "waiting for rendering", sleep: 1)
            
            // Since hooks are persistent, the one-time hook will not fire again
            // So triggerValue should remain "1"
            await fulfill(description: "waiting for hook execution", sleep: 1)
            XCTAssertEqual(store.state.hookForm.triggerValue, "1", "One-time hook should not fire again in new container")
        }
    }
}

//MARK: - RootContainer
extension ContainerHookTests {
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
        struct Props {
        }

        var props: Props

        var body: some View {
            Text("RootComponent")
        }
    }
}
