//
//  BindableReducersMiddlewareTests.swift
//
//
//  Created by Max Kuznetsov on 09.09.2024.
//

import SwiftUI
@testable import UDF
import UDFSwiftTesting
import Testing

@Suite(.serialized) struct BindableReducersMiddlewareTests {
    struct Item: Hashable, Identifiable {
        struct ID: Hashable {
            var value: Int
        }

        var id: ID
    }

    struct ItemsForm: UDF.Form {
        var paginator: Paginator = .init(Item.self, flowId: ItemsFlow.id, perPage: 10)
        var item: Item? = nil

        var message: String = ""

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidLoadItem<Item> where action.id == ItemsFlow.id:
                item = action.item

            default:
                break
            }
        }
    }

    struct ItemReducible: UDF.Reducible {
        var didLoadItemReduced: Int = 0

        mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.DidLoadItem<Item>:
                didLoadItemReduced += 1

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

        mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.LoadItem:
                self = .loading

            default:
                break
            }
        }
    }

    struct AppState: AppReducer {
        @BindableReducer(ItemsForm.self, bindedTo: ItemsContainer.self)
        fileprivate var itemsForm

        @BindableReducer(ItemsFlow.self, bindedTo: ItemsContainer.self)
        fileprivate var itemsFlow

        var itemReducible = ItemReducible()
    }

    @Test func whenLoadingDataForBindableReducers_OnleConcreteInstanceOfBindableFormShouldBeUpdated() async throws {
        let store = await TestStore(initial: AppState())
        await store.subscribe(ItemsMiddleware.self)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 2)))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 3)))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 4)))

        let bindedReducersFormCount = await store.state.itemsForm.reducers.count
        #expect(bindedReducersFormCount == 4)

        let bindedReducersFlowCount = await store.state.itemsFlow.reducers.count
        #expect(bindedReducersFlowCount == 4)

        await store.dispatch(
            ActionGroup {
                Actions.LoadItem(id: .init(value: 1))
                    .binded(to: ItemsContainer.self, by: Item.ID(value: 1))

                Actions.LoadItem(id: .init(value: 3))
                    .binded(to: ItemsContainer.self, by: Item.ID(value: 3))

                Actions.LoadItem(id: .init(value: 4))
                    .binded(to: ItemsContainer.self, by: Item.ID(value: 4))
            }
        )

        await store.wait()

        let itemsForm1: ItemsForm = try #require(await store.state.itemsForm[Item.ID(value: 1)])
        #expect(itemsForm1.item != nil)

        let itemsForm2: ItemsForm = try #require(await store.state.itemsForm[Item.ID(value: 2)])
        #expect(itemsForm2.item == nil)

        let itemsForm3: ItemsForm = try #require(await store.state.itemsForm[Item.ID(value: 3)])
        #expect(itemsForm3.item != nil)

        let itemsForm4: ItemsForm = try #require(await store.state.itemsForm[Item.ID(value: 4)])
        #expect(itemsForm4.item != nil)
    }

    @Test func whenDispatchingBindedAction_DuplicationShouldBePrevented() async throws {
        let store = await TestStore(initial: AppState())
        await store.subscribe(ItemsMiddleware.self)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))

        let bindedReducersFormCount = await store.state.itemsForm.reducers.count
        #expect(bindedReducersFormCount == 1)

        let bindedReducersFlowCount = await store.state.itemsFlow.reducers.count
        #expect(bindedReducersFlowCount == 1)

        await store.dispatch(
            ActionGroup {
                Actions.LoadItem(id: .init(value: 1))
            }.binded(to: ItemsContainer.self, by: Item.ID(value: 1))
        )

        await store.wait()

        let itemsForm1: ItemsForm = try #require(await store.state.itemsForm[Item.ID(value: 1)])
        let itemsReducer = await store.state.itemReducible

        #expect(itemsForm1.item != nil)
        #expect(itemsReducer.didLoadItemReduced == 1)
    }
}

// MARK: Actions
private extension Actions {
    struct LoadItem: Action {
        var id: BindableReducersMiddlewareTests.Item.ID
    }
}

// MARK: Container
private extension BindableReducersMiddlewareTests {
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

// MARK: Middleware
private extension BindableReducersMiddlewareTests {
    final class ItemsMiddleware: Middleware<AppState>, @unchecked Sendable {
        enum Cancellation: Hashable {
            case itemDetails(Item.ID)
        }

        struct Environment : Sendable{
            var loadItemDetails: @Sendable (
                _ itemId: Item.ID
            ) async throws -> Item
        }

        var environment: Environment!

        func scope(for state: BindableReducersMiddlewareTests.AppState) -> any Scope {
            state.itemsFlow
        }

        func observe(state: BindableReducersMiddlewareTests.AppState) {
            for (id, flow) in state.itemsFlow {
                switch flow {
                case .loading:
                    execute(flowId: ItemsFlow.id, cancellation: Cancellation.itemDetails(id)) { flowId in
                        let item = try await self.environment.loadItemDetails(id)
                        return Actions.DidLoadItem(item: item, id: flowId)
                            .binded(to: ItemsContainer.self, by: id)
                    }

                default:
                    break
                }
            }
        }

        static func buildLiveEnvironment(for store: some Store<AppState>) -> Environment {
            Environment(
                loadItemDetails: { id in
                    try await Task.sleep(nanoseconds: 100)
                    return Item(id: id)
                }
            )
        }

        static func buildTestEnvironment(for store: some Store<AppState>) -> Environment {
            Environment(
                loadItemDetails: { id in
                    try await Task.sleep(nanoseconds: 100)
                    return Item(id: id)
                }
            )
        }
    }
}
