import SwiftUI
@testable import UDF
import Testing
import UDFSwiftTesting

@Suite(.serialized) struct ContainerWithAppStateAsScopeTests {
    @propertyWrapper
    final class Box<Value> {
        private var box: Value

        init(wrappedValue: Value) {
            box = wrappedValue
        }

        var wrappedValue: Value {
            get { box }
            set { box = newValue }
        }
    }

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

    struct ContainerWithAppStateAsScopeAppState: AppReducer {
        var plainForm = PlainForm()
        var userData = UserData()
    }

    struct PlainForm: UDF.Form {
        var title: String = ""
    }

    struct UserData: UDF.Form {
        var isUserLoggedIn: Bool = false
    }

    #if os(iOS)
    @Test 
    @MainActor func rootComponentRendering() async {
        // No need to clear GlobalValue as we're using explicit store injection
        let store = EnvironmentStore(initial: ContainerWithAppStateAsScopeAppState(), logger: TestStoreLogger())
        
        // Use explicit store injection - create container but access underlying container for counting
        let rootContainer = RootContainer()
        let window = await PlatformWindow.render(container: rootContainer.with(store: store))
        
        #expect(rootContainer.renderingNumber == 0)
        await fulfill(description: "waiting for first rendering", sleep: 1)
        #expect(rootContainer.renderingNumber == 1)
        
        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "title 1"))
        await fulfill(description: "waiting for rendering", sleep: 1)
        
        window.redraw()
        await fulfill(description: "waiting for rendering", sleep: 1)
        #expect(rootContainer.renderingNumber == 2)
        
        store.dispatch(Actions.UpdateFormField(keyPath: \UserData.isUserLoggedIn, value: true))
        await fulfill(description: "waiting for rendering", sleep: 1)
        
        window.redraw()
        await fulfill(description: "waiting for rendering", sleep: 1)
        #expect(rootContainer.renderingNumber == 3)
        
        store.dispatch(Actions.UpdateFormField(keyPath: \UserData.isUserLoggedIn, value: false))
        await fulfill(description: "waiting for rendering", sleep: 1)
        
        window.redraw()
        await fulfill(description: "waiting for rendering", sleep: 1)
        #expect(rootContainer.renderingNumber == 4)
        
        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "title 2"))
        await fulfill(description: "waiting for rendering", sleep: 1)
        
        window.redraw()
        await fulfill(description: "waiting for rendering", sleep: 1)
        #expect(rootContainer.renderingNumber == 5)
    }
    
    @Test
    
    @MainActor func noneScope() async {
        // No need to clear GlobalValue as we're using explicit store injection
        let store = EnvironmentStore(initial: ContainerWithAppStateAsScopeAppState(), logger: TestStoreLogger())
        
        let noneScopeContainer = NoneScopeContainer()
        let window = await PlatformWindow.render(container: noneScopeContainer.with(store: store))
        
        #expect(noneScopeContainer.renderingNumber == 0)
        await fulfill(description: "waiting for first rendering", sleep: 1)
        #expect(noneScopeContainer.renderingNumber == 1)
        
        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "title 1"))
        await fulfill(description: "waiting for rendering", sleep: 1)
        
        window.redraw()
        #expect(noneScopeContainer.renderingNumber == 1)
    }
#endif
}

// MARK: - RootContainer
extension ContainerWithAppStateAsScopeTests {
    struct RootContainer: Container {
        func onContainerAppear(store: EnvironmentStore<ContainerWithAppStateAsScopeAppState>) {}
        func onContainerDisappear(store: EnvironmentStore<ContainerWithAppStateAsScopeAppState>) {}
        func onContainerDidLoad(store: EnvironmentStore<ContainerWithAppStateAsScopeAppState>) {}

        typealias ContainerComponent = RootComponent

        @Box var renderingNumber: Int = 0

        func scope(for state: ContainerWithAppStateAsScopeAppState) -> Scope {
            state
        }

        func map(store: EnvironmentStore<ContainerWithAppStateAsScopeAppState>) -> RootComponent.Props {
            renderingNumber += 1
            print("RootContainer: renderingNumber - \(renderingNumber)")

            return .init(
                isUserLoggedIn: store.state.userData.isUserLoggedIn
            )
        }
    }

    struct RootComponent: Component {
        struct Props {
            var isUserLoggedIn: Bool
        }

        var props: Props

        var body: some View {
            print("props.isUserLoggedIn: \(props.isUserLoggedIn)")
            return Group {
                if props.isUserLoggedIn {
                    Text("user logged in")
                } else {
                    Text("placeholder")
                }
            }
        }
    }
}

// MARK: - None scope container
extension ContainerWithAppStateAsScopeTests {
    struct NoneScopeContainer: Container {
        typealias ContainerComponent = RootComponent

        func onContainerAppear(store: EnvironmentStore<ContainerWithAppStateAsScopeAppState>) {}
        func onContainerDisappear(store: EnvironmentStore<ContainerWithAppStateAsScopeAppState>) {}
        func onContainerDidLoad(store: EnvironmentStore<ContainerWithAppStateAsScopeAppState>) {}

        @Box var renderingNumber: Int = 0

        func scope(for state: ContainerWithAppStateAsScopeAppState) -> Scope {
            .none
        }

        func map(store: EnvironmentStore<ContainerWithAppStateAsScopeTests.ContainerWithAppStateAsScopeAppState>) -> ContainerWithAppStateAsScopeTests.RootComponent
            .Props
        {
            renderingNumber += 1
            print("NoneScopeContainer: renderingNumber - \(renderingNumber)")
            return .init(isUserLoggedIn: false)
        }
    }
}
