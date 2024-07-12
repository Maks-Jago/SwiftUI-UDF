
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
    }

//    func test_componentRenderingAfterStateMutation() async throws {
//        let store = try EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
//        let itemsContainer = ItemsListContainer()
//
//        let window = await MainActor.run {
//            let window = UIWindow(frame: .zero)
//            let viewController = UIHostingController(rootView: itemsContainer)
//            window.rootViewController = viewController
//
//            viewController.beginAppearanceTransition(true, animated: false)
//            viewController.endAppearanceTransition()
//
//            viewController.view.setNeedsLayout()
//            viewController.view.layoutIfNeeded()
//            return window
//        }
//
//        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "title 1"))
//        await fulfill(description: "waiting for rendering", sleep: 1)
//        print(window) //To force a window redraw
//        await fulfill(description: "waiting for rendering", sleep: 1)
//
//        XCTAssertEqual(itemsContainer.renderingNumber, 2)
//    }

    func test_OneTimeHook() async throws {
        let store = try EnvironmentStore(initial: AppState(), logger: TestStoreLogger())
        let rootContainer = RootContainer()

        let window = await MainActor.run {
            let window = UIWindow(frame: .zero)
            let viewController = UIHostingController(rootView: rootContainer)
            window.rootViewController = viewController

            viewController.beginAppearanceTransition(true, animated: false)
            viewController.endAppearanceTransition()

            viewController.view.setNeedsLayout()
            viewController.view.layoutIfNeeded()
            return window
        }

        XCTAssertEqual(store.state.hookForm.triggerValue, "")
        print(window) //To force a window redraw

//        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "title 1"))
        await fulfill(description: "waiting for rendering", sleep: 10)
        store.$state.hookForm.triggerValue.wrappedValue = "1"

        await fulfill(description: "waiting for dispatch", sleep: 10)
        XCTAssertEqual(store.state.hookForm.triggerValue, "1")
//
//        store.dispatch(Actions.UpdateFormField(keyPath: \UserData.isUserLoggedIn, value: true))
//        await fulfill(description: "waiting for rendering", sleep: 1)
//
//        print(window) //To force a window redraw
//        await fulfill(description: "waiting for rendering", sleep: 1)
//        XCTAssertEqual(rootContainer.renderingNumber, 2)
//
//        store.dispatch(Actions.UpdateFormField(keyPath: \UserData.isUserLoggedIn, value: false))
//        await fulfill(description: "waiting for rendering", sleep: 1)
//
//        print(window) //To force a window redraw
//        await fulfill(description: "waiting for rendering", sleep: 1)
//        XCTAssertEqual(rootContainer.renderingNumber, 3)
//
//        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "title 2"))
//        await fulfill(description: "waiting for rendering", sleep: 1)
//
//        print(window) //To force a window redraw
//        await fulfill(description: "waiting for rendering", sleep: 1)
//        XCTAssertEqual(rootContainer.renderingNumber, 3)
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

        func onContainerDidLoad(store: EnvironmentStore<ContainerHookTests.AppState>) {
            addHoook(id: "OneTimeHook", type: .oneTime) { state in
                state.hookForm.triggerValue == "1"
            } block: { store in
                store.$state.hookForm.triggerValue.wrappedValue = "2"
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
