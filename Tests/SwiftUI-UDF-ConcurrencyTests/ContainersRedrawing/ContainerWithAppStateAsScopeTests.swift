import XCTest
import SwiftUI
@testable import UDF

final class ContainerWithAppStateAsScopeTests: XCTestCase {

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
            print("---------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
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

    func createWindow(with container: some Container) async  -> UIWindow {
        await MainActor.run {
            let window = UIWindow(frame: .zero)
            let viewController = UIHostingController(rootView: container)
            window.rootViewController = viewController

            viewController.beginAppearanceTransition(true, animated: false)
            viewController.endAppearanceTransition()

            viewController.view.setNeedsLayout()
            viewController.view.layoutIfNeeded()
            return window
        }
    }

    func test_rootComponentRendering() async {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = RootContainer()
        let window = await createWindow(with: rootContainer)

        XCTAssertEqual(rootContainer.renderingNumber, 0)
        await fulfill(description: "waiting for first rendering", sleep: 1)
        XCTAssertEqual(rootContainer.renderingNumber, 1)

        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "title 1"))
        await fulfill(description: "waiting for rendering", sleep: 1)

        print(window) //To force a window redraw
        await fulfill(description: "waiting for rendering", sleep: 1)
        XCTAssertEqual(rootContainer.renderingNumber, 2)

        store.dispatch(Actions.UpdateFormField(keyPath: \UserData.isUserLoggedIn, value: true))
        await fulfill(description: "waiting for rendering", sleep: 1)

        print(window) //To force a window redraw
        await fulfill(description: "waiting for rendering", sleep: 1)
        XCTAssertEqual(rootContainer.renderingNumber, 3)

        store.dispatch(Actions.UpdateFormField(keyPath: \UserData.isUserLoggedIn, value: false))
        await fulfill(description: "waiting for rendering", sleep: 1)

        print(window) //To force a window redraw
        await fulfill(description: "waiting for rendering", sleep: 1)
        XCTAssertEqual(rootContainer.renderingNumber, 4)

        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "title 2"))
        await fulfill(description: "waiting for rendering", sleep: 1)

        print(window) //To force a window redraw
        await fulfill(description: "waiting for rendering", sleep: 1)
        XCTAssertEqual(rootContainer.renderingNumber, 5)
    }

    func test_noneScope() async {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let noneScopeContainer = NoneScopeContainer()
        let window = await createWindow(with: noneScopeContainer)

        XCTAssertEqual(noneScopeContainer.renderingNumber, 0)
        await fulfill(description: "waiting for first rendering", sleep: 1)
        XCTAssertEqual(noneScopeContainer.renderingNumber, 1)

        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "title 1"))
        await fulfill(description: "waiting for rendering", sleep: 1)

        print(window) //To force a window redraw
        XCTAssertEqual(noneScopeContainer.renderingNumber, 1)
    }
}


//MARK: - RootContainer
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

//MARK: - None scope container
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

        func map(store: EnvironmentStore<ContainerWithAppStateAsScopeTests.AppState>) -> ContainerWithAppStateAsScopeTests.RootComponent.Props {
            renderingNumber += 1
            print("NoneScopeContainer: renderingNumber - \(renderingNumber)")
            return .init(isUserLoggedIn: false)
        }
    }
}
