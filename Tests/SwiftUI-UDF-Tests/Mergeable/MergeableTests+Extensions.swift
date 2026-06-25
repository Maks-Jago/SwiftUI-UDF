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

        static func merging(new newValue: ModernItem, old oldValue: ModernItem) -> ModernItem {
            newValue
                .keeping(\.number, from: oldValue, where: newValue.number == 0)
                .keeping(\.tags, from: oldValue, where: newValue.tags.isEmpty)
                .keeping(\.description, from: oldValue, where: newValue.description == nil)

                // Custom Rule: Keep title if the new title is shorter than 3 characters
                .keeping(\.title, from: oldValue, where: newValue.title.count < 3)
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
    func testKeepOverloadsComparedToTernary(newValue: ModernItem, oldValue: ModernItem) {
        // 1. Using key-path keeping overload
        let keyPathKept = newValue
            .keeping(\.description, from: oldValue, where: newValue.description == nil)
            .keeping(\.tags, from: oldValue, where: newValue.tags.isEmpty)
            .keeping(\.number, from: oldValue, where: newValue.number == 0)

        // 2. Using traditional ternary / nil-coalescing equivalent logic
        var ternaryMerged = newValue
        ternaryMerged.description = newValue.description ?? oldValue.description
        ternaryMerged.tags = newValue.tags.isEmpty ? oldValue.tags : newValue.tags
        ternaryMerged.number = newValue.number == 0 ? oldValue.number : newValue.number

        #expect(keyPathKept == ternaryMerged)
    }

    @Test func testKeepCustomCondition() {
        let old = ModernItem(id: .init(value: 1), title: "Original Title", text: "Original Text", number: 5, tags: [], description: nil)
        
        // Custom Rule 1: Keep if new title is shorter than old
        let temp1 = ModernItem(id: .init(value: 1), title: "Short", text: "New Text", number: 10, tags: [], description: nil)
        let new1 = temp1.keeping(\.title, from: old, where: temp1.title.count < old.title.count)
        #expect(new1.title == "Original Title")

        // Custom Rule 2: Do NOT keep if new title is longer or equal
        let temp2 = ModernItem(id: .init(value: 1), title: "Very Long New Title", text: "New Text", number: 10, tags: [], description: nil)
        let new2 = temp2.keeping(\.title, from: old, where: temp2.title.count < old.title.count)
        #expect(new2.title == "Very Long New Title")
    }

    @Test func modernItemMerging() {
        let old = ModernItem(id: .init(value: 1), title: "title 1", text: "text", number: 12.23, tags: ["swift", "udf"], description: "Hello")
        let new = ModernItem(id: .init(value: 1), title: "title 2", text: "new text", number: 0, tags: [], description: nil)

        // Test static method directly
        let mergedStatic = ModernItem.merging(new: new, old: old)
        #expect(mergedStatic.title == "title 2")
        #expect(mergedStatic.text == "new text")
        #expect(mergedStatic.number == 12.23)
        #expect(mergedStatic.tags == ["swift", "udf"])
        #expect(mergedStatic.description == "Hello")

        // Test instance method (calls default forwarding implementation to static method)
        let mergedInstance = old.merging(new)
        #expect(mergedInstance.title == "title 2")
        #expect(mergedInstance.text == "new text")
        #expect(mergedInstance.number == 12.23)
        #expect(mergedInstance.tags == ["swift", "udf"])
        #expect(mergedInstance.description == "Hello")

        #expect(mergedStatic == mergedInstance)

        // Test the custom rule in modern merging:
        // New title is "hi" (length 2 < 3) -> should keep "title 1"
        let newShortTitle = ModernItem(id: .init(value: 1), title: "hi", text: "new text", number: 0, tags: [], description: nil)
        let mergedShort = ModernItem.merging(new: newShortTitle, old: old)
        #expect(mergedShort.title == "title 1")

        // Verifying it also works via instance method forwarding
        let mergedShortInstance = old.merging(newShortTitle)
        #expect(mergedShortInstance.title == "title 1")
    }

    @Test func legacyItemBackwardsCompatibility() {
        let old = Item(id: .init(value: 1), title: "title 1", text: "text", number: 12.23)
        let new = Item(id: .init(value: 1), title: "title 2", text: "new text", number: 0)

        // Test static method (calls default forwarding implementation to legacy instance method)
        let mergedStatic = Item.merging(new: new, old: old)
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

        static func merging(new newValue: TraceableItem, old oldValue: TraceableItem) -> TraceableItem {
            var copy = newValue
            copy.mergeCount = newValue.mergeCount + oldValue.mergeCount + 1
            return copy
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

    @Test(arguments: [
        (newTitle: "a", oldTitle: "Original", expected: "Original"),
        (newTitle: "ab", oldTitle: "Original", expected: "Original"),
        (newTitle: "", oldTitle: "Original", expected: "Original"),
        (newTitle: "abc", oldTitle: "Original", expected: "abc"),
        (newTitle: "abcd", oldTitle: "Original", expected: "abcd"),
        (newTitle: "  ", oldTitle: "Original", expected: "Original"),
        (newTitle: "   ", oldTitle: "Original", expected: "   "),
        (newTitle: "ab", oldTitle: "xy", expected: "xy")
    ])
    func testModernItemCustomTitleKeepRule(newTitle: String, oldTitle: String, expected: String) {
        let old = ModernItem(id: .init(value: 1), title: oldTitle, text: "original text", number: 4.5, tags: ["t1"], description: "desc")
        let new = ModernItem(id: .init(value: 1), title: newTitle, text: "new text", number: 0, tags: [], description: nil)
        
        // Test static merging function directly
        let merged = ModernItem.merging(new: new, old: old)
        
        #expect(merged.title == expected)
        // Ensure other fields were still merged correctly according to their keep rules:
        #expect(merged.text == "new text")
        #expect(merged.number == 4.5)
        #expect(merged.tags == ["t1"])
        #expect(merged.description == "desc")
    }
}

