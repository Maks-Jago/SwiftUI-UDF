
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
//        var paginator: Paginator = .init(Item.self, flowId: ItemsFlow.id, perPage: 10) //TODO: Update paginator to use inside BindableReducer
        /// Maybe we need something like Actions.AnyAction.bindable(to: ItemsContainer.self, id: Item.ID.init())

//        var items: [Item.ID] = []

        var item: Item.ID? = nil
        var items: [Item] = []

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidLoadConcreteItems where action.id == ItemsFlow.FlowId.value(item):
                items = action.items

            default:
                break
            }
        }
    }

    enum ItemsFlow: Flow {
        case none, loading

        enum FlowId: Hashable {
            case value(Item.ID?)
        }

//        static var id: FlowId { . }

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
//        Actions.UpdateFormField(keyPath: <#T##WritableKeyPath<Form, Equatable>#>, value: <#T##Equatable#>)

//        var bindedReducersCount = try XCTUnwrap(await store.state.itemsForm).reducers.count
//        XCTAssertEqual(bindedReducersCount, 0)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 2)))

        //UpdateFormField
//        store.$state.itemsForm[.init(value: 2)].message.wrappedValue = "Items Form 2"

//        let message1 = store.state.itemsForm[.init(value: 1)].message
//        XCTAssertTrue(message1.isEmpty)

//        let message2 = store.state.itemsForm[.init(value: 2)].message
//        XCTAssertEqual(message2, "Items Form 2")
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

// MARK: Actions
fileprivate extension Actions {

    struct DidLoadConcreteItems: Action {
        var items: [BindableContainerDataMutationTests.Item]
        var id: AnyHashable

        init<ID: Hashable>(items: [BindableContainerDataMutationTests.Item], id: ID) {
            self.items = items
            self.id = AnyHashable(id)
        }
    }
}
