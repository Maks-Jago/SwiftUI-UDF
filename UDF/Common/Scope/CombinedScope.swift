//
//  CombinedScope.swift
//  
//
//  Created by Max Kuznetsov on 07.11.2021.
//

import Foundation

final class CombinedScope<S1: EquatableScope, S2: EquatableScope>: EquatableScope {
    static func == (lhs: CombinedScope<S1, S2>, rhs: CombinedScope<S1, S2>) -> Bool {
        lhs.lhsScope == rhs.lhsScope && lhs.rhsScope == rhs.rhsScope
    }

    var lhsScope: S1
    var rhsScope: S2

    init(_ lhs: S1, _ rhs: S2) {
        lhsScope = lhs
        rhsScope = rhs
    }
}
