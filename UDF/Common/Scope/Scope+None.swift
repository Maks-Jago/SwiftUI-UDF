//
//  Scope+None.swift
//  
//
//  Created by Max Kuznetsov on 06.09.2023.
//

import Foundation

public extension Scope where Self == NoneScope {
    static var none: NoneScope {
        NoneScope()
    }
}

public struct NoneScope: EquatableScope {

    public func isEqual(_ rhs: IsEquatable) -> Bool { true }
}
