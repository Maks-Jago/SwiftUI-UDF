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
        values.forEach {
            set.append($0)
        }
        self[key] = set
    }
}
