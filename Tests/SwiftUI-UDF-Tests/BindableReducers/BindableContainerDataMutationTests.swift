
import SwiftUI
@testable import UDF
import UDFSwiftTesting
import Testing

@TestStoreActor
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
        var title: String = ""

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidLoadItem<Item>:
                self.item = action.item.id
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
        let store = TestStore(initial: AppState())
        #expect(await store.state.itemsForm.reducers.count == 0)
        #expect(await store.state.itemsFlow.reducers.count == 0)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 2)))

        var success = store.state.itemsForm.reducers.count == 2
        #expect(success)

        success = store.state.itemsFlow.reducers.count == 2
        #expect(success)

        await store.dispatch(
            Actions.UpdateFormField(keyPath: \ItemsForm.item, value: .init(value: 2))
                .binded(to: ItemsContainer.self, by: .init(value: 2))
        )
        success = store.state.itemsForm[Item.ID(value: 2)]?.item != nil
        #expect(success)

        await store.dispatch(
            Actions.DidLoadItems(
                items: [Item(id: .init(value: 4)), Item(id: .init(value: 5))],
                id: ItemsFlow.id
            )
            .binded(to: ItemsContainer.self, by: .init(value: 2))
        )
        success = store.state.itemsForm[Item.ID(value: 2)]?.paginator.items.count == 2
        #expect(success)
    }

    @Test func whenBindableActionDispatched_StorageShouldReceiveOriginalAction() async throws {
        let store = TestStore(initial: AppState())
        #expect(await store.state.itemsForm.reducers.count == 0)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 2)))

        var success = store.state.itemsForm.reducers.count == 2
        #expect(success)

        let items = [Item(id: .init(value: 1)), Item(id: .init(value: 2))]

        await store.dispatch(
            Actions.DidLoadItems(items: items, id: ItemsFlow.id)
                .binded(to: ItemsContainer.self, by: Item.ID(value: 1))
        )
        success = !store.state.allItems.byId.isEmpty
        #expect(success)

        let itemsForm1 = try #require(store.state.itemsForm[Item.ID(value: 1)])
        #expect(!itemsForm1.paginator.items.isEmpty)

        let itemsForm2 = try #require(store.state.itemsForm[Item.ID(value: 2)])
        #expect(itemsForm2.paginator.items.isEmpty)
    }

    @Test func bindableActionEquality() {
        struct TestAction: Action {}
        struct OtherAction: Action {}
        
        let action1 = Actions._BindableAction(value: TestAction(), containerType: ItemsContainer.self, id: Item.ID(value: 1))
        let action2 = Actions._BindableAction(value: TestAction(), containerType: ItemsContainer.self, id: Item.ID(value: 2))
        let action3 = Actions._BindableAction(value: TestAction(), containerType: ItemsContainer.self, id: Item.ID(value: 1))
        let action4 = Actions._BindableAction(value: OtherAction(), containerType: ItemsContainer.self, id: Item.ID(value: 1))
        
        #expect(action1 != action2)
        #expect(action1 == action3)
        #expect(action1 != action4)
    }
    
    @Test func whenDispatchingBindedActionGroup_NestedActionsShouldBeReducedForTheBoundContainer() async throws {
        let store = TestStore(initial: AppState())
        let id = ItemsContainer.ID(value: 1)
        let message = "Important message"
        let title = "Important title"

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: id))
        
        var success = store.state.itemsForm.reducers.count == 1
        #expect(success, "Loading the bindable container should create exactly one ItemsForm reducer instance")

        success = store.state.itemsFlow.reducers.count == 1
        #expect(success, "Loading the bindable container should create exactly one ItemsFlow reducer instance")
        
        await store.dispatch(
            ActionGroup {
                Actions.DidLoadItem<Item>(item: .init(id: .init(value: 1)))
                ActionGroup {
                    Actions.UpdateFormField(keyPath: \ItemsForm.message, value: message)
                    ActionGroup {
                        Actions.UpdateFormField(keyPath: \ItemsForm.title, value: title)
                    }
                }
            }
            .binded(to: ItemsContainer.self, by: id)
        )
        store.wait()
        let itemForm = try #require(
            await store.state.itemsForm[id],
            "Expected bound ItemsForm state to exist for the loaded container ID"
        )
        #expect(itemForm.message == message && itemForm.item != nil && itemForm.title == title, "Dispatching a binded nested ActionGroup should update the bound form message, title and load the item")
        
        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: ItemsContainer.self, id: id))
        
        success = store.state.itemsForm.reducers.count == 0
        #expect(success, "Unloading the bindable container should remove the bound ItemsForm reducer instance")

        success = store.state.itemsFlow.reducers.count == 0
        #expect(success, "Unloading the bindable container should remove the bound ItemsFlow reducer instance")
    }

    @Test func bindableReducerReference_shouldDispatchUpdatesOnlyToTheSelectedBoundReducer() async throws {
        let store = TestStore(initial: AppState())
        let firstID = ItemsContainer.ID(value: 1)
        let secondID = ItemsContainer.ID(value: 2)
        
        let updatedTitle = "Updated title in bindable reducer"

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: firstID))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: secondID))
        
        var success = store.state.itemsForm.reducers.count == 2
        #expect(success, "Loading the bindable container should create exactly one ItemsForm reducer instance")

        success = store.state.itemsFlow.reducers.count == 2
        #expect(success, "Loading the bindable container should create exactly one ItemsFlow reducer instance")

        let bindableReference: BindableReducerReference<AppState, Item.ID, ItemsForm> = store.$state.itemsForm
        (bindableReference[firstID].title as Binding<String>).wrappedValue = updatedTitle

        store.wait()

        let firstForm = try #require(
            store.state.itemsForm[firstID],
            "Expected the first bound ItemsForm reducer to exist after container load"
        )
        let secondForm = try #require(
            store.state.itemsForm[secondID],
            "Expected the second bound ItemsForm reducer to exist after container load"
        )

        #expect(firstForm.title == updatedTitle, "BindableReducerReference should dispatch the update to the selected bound reducer instance")
        #expect(secondForm.title.isEmpty, "BindableReducerReference should not update a different bound reducer instance")
        
        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: ItemsContainer.self, id: firstID))
        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: ItemsContainer.self, id: secondID))
        
        success = store.state.itemsForm.reducers.count == 0
        #expect(success, "Unloading the bindable container should remove the bound ItemsForm reducer instance")

        success = store.state.itemsFlow.reducers.count == 0
        #expect(success, "Unloading the bindable container should remove the bound ItemsFlow reducer instance")
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
