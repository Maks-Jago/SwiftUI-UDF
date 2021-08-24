//
//  MergeableTests.swift
//  
//
//  Created by Max Kuznetsov on 20.08.2021.
//

import XCTest
@testable import SwiftUI_UDF

class MergeableTests: XCTestCase {

    struct AllItems {
        var byId: [Item.Id: Item] = [ :
//            .init(value: 1) : Item(id: .init(value: 1), title: "title 1", text: "text", number: 12.23)
        ]

        mutating func reduce(_ action: AnyAction) {
            switch action.value {
            case let action as Actions.DidLoadItems<Item>:
                action.items.forEach {
                    byId[$0.id] = $0
                }

            case let action as Actions.DidLoadItem<Item>:
                byId[action.item.id] = action.item

            case let action as Actions.DidUpdateItem<Item>:
                byId[action.item.id] = action.item

            case let action as Actions.DeleteItem<Item>:
                byId.removeValue(forKey: action.item.id)

            default:
                break
            }
        }
    }

    var allItems = AllItems()

//    var byId: [Item.Id: Item] = [
//        .init(value: 1) : Item(id: .init(value: 1), title: "title 1", text: "text", number: 12.23)
//    ]

    struct Item: Mergeable, Equatable {
        struct Id: Hashable {
            var value: Int
        }

        var id: Id
        var title: String
        var text: String
        var number: Double

        func merging(_ newValue: Item) -> Item {
            self.filled(from: newValue) { filledValue, oldValue in
                filledValue.number = newValue.number == 0 ? oldValue.number : newValue.number
            }
        }
    }

    func testItemMerging() {
        allItems.reduce(Actions.DidLoadItem(item: Item(id: .init(value: 1), title: "title 1", text: "text", number: 12.23)).eraseToAnyAction())
        let item2 = Item(id: .init(value: 1), title: "title 2", text: "new text", number: 0)


        allItems.reduce(Actions.DidUpdateItem(item: item2).eraseToAnyAction())
//        byId[item2.id] = item2

        XCTAssertEqual(allItems.byId[item2.id]!.title, "title 2")
        XCTAssertEqual(allItems.byId[item2.id]!.text, "new text")
        XCTAssertTrue(allItems.byId[item2.id]!.number > 0)
    }
}
