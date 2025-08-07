//
//  CachedTests.swift
//  SwiftUI-UDFTests
//
//  Created by Max Kuznetsov on 30.03.2022.
//

import OrderedCollections
@testable import UDF
import UDFSwiftTesting
import Testing

private extension Actions {
    struct ResetCache: Action {}
}

@Suite(.serialized)
struct CachedTests {
    struct Item: Equatable, Codable, Identifiable {
        struct ID: Hashable, Codable, Equatable {
            var value: Int
        }

        var id: ID
    }

    struct AppState: AppReducer {
        var nestedForm = NestedForm()
    }

    struct NestedForm: Form {
        @Cached(key: "cached_test_items", defaultValue: .init())
        var items: OrderedSet<Item.ID>

        @Cached(key: "cached_test_selected_item", defaultValue: nil)
        var selectedItem: Item.ID?

        @Cached(key: "cached_test_items_by_id", defaultValue: [:])
        var byId: [Item.ID: Item]

        mutating func reduce(_ action: some Action) {
            switch action {
            case let action as Actions.DidLoadItems<Item>:
                items = OrderedSet(action.items.map(\.id))
                byId.insert(items: action.items)

            case is Actions.ResetCache:
                _items.reset()
                _selectedItem.reset()
                _byId.reset()

            case let action as Actions.DeleteItem<Item>:
                byId.removeValue(forKey: action.item.id)

            default:
                break
            }
        }
    }

    @Test func itemsCaching() async {
        // Clear only EnvironmentStore, not cache as this test specifically tests cache persistence
        var store = EnvironmentStore(initial: AppState(), loggers: [])

        let items = (0 ... 3).map { Item(id: .init(value: $0)) }
        store.dispatch(Actions.DidLoadItems(items: items, id: "items"))
        await fulfill(description: "waiting for cache action processing", sleep: 0.3)

        var isEmpty = store.state.nestedForm.items.isEmpty
        #expect(!isEmpty)

        var count = store.state.nestedForm.items.count
        #expect(count == 4)

        await fulfill(description: "waiting for cache syncing", sleep: 1.5)

        store = EnvironmentStore(initial: AppState(), loggers: [])
        isEmpty = store.state.nestedForm.items.isEmpty

        #expect(!isEmpty)
        count = store.state.nestedForm.items.count

        #expect(count == 4)
    }

    @Test func resetCache() async {
        let store = EnvironmentStore(initial: AppState(), loggers: [])
        let items = (0 ... 3).map { Item(id: .init(value: $0)) }
        store.dispatch(Actions.DidLoadItems(items: items, id: "items"))

        var isEmpty = store.state.nestedForm.items.isEmpty
        #expect(!isEmpty)

        let count = store.state.nestedForm.items.count
        #expect(count == 4)

        await fulfill(description: "waiting for cache syncing", sleep: 1.5)
        store.dispatch(Actions.ResetCache())
        await fulfill(description: "waiting for reset cache processing", sleep: 0.3)

        isEmpty = store.state.nestedForm.items.isEmpty
        #expect(isEmpty)
    }

    @Test func singleObjectCaching() async {
        let store = EnvironmentStore(initial: AppState(), loggers: [])

        var selectedItem = store.state.nestedForm.selectedItem
        #expect(selectedItem == nil)

        store.dispatch(Actions.UpdateFormField(keyPath: \NestedForm.selectedItem, value: .init(value: 1)))
        await fulfill(description: "waiting for field update processing", sleep: 0.3)

        selectedItem = store.state.nestedForm.selectedItem
        #expect(selectedItem != nil)

        store.dispatch(Actions.ResetCache())
        await fulfill(description: "waiting for reset cache processing", sleep: 0.3)

        selectedItem = store.state.nestedForm.selectedItem
        #expect(selectedItem == nil)
    }

    @Test func removeItemFromCacheById() async throws {
        let store = EnvironmentStore(initial: AppState(), loggers: [])
        store.dispatch(Actions.ResetCache())
        await fulfill(description: "waiting for cache reset", sleep: 0.3)

        let items = [Item(id: .init(value: 0))]
        store.dispatch(Actions.DidLoadItems(items: items, id: "items"))
        await fulfill(description: "waiting for items to load", sleep: 0.3)

        var isEmpty = store.state.nestedForm.byId.isEmpty
        #expect(!isEmpty)

        try store.dispatch(Actions.DeleteItem(item: #require(items.first)))
        await fulfill(description: "waiting for delete item processing", sleep: 0.3)
        isEmpty = store.state.nestedForm.byId.isEmpty

        #expect(isEmpty)
    }
}
