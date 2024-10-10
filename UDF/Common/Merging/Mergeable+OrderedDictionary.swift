//===--- OrderedDictionaryExtensions.swift -----------------------------------===//
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
import OrderedCollections

public extension OrderedDictionary where Value: Mergeable {
    
    subscript(key: Key) -> Value {
        get {
            preconditionFailure("You have to use optional subscript")
        }
        set {
            self.updateValue(self[key]?.merging(newValue) ?? newValue, forKey: key)
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
