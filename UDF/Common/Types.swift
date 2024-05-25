//
//  Types.swift
//
//
//  Created by Max Kuznetsov on 18.10.2020.
//

import Foundation
@_exported import OrderedCollections

public typealias Command = () -> ()
public typealias CommandWith<T> = (T) -> ()

func areEqual<Lhs: Equatable, Rhs: Equatable>(_ lhs: Lhs, _ rhs: Rhs) -> Bool {
    guard let rhsAs = rhs as? Lhs else {
        return false
    }

    return lhs == rhsAs
}
