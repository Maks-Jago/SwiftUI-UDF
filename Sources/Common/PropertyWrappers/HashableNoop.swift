//
//  HashableNoop.swift
//  
//
//  Created by Max Kuznetsov on 05.08.2021.
//

import Foundation

@propertyWrapper
struct HashableNoop<Value: Equatable>: Hashable {
    var wrappedValue: Value

    init(wrappedValue value: Value) {
        self.wrappedValue = value
    }

    func hash(into hasher: inout Hasher) {}
}
