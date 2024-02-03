
import XCTest
@testable import UDF

class MergeableAppStateTests: XCTestCase {

    struct Item: Mergeable, Identifiable, Equatable {
        struct Id: Hashable {
            var value: Int
        }

        var id: Id
        var title: String

        func merging(_ newValue: Item) -> Item {
            self.filled(from: newValue) { filledValue, oldValue in
                filledValue.title = newValue.title.isEmpty ? oldValue.title : newValue.title
            }
        }
    }

    struct AllItems: Reducible {
        var byId: [Item.Id: Item] = [:]

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidLoadItems<Item>:
                byId.insert(items: action.items)

            case let action as Actions.DidLoadItem<Item>:
                byId.insert(item: action.item)

            case let action as Actions.DidUpdateItem<Item>:
                byId.insert(item: action.item)

            case let action as Actions.DeleteItem<Item>:
                byId.removeValue(forKey: action.item.id)

            default:
                break
            }
        }
    }

    struct AppState: AppReducer {
        var allItems = AllItems()
    }

    func testItemMerging() async throws {
        let store = try await XCTestStore(initial: AppState())
        var item = Item(id: .init(value: 1), title: "original")
        await store.dispatch(Actions.DidLoadItem(item: item))

        let isEmpty = await store.state.allItems.byId.isEmpty

        XCTAssertEqual(isEmpty, false)
        item.title = "mutated"
        await store.dispatch(Actions.DidUpdateItem(item: item))

        var allItems = await store.state.allItems
        let storageItem = try XCTUnwrap(allItems.byId[item.id])

        XCTAssertEqual(item.title, storageItem.title)

        item.title = ""
        await store.dispatch(Actions.DidUpdateItem(item: item))
        allItems = await store.state.allItems

        let mergedItem = try XCTUnwrap(allItems.byId[item.id])
        XCTAssertEqual(mergedItem.title.isEmpty, false)
    }
}
