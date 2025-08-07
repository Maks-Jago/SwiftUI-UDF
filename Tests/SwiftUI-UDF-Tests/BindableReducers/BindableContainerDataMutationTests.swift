
import SwiftUI
@testable import UDF
import UDFSwiftTesting
import Testing

@Suite(.serialized) struct BindableContainerDataMutationTests {
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
        let store = EnvironmentStore(initial: AppState(), loggers: [])

        let itemsForm = try #require(store.state.itemsForm)
        var bindedReducersFormCount = itemsForm.reducers.count
        #expect(bindedReducersFormCount == 0)

        let itemsFlow = try #require(store.state.itemsFlow)  
        var bindedReducersFlowCount = itemsFlow.reducers.count
        #expect(bindedReducersFlowCount == 0)

        store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 2)))
        await fulfill(description: "waiting for container load actions to process", sleep: 0.3)

        let itemsFormAfter = try #require(store.state.itemsForm)
        bindedReducersFormCount = itemsFormAfter.reducers.count
        #expect(bindedReducersFormCount == 2)

        let itemsFlowAfter = try #require(store.state.itemsFlow)
        bindedReducersFlowCount = itemsFlowAfter.reducers.count
        #expect(bindedReducersFlowCount == 2)

        store.dispatch(
            Actions.UpdateFormField(keyPath: \ItemsForm.item, value: .init(value: 2))
                .binded(to: ItemsContainer.self, by: .init(value: 2))
        )
        await fulfill(description: "waiting for form update action to process", sleep: 0.3)

        _ = try #require(store.state.itemsForm[Item.ID(value: 2)]?.item)

        store.dispatch(
            Actions.DidLoadItems(
                items: [Item(id: .init(value: 4)), Item(id: .init(value: 5))],
                id: ItemsFlow.id
            )
            .binded(to: ItemsContainer.self, by: .init(value: 2))
        )
        await fulfill(description: "waiting for load items action to process", sleep: 0.3)

        let itemsCount = try #require(store.state.itemsForm[Item.ID(value: 2)]?.paginator.items.count)
        #expect(itemsCount == 2)
    }

    @Test func whenBindableActionDispatched_StorageShouldReceiveOriginalAction() async throws {
        let store = EnvironmentStore(initial: AppState(), loggers: [])

        let itemsForm = try #require(store.state.itemsForm)
        var bindedReducersFormCount = itemsForm.reducers.count
        #expect(bindedReducersFormCount == 0)

        store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 2)))
        await fulfill(description: "waiting for container load actions to process", sleep: 0.3)

        let itemsFormAfter2 = try #require(store.state.itemsForm)
        bindedReducersFormCount = itemsFormAfter2.reducers.count
        #expect(bindedReducersFormCount == 2)

        let items = [Item(id: .init(value: 1)), Item(id: .init(value: 2))]

        store.dispatch(
            Actions.DidLoadItems(items: items, id: ItemsFlow.id)
                .binded(to: ItemsContainer.self, by: Item.ID(value: 1))
        )
        await fulfill(description: "waiting for load items action to process", sleep: 0.3)

        let allItems = store.state.allItems.byId
        #expect(!allItems.isEmpty)

        let itemsForm1 = try #require(store.state.itemsForm[Item.ID(value: 1)])
        #expect(!itemsForm1.paginator.items.isEmpty)

        let itemsForm2 = try #require(store.state.itemsForm[Item.ID(value: 2)])
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
