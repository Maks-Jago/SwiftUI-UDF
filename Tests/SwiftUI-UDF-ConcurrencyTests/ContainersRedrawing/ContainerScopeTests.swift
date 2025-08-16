//
//  ContainerScopeTests.swift
//  SwiftUI-UDF-ConcurrencyTests
//
//  Created by Max Kuznetsov on 07.11.2022.
//

import SwiftUI
@testable import UDF
import Testing
import UDFSwiftTesting

@Suite struct ContainerScopeTests {
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

    @Test
    @MainActor func componentRenderingAfterStateMutation() async {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        let itemsContainer = ItemsListContainer()
        let window = await PlatformWindow.render(container: itemsContainer.with(store: store))

        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "title 1"))
        _ = await waitForMainActorCondition { itemsContainer.renderingNumber == 1 }

        window.redraw()
        let success = await waitForMainActorCondition { itemsContainer.renderingNumber == 2 }
        #expect(success)
    }

    @Test
    @MainActor func rootComponentRendering() async {
        let store = EnvironmentStore(initial: AppState(), logger: TestStoreLogger())

        let rootContainer = RootContainer()
        let window = await PlatformWindow.render(container: rootContainer.with(store: store))

        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "title 1"))
        var success = await waitForMainActorCondition { rootContainer.renderingNumber == 1 }
        #expect(success)

        store.dispatch(Actions.UpdateFormField(keyPath: \UserData.isUserLoggedIn, value: true))

        window.redraw()
        success = await waitForMainActorCondition { rootContainer.renderingNumber == 2 }
        #expect(success)

        store.dispatch(Actions.UpdateFormField(keyPath: \UserData.isUserLoggedIn, value: false))

        window.redraw()
        success = await waitForMainActorCondition { rootContainer.renderingNumber == 3 }
        #expect(success)

        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "title 2"))
        await sleep()

        window.redraw()
        await sleep()
        #expect(rootContainer.renderingNumber == 3)
    }
}

// MARK: - ItemsListContainer
extension ContainerScopeTests {
    struct ItemsListContainer: Container {
        typealias ContainerComponent = ItemsListComponent

        @Box var renderingNumber: Int = 0

        func scope(for state: ContainerScopeTests.AppState) -> Scope {
            state.plainForm
        }

        func map(store: EnvironmentStore<AppState>) -> ContainerComponent.Props {
            renderingNumber += 1
            print("ItemsListContainer: renderingNumber - \(renderingNumber)")

            return .init(
                title: store.state.plainForm.title
            )
        }
    }

    struct ItemsListComponent: Component {
        struct Props {
            var title: String
        }

        var props: Props

        var body: some View {
            print("props.title: \(props.title)")
            return Text(props.title)
        }
    }
}

// MARK: - RootContainer
extension ContainerScopeTests {
    struct RootContainer: Container {
        typealias ContainerComponent = RootComponent

        @Box var renderingNumber: Int = 0

        func scope(for state: AppState) -> Scope {
            state.userData
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
                ItemsListContainer()

                if props.isUserLoggedIn {
                    Text("user logged in")
                } else {
                    Text("placeholder")
                }
            }
        }
    }
}
