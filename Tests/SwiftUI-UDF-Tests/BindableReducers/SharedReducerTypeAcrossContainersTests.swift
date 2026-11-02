import SwiftUI
@testable import UDF
import UDFSwiftTesting
import Testing

@TestStoreActor
@Suite struct SharedReducerTypeAcrossContainersTests {
    struct Item: Hashable, Identifiable {
        struct ID: Hashable {
            var value: Int
        }

        var id: ID
    }

    struct ItemsForm: UDF.Form {
        var title: String = ""
    }

    struct AppState: AppReducer {
        @BindableReducer(ItemsForm.self, bindedTo: ListContainer.self)
        fileprivate var listForm

        @BindableReducer(ItemsForm.self, bindedTo: DetailsContainer.self)
        fileprivate var detailsForm
    }

    @Test func whenOneContainerLoads_OnlyItsOwnBoundReducerShouldBeCreated() async throws {
        let store = TestStore(initial: AppState())
        let id = Item.ID(value: 1)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ListContainer.self, id: id))
        store.wait()

        var success = store.state.listForm.reducers.count == 1
        #expect(success, "Loading ListContainer should create exactly one ListContainer-bound ItemsForm instance")

        success = store.state.detailsForm.reducers.count == 0
        #expect(success, "Loading ListContainer must not create a DetailsContainer-bound ItemsForm instance")
    }

    @Test func whenBindedActionDispatched_OnlyTheMatchingContainersReducerShouldBeUpdated() async throws {
        let store = TestStore(initial: AppState())
        let id = Item.ID(value: 1)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ListContainer.self, id: id))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: DetailsContainer.self, id: id))
        store.wait()
        
        #expect(store.state.listForm.reducers.count == 1, "Loading ListContainer should create exactly one ListContainer-bound ItemsForm instance")
        #expect(store.state.detailsForm.reducers.count == 1, "Loading DetailsContainer should create exactly one DetailsContainer-bound ItemsForm instance")

        await store.dispatch {
            Actions.UpdateFormField(keyPath: \ItemsForm.title, value: "from-list")
                .binded(to: ListContainer.self, by: id)
        }
        store.wait()

        let listForm = try #require(store.state.listForm[id])
        #expect(listForm.title == "from-list", "The binded action should reach the ListContainer-bound reducer")

        let detailsForm = try #require(store.state.detailsForm[id])
        #expect(detailsForm.title.isEmpty, "The binded action must not leak into the DetailsContainer-bound reducer sharing the same ID and Reducer type")
    }

    @Test func whenOneContainerUnloads_TheOtherContainersReducerShouldSurvive() async throws {
        let store = TestStore(initial: AppState())
        let id = Item.ID(value: 1)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ListContainer.self, id: id))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: DetailsContainer.self, id: id))
        store.wait()
        
        #expect(store.state.listForm.reducers.count == 1, "Loading ListContainer should create exactly one ListContainer-bound ItemsForm instance")
        #expect(store.state.detailsForm.reducers.count == 1, "Loading DetailsContainer should create exactly one DetailsContainer-bound ItemsForm instance")

        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: ListContainer.self, id: id))
        store.wait()

        var success = store.state.listForm.reducers.count == 0
        #expect(success, "Unloading ListContainer should remove its bound ItemsForm instance")

        success = store.state.detailsForm.reducers.count == 1
        #expect(success, "Unloading ListContainer must not remove the DetailsContainer-bound ItemsForm instance")
    }

    @Test func whenDispatchingBindedNestedActionGroup_OnlyTheMatchingContainersReducerShouldBeUpdated() async throws {
        let store = TestStore(initial: AppState())
        let id = Item.ID(value: 1)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ListContainer.self, id: id))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: DetailsContainer.self, id: id))
        store.wait()
        
        #expect(store.state.listForm.reducers.count == 1, "Loading ListContainer should create exactly one ListContainer-bound ItemsForm instance")
        #expect(store.state.detailsForm.reducers.count == 1, "Loading DetailsContainer should create exactly one DetailsContainer-bound ItemsForm instance")

        await store.dispatch(
            ActionGroup {
                ActionGroup {
                    Actions.UpdateFormField(keyPath: \ItemsForm.title, value: "nested-from-details")
                }
            }
            .binded(to: DetailsContainer.self, by: id)
        )
        store.wait()

        let detailsForm = try #require(store.state.detailsForm[id])
        #expect(detailsForm.title == "nested-from-details", "A binded nested ActionGroup should reach the DetailsContainer-bound reducer")

        let listForm = try #require(store.state.listForm[id])
        #expect(listForm.title.isEmpty, "A binded nested ActionGroup must not leak into the ListContainer-bound reducer")
    }

    @Test func bindableReducerReference_shouldDispatchUpdatesOnlyToItsOwnBoundReducer() async throws {
        let store = TestStore(initial: AppState())
        let id = Item.ID(value: 1)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ListContainer.self, id: id))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: DetailsContainer.self, id: id))
        store.wait()
        
        #expect(store.state.listForm.reducers.count == 1, "Loading ListContainer should create exactly one ListContainer-bound ItemsForm instance")
        #expect(store.state.detailsForm.reducers.count == 1, "Loading DetailsContainer should create exactly one DetailsContainer-bound ItemsForm instance")

        let bindableReference: BindableReducerReference<AppState, Item.ID, ItemsForm> = store.$state.listForm
        bindableReference[id].title.wrappedValue = "via-reference"
        store.wait()

        let listForm = try #require(store.state.listForm[id])
        #expect(listForm.title == "via-reference", "The reference should update the ListContainer-bound reducer")

        let detailsForm = try #require(store.state.detailsForm[id])
        #expect(detailsForm.title.isEmpty, "The reference must not write through to the DetailsContainer-bound reducer")
    }

    struct ListContainer: BindableContainer {
        typealias ContainerComponent = ItemsComponent

        var id: Item.ID

        func scope(for state: AppState) -> Scope {
            state.listForm[id]
        }

        func map(store: EnvironmentStore<AppState>) -> ItemsComponent.Props {
            .init()
        }
    }

    struct DetailsContainer: BindableContainer {
        typealias ContainerComponent = ItemsComponent

        var id: Item.ID

        func scope(for state: AppState) -> Scope {
            state.detailsForm[id]
        }

        func map(store: EnvironmentStore<AppState>) -> ItemsComponent.Props {
            .init()
        }
    }

    struct ItemsComponent: Component {
        struct Props {}

        var props: Props

        var body: some View {
            EmptyView()
        }
    }
}
