import SwiftUI
@testable import UDF
import Testing
import UDFSwiftTesting

@Suite struct ContainerWithAppStateAsScopeTests {
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

    struct AppState: AppReducer {
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
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        let rootContainer = RootContainer()
        let window = await PlatformWindow.render(view: rootContainer.with(store: store))

        #expect(rootContainer.renderingNumber == 0)
        var success = await waitForMainActorCondition { rootContainer.renderingNumber == 1 }
        #expect(success)

        let title1 = "title 1"
        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: title1))
        await waitForMainActorCondition { store.state.plainForm.title == title1 }

        window.redraw()
        success = await waitForMainActorCondition { rootContainer.renderingNumber == 2 }
        #expect(success)

        store.dispatch(Actions.UpdateFormField(keyPath: \UserData.isUserLoggedIn, value: true))
        await waitForMainActorCondition { store.state.userData.isUserLoggedIn }

        window.redraw()
        success = await waitForMainActorCondition { rootContainer.renderingNumber == 3 }
        #expect(success)

        store.dispatch(Actions.UpdateFormField(keyPath: \UserData.isUserLoggedIn, value: false))
        await waitForMainActorCondition { !store.state.userData.isUserLoggedIn }

        window.redraw()
        success = await waitForMainActorCondition { rootContainer.renderingNumber == 4 }
        #expect(success)

        let title2 = "title 2"
        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: title2))
        await waitForMainActorCondition { store.state.plainForm.title == title2 }

        window.redraw()
        success = await waitForMainActorCondition { rootContainer.renderingNumber == 5 }
        #expect(success)
    }

    @Test
    @MainActor func noneScope() async {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        let noneScopeContainer = NoneScopeContainer()
        let window = await PlatformWindow.render(view: noneScopeContainer.with(store: store))

        #expect(noneScopeContainer.renderingNumber == 0)
        let success = await waitForMainActorCondition { noneScopeContainer.renderingNumber == 1 }
        #expect(success)

        let title1 = "title 1"
        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: title1))
        await waitForMainActorCondition { store.state.plainForm.title == title1 }

        window.redraw()
        #expect(noneScopeContainer.renderingNumber == 1)
    }
#endif
}

// MARK: - RootContainer
extension ContainerWithAppStateAsScopeTests {
    struct RootContainer: Container {
        func onContainerAppear(store: EnvironmentStore<AppState>) {}
        func onContainerDisappear(store: EnvironmentStore<AppState>) {}
        func onContainerDidLoad(store: EnvironmentStore<AppState>) {}

        typealias ContainerComponent = RootComponent

        @Box var renderingNumber: Int = 0

        func scope(for state: AppState) -> Scope {
            state
        }

        func map(store: EnvironmentStore<AppState>) -> RootComponent.Props {
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

        func onContainerAppear(store: EnvironmentStore<AppState>) {}
        func onContainerDisappear(store: EnvironmentStore<AppState>) {}
        func onContainerDidLoad(store: EnvironmentStore<AppState>) {}

        @Box var renderingNumber: Int = 0

        func scope(for state: AppState) -> Scope {
            .none
        }

        func map(store: EnvironmentStore<ContainerWithAppStateAsScopeTests.AppState>) -> ContainerWithAppStateAsScopeTests.RootComponent
            .Props
        {
            renderingNumber += 1
            print("NoneScopeContainer: renderingNumber - \(renderingNumber)")
            return .init(isUserLoggedIn: false)
        }
    }
}
