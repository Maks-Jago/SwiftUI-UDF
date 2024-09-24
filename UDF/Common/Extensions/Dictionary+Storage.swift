//
//  Dictionary+Storage.swift
//  
//
//  Created by Max Kuznetsov on 24.09.2021.
//

import Foundation

public extension Dictionary {
    mutating func append<V>(_ value: V, by key: Key) where Value == OrderedSet<V> {
        var set = self[key] ?? []
        set.append(value)
        self[key] = set
    }

    mutating func append<V>(_ values: [V], by key: Key) where Value == OrderedSet<V> {
        var set = self[key] ?? []
        set.append(contentsOf: values)
        self[key] = set
    }

    mutating func append<V: Identifiable>(_ value: V, by key: Key) where Value == OrderedSet<V.ID> {
        append(value.id, by: key)
    }

    mutating func append<V: Identifiable>(_ values: [V], by key: Key) where Value == OrderedSet<V.ID> {
        append(values.map(\.id), by: key)
    }
}

public extension Dictionary {
    mutating func append<VKey, VValue>(_ value: Value, by key: Key) where Value == Dictionary<VKey, VValue> {
        var dict: Value = self[key] ?? [:]
        dict.merge(dict: value)
        self[key] = dict
    }
}

public extension Dictionary {
    mutating func merge(dict: [Key: Value]){
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
}
