//
//  CachedTests.swift
//  SwiftUI-UDFTests
//
//  Created by Max Kuznetsov on 30.03.2022.
//

import OrderedCollections
@testable import UDF
import UDFXCTest
import XCTest

private extension Actions {
    struct ResetCache: Action {}
}

class CachedTests: XCTestCase {
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
        @Cached(key: "items", defaultValue: .init())
        var items: OrderedSet<Item.ID>

        @Cached(key: "selected_item", defaultValue: nil)
        var selectedItem: Item.ID?

        @Cached(key: "items_by_id", defaultValue: [:])
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

    func testItemsCaching() async {
        var store = await XCTestStore(initial: AppState())

        let items = (0 ... 3).map { Item(id: .init(value: $0)) }
        await store.dispatch(Actions.DidLoadItems(items: items, id: "items"))

        var isEmpty = await store.state.nestedForm.items.isEmpty
        XCTAssertFalse(isEmpty)

        var count = await store.state.nestedForm.items.count
        XCTAssertEqual(count, 4)

        await fulfill(description: "waiting for cache syncing", sleep: 1.5)

        store = await .init(initial: AppState())
        isEmpty = await store.state.nestedForm.items.isEmpty

        XCTAssertFalse(isEmpty)
        count = await store.state.nestedForm.items.count

        XCTAssertEqual(count, 4)
    }

    func testResetCache() async {
        let store = await XCTestStore(initial: AppState())
        let items = (0 ... 3).map { Item(id: .init(value: $0)) }
        await store.dispatch(Actions.DidLoadItems(items: items, id: "items"))

        var isEmpty = await store.state.nestedForm.items.isEmpty
        XCTAssertFalse(isEmpty)

        let count = await store.state.nestedForm.items.count
        XCTAssertEqual(count, 4)

        await fulfill(description: "waiting for cache syncing", sleep: 1.5)
        await store.dispatch(Actions.ResetCache())

        isEmpty = await store.state.nestedForm.items.isEmpty
        XCTAssertTrue(isEmpty)
    }

    func testSingleObjectCaching() async {
        let store = await XCTestStore(initial: AppState())

        var selectedItem = await store.state.nestedForm.selectedItem
        XCTAssertNil(selectedItem)

        await store.dispatch(Actions.UpdateFormField(keyPath: \NestedForm.selectedItem, value: .init(value: 1)))

        selectedItem = await store.state.nestedForm.selectedItem
        XCTAssertNotNil(selectedItem)

        await store.dispatch(Actions.ResetCache())

        selectedItem = await store.state.nestedForm.selectedItem
        XCTAssertNil(selectedItem)
    }

    func testRemoveItemFromCacheById() async throws {
        let store = await XCTestStore(initial: AppState())
        await store.dispatch(Actions.ResetCache())

        let items = [Item(id: .init(value: 0))]
        await store.dispatch(Actions.DidLoadItems(items: items, id: "items"))

        var isEmpty = await store.state.nestedForm.byId.isEmpty
        XCTAssertFalse(isEmpty)

        try await store.dispatch(Actions.DeleteItem(item: XCTUnwrap(items.first)))
        isEmpty = await store.state.nestedForm.byId.isEmpty

        XCTAssertTrue(isEmpty)
    }
}
