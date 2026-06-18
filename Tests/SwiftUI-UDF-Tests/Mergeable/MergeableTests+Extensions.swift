@testable import UDF
import Testing
import OrderedCollections

extension MergeableTests {
    struct ModernItem: Mergeable, Equatable, Sendable {
        struct Id: Hashable, Sendable {
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

    @Test(arguments: [
        (
            newValue: ModernItem(id: .init(value: 1), title: "title", text: "text", number: 10.0, tags: ["tag1"], description: nil),
            oldValue: ModernItem(id: .init(value: 1), title: "title", text: "text", number: 0.0, tags: [], description: "old")
        ),
        (
            newValue: ModernItem(id: .init(value: 1), title: "title", text: "text", number: 0.0, tags: [], description: "new"),
            oldValue: ModernItem(id: .init(value: 1), title: "title", text: "text", number: 20.0, tags: ["tag2"], description: "old")
        ),
        (
            newValue: ModernItem(id: .init(value: 1), title: "title", text: "text", number: 30.0, tags: ["tag3"], description: "new"),
            oldValue: ModernItem(id: .init(value: 1), title: "title", text: "text", number: 0.0, tags: [], description: nil)
        ),
        (
            newValue: ModernItem(id: .init(value: 1), title: "title", text: "text", number: 0.0, tags: [], description: nil),
            oldValue: ModernItem(id: .init(value: 1), title: "title", text: "text", number: 0.0, tags: [], description: nil)
        ),
        (
            newValue: ModernItem(id: .init(value: 1), title: "title", text: "text", number: 30.0, tags: ["tag3"], description: "new"),
            oldValue: ModernItem(id: .init(value: 1), title: "title", text: "text", number: 20.0, tags: ["tag2"], description: "old")
        )
    ])
    func testMergeOverloadsComparedToTernary(newValue: ModernItem, oldValue: ModernItem) {
        // 1. Using key-path merge overloads
        var keyPathMerged = newValue
        keyPathMerged.merge(oldValue, \.description)
        keyPathMerged.merge(oldValue, \.tags)
        keyPathMerged.merge(oldValue, \.number, preserving: 0)

        // 2. Using traditional ternary / nil-coalescing equivalent logic
        var ternaryMerged = newValue
        ternaryMerged.description = newValue.description ?? oldValue.description
        ternaryMerged.tags = newValue.tags.isEmpty ? oldValue.tags : newValue.tags
        ternaryMerged.number = newValue.number == 0 ? oldValue.number : newValue.number

        #expect(keyPathMerged == ternaryMerged)
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

    struct TraceableItem: Mergeable, Identifiable, Equatable, Sendable {
        struct Id: Hashable, Sendable {
            var value: Int
        }

        var id: Id
        var mergeCount: Int = 0

        static func merging(_ filledValue: inout TraceableItem, new newValue: TraceableItem, old oldValue: TraceableItem) {
            filledValue.mergeCount = newValue.mergeCount + oldValue.mergeCount + 1
        }
    }

    @Test func testDictionaryInsertDoubleMerging() {
        var dict: [TraceableItem.Id: TraceableItem] = [:]
        let itemId = TraceableItem.Id(value: 1)
        
        // Initial insert when empty
        dict.insert(item: TraceableItem(id: itemId, mergeCount: 5))
        #expect(dict[itemId]?.mergeCount == 5)
        
        // Insert again to trigger merge
        dict.insert(item: TraceableItem(id: itemId, mergeCount: 2))
        
        // Expected single merge: newValue.mergeCount (2) + oldValue.mergeCount (5) + 1 = 8
        #expect(dict[itemId]?.mergeCount == 8)
    }

    @Test func testOrderedDictionaryInsertDoubleMerging() {
        var dict: OrderedDictionary<TraceableItem.Id, TraceableItem> = [:]
        let itemId = TraceableItem.Id(value: 1)
        
        // Initial insert when empty
        dict.insert(item: TraceableItem(id: itemId, mergeCount: 5))
        #expect(dict[itemId]?.mergeCount == 5)
        
        // Insert again to trigger merge
        dict.insert(item: TraceableItem(id: itemId, mergeCount: 2))
        
        // Expected single merge: newValue.mergeCount (2) + oldValue.mergeCount (5) + 1 = 8
        #expect(dict[itemId]?.mergeCount == 8)
    }
}
