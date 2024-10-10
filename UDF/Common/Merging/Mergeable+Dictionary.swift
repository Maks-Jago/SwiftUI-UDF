//===--- Mergeable+Dictionary.swift -------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

public extension Dictionary where Value: Mergeable {
    
    /// A subscript that merges a new value with the existing value for a given key.
    ///
    /// - Parameter key: The key associated with the value in the dictionary.
    /// - Returns: The merged value if it exists, otherwise a new value.
    /// - Warning: This subscript is not meant for direct retrieval and will trigger a precondition failure.
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
    
    /// Inserts an array of identifiable items into the dictionary.
    ///
    /// - Parameter items: An array of items to be inserted into the dictionary.
    ///                    If an item already exists, it will be replaced.
    mutating func insert(items: [Value]) {
        items.forEach { item in
            self[item.id] = item
        }
    }
    
    /// Inserts a single identifiable item into the dictionary.
    ///
    /// - Parameter item: The item to be inserted into the dictionary.
    ///                   If an item with the same ID already exists, it will be replaced.
    mutating func insert(item: Value) {
        self[item.id] = item
    }
}

public typealias MI = Mergeable & Identifiable

public extension Dictionary where Value: MI, Key == Value.ID {
    
    /// Inserts an array of mergeable and identifiable items into the dictionary.
    ///
    /// - Parameter items: An array of items to be inserted into the dictionary.
    ///                    If an item with the same ID already exists, it will be merged with the new item.
    mutating func insert(items: [Value]) {
        items.forEach { item in
            self[item.id] = self[item.id]?.merging(item) ?? item
        }
    }
    
    /// Inserts a single mergeable and identifiable item into the dictionary.
    ///
    /// - Parameter item: The item to be inserted into the dictionary.
    ///                   If an item with the same ID already exists, it will be merged with the new item.
    mutating func insert(item: Value) {
        self[item.id] = self[item.id]?.merging(item) ?? item
    }
}
