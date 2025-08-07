@testable import UDF
import UDFSwiftTesting
import Testing

@Suite
struct MergeableAppStateTests {
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

    @Test func itemMerging() async throws {
        let store = EnvironmentStore(initial: AppState(), loggers: [])
        var item = Item(id: .init(value: 1), title: "original")
        store.dispatch(Actions.DidLoadItem(item: item))
        await fulfill(description: "waiting for action processing", sleep: 0.3)

        let isEmpty = store.state.allItems.byId.isEmpty

        #expect(isEmpty == false)
        item.title = "mutated"
        store.dispatch(Actions.DidUpdateItem(item: item))
        await fulfill(description: "waiting for action processing", sleep: 0.3)

        var allItems = store.state.allItems
        let storageItem = try #require(allItems.byId[item.id])

        #expect(item.title == storageItem.title)

        item.title = ""
        store.dispatch(Actions.DidUpdateItem(item: item))
        await fulfill(description: "waiting for action processing", sleep: 0.3)
        allItems = store.state.allItems

        let mergedItem = try #require(allItems.byId[item.id])
        #expect(mergedItem.title.isEmpty == false)
    }
}
