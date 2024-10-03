//===--- Dictionary+Storage.swift ------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

public extension Dictionary {
    
    /// Appends a value to an `OrderedSet` stored in the dictionary under the specified key.
    ///
    /// - Parameters:
    ///   - value: The value to append.
    ///   - key: The key under which the `OrderedSet` is stored.
    mutating func append<V>(_ value: V, by key: Key) where Value == OrderedSet<V> {
        var set = self[key] ?? []
        set.append(value)
        self[key] = set
    }
    
    /// Appends an array of values to an `OrderedSet` stored in the dictionary under the specified key.
    ///
    /// - Parameters:
    ///   - values: The array of values to append.
    ///   - key: The key under which the `OrderedSet` is stored.
    mutating func append<V>(_ values: [V], by key: Key) where Value == OrderedSet<V> {
        var set = self[key] ?? []
        set.append(contentsOf: values)
        self[key] = set
    }
    
    /// Appends an `Identifiable` value's `id` to an `OrderedSet` stored in the dictionary under the specified key.
    ///
    /// - Parameters:
    ///   - value: The `Identifiable` value to append.
    ///   - key: The key under which the `OrderedSet` of IDs is stored.
    mutating func append<V: Identifiable>(_ value: V, by key: Key) where Value == OrderedSet<V.ID> {
        append(value.id, by: key)
    }
    
    /// Appends an array of `Identifiable` values' `ids` to an `OrderedSet` stored in the dictionary under the specified key.
    ///
    /// - Parameters:
    ///   - values: The array of `Identifiable` values to append.
    ///   - key: The key under which the `OrderedSet` of IDs is stored.
    mutating func append<V: Identifiable>(_ values: [V], by key: Key) where Value == OrderedSet<V.ID> {
        append(values.map(\.id), by: key)
    }
}

public extension Dictionary {
    
    /// Appends a dictionary to a nested dictionary stored in the current dictionary under the specified key.
    ///
    /// - Parameters:
    ///   - value: The dictionary to append.
    ///   - key: The key under which the nested dictionary is stored.
    mutating func append<VKey, VValue>(_ value: Value, by key: Key) where Value == Dictionary<VKey, VValue> {
        var dict: Value = self[key] ?? [:]
        dict.merge(dict: value)
        self[key] = dict
    }
}

public extension Dictionary {
    
    /// Merges the given dictionary into the current dictionary, updating values for matching keys.
    ///
    /// - Parameter dict: The dictionary to merge.
    mutating func merge(dict: [Key: Value]) {
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
}
