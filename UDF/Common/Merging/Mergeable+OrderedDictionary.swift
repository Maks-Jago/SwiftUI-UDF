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
            var filled = newValue
            if let old = self[key] {
                Value.merging(&filled, old: old)
            }
            self.updateValue(filled, forKey: key)
        }
    }
}

public extension OrderedDictionary where Value: Identifiable, Key == Value.ID {
    mutating func insert(items: [Value]) {
        for item in items {
            self[item.id] = item
        }
    }

    mutating func insert(item: Value) {
        self[item.id] = item
    }
}

public typealias OMI = Identifiable & Mergeable
public extension OrderedDictionary where Value: MI, Key == Value.ID {
    mutating func insert(items: [Value]) {
        for item in items {
            var filled = item
            if let old = self[item.id] {
                Value.merging(&filled, old: old)
            }
            self.updateValue(filled, forKey: item.id)
        }
    }

    mutating func insert(item: Value) {
        var filled = item
        if let old = self[item.id] {
            Value.merging(&filled, old: old)
        }
        self.updateValue(filled, forKey: item.id)
    }
}
