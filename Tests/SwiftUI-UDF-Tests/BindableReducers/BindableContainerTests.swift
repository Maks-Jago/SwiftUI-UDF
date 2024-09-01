
import XCTest
@testable import UDF
import SwiftUI
import UDFXCTest

final class BindableContainerTests: XCTestCase {

    struct Item: Identifiable {
        struct ID: Hashable {
            var value: Int
        }

        var id: ID
    }

    struct ItemsForm: UDF.Form {
        
    }

    struct AppState: AppReducer {

        @BindableReducer(containerType: ItemsContainer.self, reducerType: ItemsForm.self)
        var itemsForm
    }

    func test_WhenTwoContainersLoaded_BindableReducerCountShouldBeEqual2() async throws {
        let store = await XCTestStore(initial: AppState())

        var bindedReducersCount = try await XCTUnwrapAsync(await store.state.itemsForm).reducers.count
        XCTAssertEqual(bindedReducersCount, 0)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))

        bindedReducersCount = try await XCTUnwrapAsync(await store.state.itemsForm).reducers.count
        XCTAssertEqual(bindedReducersCount, 1)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 2)))

        bindedReducersCount = try await XCTUnwrapAsync(await store.state.itemsForm).reducers.count
        XCTAssertEqual(bindedReducersCount, 2)
    }

    func test_WhenBindableContainerUnloaded_BindableReducerCountShouldBeEqual0() async throws {
        let store = await XCTestStore(initial: AppState())
        
        var bindedReducersCount = try await XCTUnwrapAsync(await store.state.itemsForm).reducers.count
        XCTAssertEqual(bindedReducersCount, 0)

        await store.dispatch(Actions._OnContainerDidLoad(containerType: ItemsContainer.self, id: .init(value: 1)))

        bindedReducersCount = try await XCTUnwrapAsync(await store.state.itemsForm).reducers.count
        XCTAssertEqual(bindedReducersCount, 1)

        await store.dispatch(Actions._OnContainerDidUnLoad(containerType: ItemsContainer.self, id: .init(value: 1)))
        
        bindedReducersCount = try await XCTUnwrapAsync(await store.state.itemsForm).reducers.count
        XCTAssertEqual(bindedReducersCount, 0)
    }
}

// MARK: Container
extension BindableContainerTests {
    
    struct ItemsContainer: BindableContainer {
        typealias ContainerComponent = ItemsComponent

        var id: Item.ID

        func scope(for state: BindableContainerTests.AppState) -> Scope {
            state.itemsForm[id]
        }

        func map(store: EnvironmentStore<AppState>) -> BindableContainerTests.ItemsComponent.Props {
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
