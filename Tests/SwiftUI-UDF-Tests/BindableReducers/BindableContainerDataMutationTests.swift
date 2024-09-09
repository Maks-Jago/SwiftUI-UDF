
import XCTest
@testable import UDF
import SwiftUI
import UDFXCTest

final class BindableContainerDataMutationTests: XCTestCase {

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

    struct AppState: AppReducer {

        @BindableReducer(ItemsForm.self, containerType: ItemsContainer.self)
        fileprivate var itemsForm

        @BindableReducer(ItemsFlow.self, containerType: ItemsContainer.self)
        fileprivate var itemsFlow
    }

    func test_WhenMutateBindableForm_OnleConcreteInstanceOfBindableFormShouldBeUpdated() async throws {
        let store = await XCTestStore(initial: AppState())

        var bindedReducersFormCount = try await XCTUnwrapAsync(await store.state.itemsForm).reducers.count
        XCTAssertEqual(bindedReducersFormCount, 0)

        var bindedReducersFlowCount = try await XCTUnwrapAsync(await store.state.itemsFlow).reducers.count
        XCTAssertEqual(bindedReducersFlowCount, 0)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 2)))

        bindedReducersFormCount = try await XCTUnwrapAsync(await store.state.itemsForm).reducers.count
        XCTAssertEqual(bindedReducersFormCount, 2)

        bindedReducersFlowCount = try await XCTUnwrapAsync(await store.state.itemsFlow).reducers.count
        XCTAssertEqual(bindedReducersFlowCount, 2)

        await store.dispatch(
            Actions.UpdateFormField(keyPath: \ItemsForm.item, value: .init(value: 2))
                .bindable(containerType: ItemsContainer.self, id: .init(value: 2))
        )

        _ = try await XCTUnwrapAsync(await store.state.itemsForm[.init(value: 2)]?.item)

        await store.dispatch(
            Actions.DidLoadItems(
                items: [Item(id: .init(value: 4)), Item(id: .init(value: 5))], 
                id: ItemsFlow.id
            )
            .bindable(containerType: ItemsContainer.self, id: .init(value: 2))
        )

        let itemsCount = try await XCTUnwrapAsync(await store.state.itemsForm[.init(value: 2)]).paginator.items.count
        XCTAssertEqual(itemsCount, 2)
    }
}

// MARK: Container
fileprivate extension BindableContainerDataMutationTests {

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
        struct Props {

        }

        var props: Props

        var body: some View {
            Text("body")
        }
    }
}
