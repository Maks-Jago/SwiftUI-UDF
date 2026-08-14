import OrderedCollections
import Testing
@testable import UDF

@Suite struct StorageTests {
    
    @Test("Storage reduces entity actions with Dictionary")
    func storageReducesEntityActionsWithDictionary() {
        validateStorage(for: AllItemsDictionary())
    }

    @Test("Storage reduces entity actions with OrderedDictionary")
    func storageReducesEntityActionsWithOrderedDictionary() {
        validateStorage(for: AllItemsOrderedDictionary())
    }

    private func validateStorage<S: Storage>(for storage: S) where S.Entity == Item {
        var storage = storage

        let apple = Item(id: .init(value: 1), name: "apple")
        let pineapple = Item(id: .init(value: 2), name: "pineapple")
        let strawberry = Item(id: .init(value: 3), name: "strawberry")
        let updatedPineapple = Item(id: pineapple.id, name: "updated pineapple")
        let missingId = Item.ID(value: 99)

        storage.reduce(Actions.DidLoadItems(items: [apple, pineapple, strawberry], id: "items"))
        #expect(storage.byId.count == 3, "Storage should contain all loaded items")
        #expect(storage[apple.id] == apple, "Storage should return the inserted apple by subscript")
        #expect(storage.by(id: pineapple.id) == pineapple, "Storage should return the inserted pineapple by id")

        storage.reduce(Actions.DidUpdateItem(item: updatedPineapple))
        #expect(storage.byId.count == 3, "Updating an item should not change storage count")
        #expect(storage[pineapple.id] == updatedPineapple, "Storage should keep the updated pineapple value")

        storage.reduce(Actions.DeleteItem(item: strawberry))
        #expect(storage.byId.count == 2, "Deleting an item should reduce storage count by one")
        #expect(storage[strawberry.id] == nil, "Deleted item should no longer be available in storage")
    }
}

private struct AllItemsDictionary: Storage {
    var byId: [Item.ID: Item] = [:]

    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.DidLoadItems<Item>:
            byId.insert(items: action.items)

        case let action as Actions.DidLoadItem<Item>:
            byId.insert(item: action.item)

        case let action as Actions.DidUpdateItem<Item>:
            byId[action.item.id] = action.item

        case let action as Actions.DeleteItem<Item>:
            byId.removeValue(forKey: action.item.id)

        default:
            break
        }
    }
}

private struct AllItemsOrderedDictionary: Storage {
    var byId: OrderedDictionary<Item.ID, Item> = [:]

    mutating func reduce(_ action: some Action) {
        switch action {
        case let action as Actions.DidLoadItems<Item>:
            byId.insert(items: action.items)

        case let action as Actions.DidLoadItem<Item>:
            byId.insert(item: action.item)

        case let action as Actions.DidUpdateItem<Item>:
            byId[action.item.id] = action.item

        case let action as Actions.DeleteItem<Item>:
            byId.removeValue(forKey: action.item.id)

        default:
            break
        }
    }
}

private struct Item: Identifiable, Equatable, Sendable, EmptyValue {
    let id: ID
    let name: String

    struct ID: Hashable, Sendable {
        let value: Int
    }
    
    static var empty: Self {
        .init(
            id: .init(value: 0),
            name: ""
        )
    }
}
