//
//  MergeableTests.swift
//
//
//  Created by Max Kuznetsov on 20.08.2021.
//

@testable import UDF
import Testing

@Suite
struct MergeableTests {
    struct Item: Mergeable, Equatable {
        struct Id: Hashable {
            var value: Int
        }

        var id: Id
        var title: String
        var text: String
        var number: Double

        static func merging(new newValue: Item, old oldValue: Item) -> Item {
            oldValue.filled(from: newValue) { filledValue, oldValue in
                filledValue.number = newValue.number == 0 ? oldValue.number : newValue.number
            }
        }
    }

    @Test func itemMerging() {
        var item = Item(id: .init(value: 1), title: "title 1", text: "text", number: 12.23)
        let item2 = Item(id: .init(value: 1), title: "title 2", text: "new text", number: 0)
        item = Item.merging(new: item2, old: item)

        #expect(item.title == "title 2")
        #expect(item.text == "new text")
        #expect(item.number > 0)
    }
}
