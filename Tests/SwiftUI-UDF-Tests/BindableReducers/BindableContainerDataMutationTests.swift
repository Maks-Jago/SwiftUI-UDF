
import SwiftUI
@testable import UDF
import UDFSwiftTesting
import Testing

@Suite struct BindableContainerDataMutationTests {
    struct Item: Hashable, Identifiable {
        struct ID: Hashable {
            var value: Int
        }

        var id: ID
    }

    struct ItemsForm: UDF.Form {
        var paginator: Paginator = .init(Item.self, flowId: ItemsFlow.id, perPage: 10)
        var item: Item.ID? = nil

        var message: String = ""

        mutating func reduce(_ action: some Action) {
            switch action {
            default:
                break
            }
        }
    }

    enum ItemsFlow: IdentifiableFlow {
        case none, loading

        init() {
            self = .none
        }
    }

    struct AllItems: Reducible {
        var byId: [Item.ID: Item] = [:]

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidLoadItems<Item>:
                byId.insert(items: action.items)

            default:
                break
            }
        }
    }

    struct AppState: AppReducer {
        var allItems = AllItems()

        @BindableReducer(ItemsForm.self, bindedTo: ItemsContainer.self)
        fileprivate var itemsForm

        @BindableReducer(ItemsFlow.self, bindedTo: ItemsContainer.self)
        fileprivate var itemsFlow
    }

    @Test func whenMutateBindableForm_OnleConcreteInstanceOfBindableFormShouldBeUpdated() async throws {
        let store = await TestStore(initial: AppState())
        #expect(await store.state.itemsForm.reducers.count == 0)
        #expect(await store.state.itemsFlow.reducers.count == 0)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 2)))

        var success = await waitForCondition { await store.state.itemsForm.reducers.count == 2 }
        #expect(success)

        success = await waitForCondition { await store.state.itemsFlow.reducers.count == 2 }
        #expect(success)

        await store.dispatch(
            Actions.UpdateFormField(keyPath: \ItemsForm.item, value: .init(value: 2))
                .binded(to: ItemsContainer.self, by: .init(value: 2))
        )
        success = await waitForCondition { await store.state.itemsForm[Item.ID(value: 2)]?.item != nil }
        #expect(success)

        await store.dispatch(
            Actions.DidLoadItems(
                items: [Item(id: .init(value: 4)), Item(id: .init(value: 5))],
                id: ItemsFlow.id
            )
            .binded(to: ItemsContainer.self, by: .init(value: 2))
        )
        success = await waitForCondition {
            await store.state.itemsForm[Item.ID(value: 2)]?.paginator.items.count == 2
        }
        #expect(success)
    }

    @Test func whenBindableActionDispatched_StorageShouldReceiveOriginalAction() async throws {
        let store = await TestStore(initial: AppState())
        #expect(await store.state.itemsForm.reducers.count == 0)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 2)))

        var success = await waitForCondition { await store.state.itemsForm.reducers.count == 2 }
        #expect(success)

        let items = [Item(id: .init(value: 1)), Item(id: .init(value: 2))]

        await store.dispatch(
            Actions.DidLoadItems(items: items, id: ItemsFlow.id)
                .binded(to: ItemsContainer.self, by: Item.ID(value: 1))
        )
        success = await waitForCondition { await !store.state.allItems.byId.isEmpty }
        #expect(success)

        let itemsForm1 = try await #require(store.state.itemsForm[Item.ID(value: 1)])
        #expect(!itemsForm1.paginator.items.isEmpty)

        let itemsForm2 = try await #require(store.state.itemsForm[Item.ID(value: 2)])
        #expect(itemsForm2.paginator.items.isEmpty)
    }
}

// MARK: Container
private extension BindableContainerDataMutationTests {
    struct ItemsContainer: BindableContainer {
        typealias ContainerComponent = ItemsComponent

        var id: Item.ID

        func scope(for state: AppState) -> Scope {
            state.itemsForm[id]
            state.itemsFlow[id]
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
