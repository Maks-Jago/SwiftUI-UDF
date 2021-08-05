//
//  EquatableNoop.swift
//  
//
//  Created by Max Kuznetsov on 05.08.2021.
//

import Foundation

@propertyWrapper
struct EquatableNoop<Value>: Equatable {
    var wrappedValue: Value

    static func == (lhs: EquatableNoop<Value>, rhs: EquatableNoop<Value>) -> Bool { true }
}
