
import SwiftUI
@testable import UDF
import UDFSwiftTesting
import Testing

@Suite(.serialized) struct BindableContainerLoadUnloadTests {
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
        let store = await TestStore(initial: AppState())

        var bindedReducersCount = await store.state.itemsForm.reducers.count
        #expect(bindedReducersCount == 0)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))

        bindedReducersCount = await store.state.itemsForm.reducers.count
        #expect(bindedReducersCount == 1)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 2)))

        bindedReducersCount = await store.state.itemsForm.reducers.count
        #expect(bindedReducersCount == 2)
    }

    @Test func whenBindableContainerUnloaded_BindableReducerCountShouldBeEqual0() async throws {
        let store = await TestStore(initial: AppState())

        var bindedReducersCount = await store.state.itemsForm.reducers.count
        #expect(bindedReducersCount == 0)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))

        bindedReducersCount = await store.state.itemsForm.reducers.count
        #expect(bindedReducersCount == 1)

        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: ItemsContainer.self, id: .init(value: 1)))

        bindedReducersCount = await store.state.itemsForm.reducers.count
        #expect(bindedReducersCount == 0)
    }

    @Test func whenBindableContainerHasMultipleInstances_BindableReducerShouldNotBeReleased() async throws {
        let store = await TestStore(initial: AppState())

        var bindedReducersCount = await store.state.itemsForm.reducers.count
        #expect(bindedReducersCount == 0)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))

        bindedReducersCount = await store.state.itemsForm.reducers.count
        #expect(bindedReducersCount == 1)

        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: ItemsContainer.self, id: .init(value: 1)))

        bindedReducersCount = await store.state.itemsForm.reducers.count
        #expect(bindedReducersCount == 1)

        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: ItemsContainer.self, id: .init(value: 1)))

        bindedReducersCount = await store.state.itemsForm.reducers.count
        #expect(bindedReducersCount == 1)

        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: ItemsContainer.self, id: .init(value: 1)))

        bindedReducersCount = await store.state.itemsForm.reducers.count
        #expect(bindedReducersCount == 0)
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
