//
//  ReducerScope.swift
//  
//
//  Created by Max Kuznetsov on 07.11.2021.
//

import Foundation

final class ReducerScope<R: Reducible>: EquatableScope {
    static func == (lhs: ReducerScope<R>, rhs: ReducerScope<R>) -> Bool {
        lhs.reducer == rhs.reducer
    }

    var reducer: R?

    init(reducer: R?) {
        self.reducer = reducer
    }
}
