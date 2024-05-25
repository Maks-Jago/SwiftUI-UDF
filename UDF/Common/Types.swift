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
public typealias CommandWith2<T1, T2> = (T1, T2) -> ()
public typealias CommandWith3<T1, T2, T3> = (T1, T2, T3) -> ()
public typealias CommandWith4<T1, T2, T3, T4> = (T1, T2, T3, T4) -> ()
public typealias CommandWith5<T1, T2, T3, T4, T5> = (T1, T2, T3, T4, T5) -> ()

func areEqual<Lhs: Equatable, Rhs: Equatable>(_ lhs: Lhs, _ rhs: Rhs) -> Bool {
    guard let rhsAs = rhs as? Lhs else {
        return false
    }

    return lhs == rhsAs
}
