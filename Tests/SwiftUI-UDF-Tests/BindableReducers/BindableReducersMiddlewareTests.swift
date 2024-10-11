//
//  BindableReducersMiddlewareTests.swift
//
//
//  Created by Max Kuznetsov on 09.09.2024.
//

import SwiftUI
@testable import UDF
import UDFXCTest
import XCTest

final class BindableReducersMiddlewareTests: XCTestCase {
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
    }

    func test_WhenLoadingDataForBindableReducers_OnleConcreteInstanceOfBindableFormShouldBeUpdated() async throws {
        let store = await XCTestStore(initial: AppState())
        await store.subscribe(ItemsMiddleware.self)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 2)))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 3)))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 4)))

        let bindedReducersFormCount = try await XCTUnwrapAsync(await store.state.itemsForm).reducers.count
        XCTAssertEqual(bindedReducersFormCount, 4)

        let bindedReducersFlowCount = try await XCTUnwrapAsync(await store.state.itemsFlow).reducers.count
        XCTAssertEqual(bindedReducersFlowCount, 4)

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

        let itemsForm1: ItemsForm = try await XCTUnwrapAsync(await store.state.itemsForm[Item.ID(value: 1)])
        XCTAssertNotNil(itemsForm1.item)

        let itemsForm2: ItemsForm = try await XCTUnwrapAsync(await store.state.itemsForm[Item.ID(value: 2)])
        XCTAssertNil(itemsForm2.item)

        let itemsForm3: ItemsForm = try await XCTUnwrapAsync(await store.state.itemsForm[Item.ID(value: 3)])
        XCTAssertNotNil(itemsForm3.item)

        let itemsForm4: ItemsForm = try await XCTUnwrapAsync(await store.state.itemsForm[Item.ID(value: 4)])
        XCTAssertNotNil(itemsForm4.item)
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
    final class ItemsMiddleware: BaseObservableMiddleware<AppState> {
        enum Cancellation: Hashable {
            case itemDetails(Item.ID)
        }

        struct Environment {
            var loadItemDetails: (
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
                    execute(id: ItemsFlow.id, cancellation: Cancellation.itemDetails(id)) { flowId in
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
