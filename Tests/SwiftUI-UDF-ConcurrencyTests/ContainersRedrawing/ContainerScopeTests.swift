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

@Suite(.serialized) struct ContainerScopeTests {
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

    struct ContainerScopeAppState: AppReducer {
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
        // No need to clear GlobalValue as we're using explicit store injection
        let store = EnvironmentStore(initial: ContainerScopeAppState(), logger: TestStoreLogger())
        
        let itemsContainer = ItemsListContainer()
        let window = await PlatformWindow.render(container: itemsContainer.with(store: store))

        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "title 1"))
        await fulfill(description: "waiting for rendering", sleep: 1)
        window.redraw()
        await fulfill(description: "waiting for rendering", sleep: 1)

        #expect(itemsContainer.renderingNumber == 2)
    }

    @Test 

    @MainActor func rootComponentRendering() async {
        // No need to clear GlobalValue as we're using explicit store injection
        let store = EnvironmentStore(initial: ContainerScopeAppState(), logger: TestStoreLogger())
        
        let rootContainer = RootContainer()
        let window = await PlatformWindow.render(container: rootContainer.with(store: store))

        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "title 1"))
        await fulfill(description: "waiting for rendering", sleep: 1)
        #expect(rootContainer.renderingNumber == 1)

        store.dispatch(Actions.UpdateFormField(keyPath: \UserData.isUserLoggedIn, value: true))
        await fulfill(description: "waiting for rendering", sleep: 1)

        window.redraw()
        await fulfill(description: "waiting for rendering", sleep: 1)
        #expect(rootContainer.renderingNumber == 2)

        store.dispatch(Actions.UpdateFormField(keyPath: \UserData.isUserLoggedIn, value: false))
        await fulfill(description: "waiting for rendering", sleep: 1)

        window.redraw()
        await fulfill(description: "waiting for rendering", sleep: 1)
        #expect(rootContainer.renderingNumber == 3)

        store.dispatch(Actions.UpdateFormField(keyPath: \PlainForm.title, value: "title 2"))
        await fulfill(description: "waiting for rendering", sleep: 1)

        window.redraw()
        await fulfill(description: "waiting for rendering", sleep: 1)
        #expect(rootContainer.renderingNumber == 3)
    }
}

// MARK: - ItemsListContainer
extension ContainerScopeTests {
    struct ItemsListContainer: Container {
        typealias ContainerComponent = ItemsListComponent

        @Box var renderingNumber: Int = 0

        func scope(for state: ContainerScopeTests.ContainerScopeAppState) -> Scope {
            state.plainForm
        }

        func map(store: EnvironmentStore<ContainerScopeAppState>) -> ContainerComponent.Props {
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

        func scope(for state: ContainerScopeAppState) -> Scope {
            state.userData
        }

        func map(store: EnvironmentStore<ContainerScopeAppState>) -> RootComponent.Props {
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
                Text("Root component - nested container removed to avoid GlobalValue dependency")

                if props.isUserLoggedIn {
                    Text("user logged in")
                } else {
                    Text("placeholder")
                }
            }
        }
    }
}
