
import SwiftUI
@testable import UDF
import XCTest

final class ContainerLifecycleTests: XCTestCase {
    struct AppState: AppReducer {
        var userData = UserData()
    }

    struct UserData: UDF.Form {
        var isUserLoggedIn: Bool = false
        var didLoad: Bool = false
        var didUnload: Bool = false

        mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.ContainerDidLoad:
                self.didLoad = true

            case is Actions.ContainerDidUnload:
                self.didUnload = true

            default:
                break
            }
        }
    }

    @MainActor
    func test_ContainerLifecycle() async {
        let store = EnvironmentStore(initial: AppState(), logger: .consoleDebug)
        let rootContainer = RootContainer()

        var window: UIWindow? = await UIWindow.render(container: rootContainer)
        print(window!) // To force a window redraw

        await fulfill(description: "waiting for rendering", sleep: 1)
        XCTAssertTrue(store.state.userData.didLoad)

        window?.rootViewController = nil
        window = nil

        await fulfill(description: "waiting for rendering", sleep: 1)
        XCTAssertTrue(store.state.userData.didUnload)
    }
}

extension ContainerLifecycleTests {
    struct RootContainer: Container {
        typealias ContainerComponent = RootComponent

        func scope(for state: AppState) -> Scope {
            state
        }

        func map(store: EnvironmentStore<AppState>) -> RootComponent.Props {
            .init(
                isUserLoggedIn: store.state.userData.isUserLoggedIn
            )
        }

        func onContainerDidLoad(store: EnvironmentStore<ContainerLifecycleTests.AppState>) {
            store.dispatch(Actions.ContainerDidLoad())
        }

        func onContainerDidUnload(store: EnvironmentStore<ContainerLifecycleTests.AppState>) {
            store.dispatch(Actions.ContainerDidUnload())
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

private extension Actions {
    struct ContainerDidLoad: Action {}
    struct ContainerDidUnload: Action {}
}
