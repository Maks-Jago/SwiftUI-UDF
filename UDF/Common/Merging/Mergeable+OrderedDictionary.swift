
import Foundation
import OrderedCollections

public extension OrderedDictionary where Value: Mergeable {

    subscript(key: Key) -> Value {
        get {
            preconditionFailure("You have to use optional subscript")
        }
        set {
            self[key] = self[key]?.merging(newValue) ?? newValue
        }
    }
}

public extension OrderedDictionary where Value: Identifiable, Key == Value.ID {

    mutating func insert(items: [Value]) {
        items.forEach { item in
            self[item.id] = item
        }
    }

    mutating func insert(item: Value) {
        self[item.id] = item
    }
}

public typealias OMI = Mergeable & Identifiable
public extension OrderedDictionary where Value: MI, Key == Value.ID {

    mutating func insert(items: [Value]) {
        items.forEach { item in
            self[item.id] = self[item.id]?.merging(item) ?? item
        }
    }

    mutating func insert(item: Value) {
        self[item.id] = self[item.id]?.merging(item) ?? item
    }
}
