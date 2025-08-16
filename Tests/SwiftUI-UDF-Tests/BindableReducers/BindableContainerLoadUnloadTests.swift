
import SwiftUI
@testable import UDF
import UDFSwiftTesting
import Testing

@Suite struct BindableContainerLoadUnloadTests {
    struct Item: Identifiable {
        struct ID: Hashable {
            var value: Int
        }

        var id: ID
    }

    struct ItemsForm: UDF.Form {}

    struct AppState: AppReducer {
        @BindableReducer(ItemsForm.self, bindedTo: ItemsContainer.self)
        fileprivate var itemsForm
    }

    @Test func whenTwoContainersLoaded_BindableReducerCountShouldBeEqual2() async throws {
        let store = EnvironmentStore(initial: AppState(), loggers: [])
        #expect(store.state.itemsForm.reducers.count == 0)

        store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        var success = await waitForCondition { store.state.itemsForm.reducers.count == 1 }
        #expect(success)

        store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 2)))
        success = await waitForCondition { store.state.itemsForm.reducers.count == 2 }
        #expect(success)
    }

    @Test func whenBindableContainerUnloaded_BindableReducerCountShouldBeEqual0() async throws {
        let store = EnvironmentStore(initial: AppState(), loggers: [])
        #expect(store.state.itemsForm.reducers.count == 0)

        store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        var success = await waitForCondition { store.state.itemsForm.reducers.count == 1 }
        #expect(success)

        store.dispatch(Actions._OnContainerDidUnLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        success = await waitForCondition { store.state.itemsForm.reducers.count == 0 }
        #expect(success)
    }

    @Test func whenBindableContainerHasMultipleInstances_BindableReducerShouldNotBeReleased() async throws {
        let store = EnvironmentStore(initial: AppState(), loggers: [])
        #expect(store.state.itemsForm.reducers.count == 0)

        store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        var success = await waitForCondition { store.state.itemsForm.reducers.count == 1 }
        #expect(success)

        store.dispatch(Actions._OnContainerDidUnLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        await sleep()

        #expect(store.state.itemsForm.reducers.count == 1)

        store.dispatch(Actions._OnContainerDidUnLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        await sleep()

        #expect(store.state.itemsForm.reducers.count == 1)

        store.dispatch(Actions._OnContainerDidUnLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        success = await waitForCondition { store.state.itemsForm.reducers.count == 0 }
        #expect(success)
    }
}

// MARK: Container
private extension BindableContainerLoadUnloadTests {
    struct ItemsContainer: BindableContainer {
        typealias ContainerComponent = ItemsComponent

        var id: Item.ID

        func scope(for state: AppState) -> Scope {
            state.itemsForm[id]
        }

        func map(store: EnvironmentStore<AppState>) -> ItemsComponent.Props {
            .init()
        }
    }

    struct ItemsComponent: Component {
        struct Props {}

        var props: Props

        var body: some View {
            Text("body")
        }
    }
}
