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
        var store = await TestStore(initial: AppState())
        await store.dispatch(Actions.ResetCache())

        await sleep(1.1) // Wait for cache sync interval (default 1.0s) to complete

        var success = await waitForAsyncCondition { await store.state.nestedForm.items.isEmpty }
        #expect(success)

        let items = (0 ... 3).map { Item(id: .init(value: $0)) }
        await store.dispatch(Actions.DidLoadItems(items: items, id: "items"))

        success = await waitForAsyncCondition { await !store.state.nestedForm.items.isEmpty }
        #expect(success)

        success = await waitForAsyncCondition { await store.state.nestedForm.items.count == 4 }
        #expect(success)

        await sleep(1.1) // Wait for cache sync interval (default 1.0s) to complete

        store = await TestStore(initial: AppState())

        success = await waitForAsyncCondition { await !store.state.nestedForm.items.isEmpty }
        #expect(success)
        #expect(await store.state.nestedForm.items.count == 4)

        await store.dispatch(Actions.ResetCache())

        await sleep(1.1) // Wait for cache sync interval (default 1.0s) to complete

        success = await waitForAsyncCondition { await store.state.nestedForm.items.isEmpty }
        #expect(success)
    }

    @Test func singleObjectCaching() async {
        let store = await TestStore(initial: AppState())
        await store.dispatch(Actions.ResetCache())

        await sleep(1.1) // Wait for cache sync interval (default 1.0s) to complete

        var success = await waitForAsyncCondition { await store.state.nestedForm.selectedItem == nil }
        #expect(success)

        await store.dispatch(Actions.UpdateFormField(keyPath: \NestedForm.selectedItem, value: .init(value: 1)))
        success = await waitForAsyncCondition { await store.state.nestedForm.selectedItem != nil }
        #expect(success)

        await store.dispatch(Actions.ResetCache())
        success = await waitForAsyncCondition { await store.state.nestedForm.selectedItem == nil }
        #expect(success)
    }

    @Test func removeItemFromCacheById() async throws {
        let store = await TestStore(initial: AppState())
        await store.dispatch(Actions.ResetCache())

        await sleep(1.1) // Wait for cache sync interval (default 1.0s) to complete

        var success = await waitForAsyncCondition { await store.state.nestedForm.byId.isEmpty }
        #expect(success)

        let items = [Item(id: .init(value: 0))]
        await store.dispatch(Actions.DidLoadItems(items: items, id: "items"))
        success = await waitForAsyncCondition { await !store.state.nestedForm.byId.isEmpty }
        #expect(success)

        try await store.dispatch(Actions.DeleteItem(item: #require(items.first)))
        success = await waitForAsyncCondition { await store.state.nestedForm.byId.isEmpty }
        #expect(success)
    }
}
