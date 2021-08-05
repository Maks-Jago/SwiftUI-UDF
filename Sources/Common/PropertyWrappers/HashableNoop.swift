//
//  HashableNoop.swift
//  
//
//  Created by Max Kuznetsov on 05.08.2021.
//

import Foundation

@propertyWrapper
public struct HashableNoop<Value: Equatable>: Hashable {
    public var wrappedValue: Value

    public init(wrappedValue value: Value) {
        self.wrappedValue = value
    }

    public func hash(into hasher: inout Hasher) {}
}
