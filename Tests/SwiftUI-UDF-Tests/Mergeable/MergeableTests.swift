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

        func merging(_ newValue: Item) -> Item {
            self.filled(from: newValue) { filledValue, oldValue in
                filledValue.number = newValue.number == 0 ? oldValue.number : newValue.number
            }
        }
    }

    @Test func itemMerging() {
        var item = Item(id: .init(value: 1), title: "title 1", text: "text", number: 12.23)
        let item2 = Item(id: .init(value: 1), title: "title 2", text: "new text", number: 0)
        item = item.merging(item2)

        #expect(item.title == "title 2")
        #expect(item.text == "new text")
        #expect(item.number > 0)
    }
}
