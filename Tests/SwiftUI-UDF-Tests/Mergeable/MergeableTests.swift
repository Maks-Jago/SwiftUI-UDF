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

    struct ModernItem: Mergeable, Equatable {
        struct Id: Hashable {
            var value: Int
        }

        var id: Id
        var title: String
        var text: String
        var number: Double
        var tags: [String]
        var description: String?

        static func merging(_ filledValue: inout ModernItem, new newValue: ModernItem, old oldValue: ModernItem) {
            filledValue.merge(oldValue, \.number, preserving: 0)
            filledValue.merge(oldValue, \.tags)
            filledValue.merge(oldValue, \.description)
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

    @Test func modernItemMerging() {
        let old = ModernItem(id: .init(value: 1), title: "title 1", text: "text", number: 12.23, tags: ["swift", "udf"], description: "Hello")
        let new = ModernItem(id: .init(value: 1), title: "title 2", text: "new text", number: 0, tags: [], description: nil)

        // Test static method directly
        var mergedStatic = new
        ModernItem.merging(&mergedStatic, new: new, old: old)
        #expect(mergedStatic.title == "title 2")       // Auto-merged (overwritten)
        #expect(mergedStatic.text == "new text")       // Auto-merged (overwritten)
        #expect(mergedStatic.number == 12.23)          // Merged using KeyPath preserving 0
        #expect(mergedStatic.tags == ["swift", "udf"]) // Merged using KeyPath preserving empty
        #expect(mergedStatic.description == "Hello")   // Merged using KeyPath preserving nil

        // Test instance method (calls default forwarding implementation to static method)
        let mergedInstance = old.merging(new)
        #expect(mergedInstance.title == "title 2")
        #expect(mergedInstance.text == "new text")
        #expect(mergedInstance.number == 12.23)
        #expect(mergedInstance.tags == ["swift", "udf"])
        #expect(mergedInstance.description == "Hello")

        #expect(mergedStatic == mergedInstance)
    }

    @Test func legacyItemBackwardsCompatibility() {
        let old = Item(id: .init(value: 1), title: "title 1", text: "text", number: 12.23)
        let new = Item(id: .init(value: 1), title: "title 2", text: "new text", number: 0)

        // Test static method (calls default forwarding implementation to legacy instance method)
        var mergedStatic = new
        Item.merging(&mergedStatic, new: new, old: old)
        #expect(mergedStatic.title == "title 2")
        #expect(mergedStatic.text == "new text")
        #expect(mergedStatic.number == 12.23)

        // Verify it matches direct instance merging
        let mergedInstance = old.merging(new)
        #expect(mergedStatic == mergedInstance)
    }
}
