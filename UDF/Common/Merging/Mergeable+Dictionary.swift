
import Foundation

public extension Dictionary where Value: Mergeable {

    subscript(key: Key) -> Value {
        get {
            preconditionFailure("You have to use optional subscript")
        }
        set {
            self[key] = self[key]?.merging(newValue) ?? newValue
        }
    }
}

public extension Dictionary where Value: Identifiable, Key == Value.ID {

    mutating func insert(items: [Value]) {
        items.forEach { item in
            self[item.id] = item
        }
    }

    mutating func insert(item: Value) {
        self[item.id] = item
    }
}

public typealias MI = Mergeable & Identifiable
public extension Dictionary where Value: MI, Key == Value.ID {

    mutating func insert(items: [Value]) {
        items.forEach { item in
            self[item.id] = self[item.id]?.merging(item) ?? item
        }
    }

    mutating func insert(item: Value) {
        self[item.id] = self[item.id]?.merging(item) ?? item
    }
}


