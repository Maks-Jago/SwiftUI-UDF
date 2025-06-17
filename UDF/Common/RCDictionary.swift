//===--- RDDictionary.swift ------------------------------------===//
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

public struct RCDictionary<Key: Hashable & Sendable, Value: Initable & Equatable & Sendable>: Equatable, Sendable {
    private var keyValues: [Key: ReducerBox] = [:]

    mutating func retainOrCreateValue(for key: Key) {
        if keyValues[key] != nil {
            keyValues[key]?.retain()
        } else {
            keyValues[key] = .init(value: .init())
        }
    }

    mutating func release(key: Key) {
        if keyValues[key]?.release() == true {
            keyValues.removeValue(forKey: key)
        }
    }

    mutating func updateValue(_ value: Value, forKey key: Key) {
        var box = keyValues[key] ?? .init(value: value)
        box.value = value
        keyValues[key] = box
    }

    public subscript(_ key: Key) -> Value? {
        keyValues[key]?.value
    }
}

// MARK: - ReducerBox
public extension RCDictionary {
    struct ReducerBox: Equatable {
        var value: Value
        private var referenceCount: Int = 1

        init(value: Value) {
            self.value = value
        }

        mutating func retain() {
            referenceCount += 1
        }

        mutating func release() -> Bool {
            referenceCount -= 1
            return referenceCount <= 0
        }
    }
}

// MARK: - Collection
extension RCDictionary: Collection {
    public typealias Index = [Key: ReducerBox].Index
    public typealias Element = (key: Key, value: Value)

    /// The starting index of the collection, used in iterations.
    public var startIndex: Index { keyValues.startIndex }

    /// The ending index of the collection, used in iterations.
    public var endIndex: Index { keyValues.endIndex }

    /// Required subscript to access an element of the collection at the specified index.
    ///
    /// - Parameter index: The position in the collection.
    /// - Returns: The element at the specified index.
    public subscript(index: Index) -> Element {
        let element = keyValues[index]
        return (element.key, element.value.value)
    }

    /// Returns the next index in the collection.
    ///
    /// - Parameter i: The current index.
    /// - Returns: The index immediately after the given index.
    public func index(after i: Index) -> Index {
        keyValues.index(after: i)
    }
}

extension RCDictionary.ReducerBox: Sendable where Value: Sendable {}
