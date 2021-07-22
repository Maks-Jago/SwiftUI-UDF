//
//  StateReducer.swift
//  
//
//  Created by Max Kuznetsov on 22.07.2021.
//

import Foundation

public struct StateReducer<State: Reducible> {

    public func callAsFunction(_ state: inout State, _ action: AnyAction) {
        #if DEBUG
        print("Reduce\t\t\t", action)
        print("---------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
        #endif
        state.reduce(action)
    }
}

public extension EnvironmentStore {
    convenience init(initial state: State) where State: Reducible {
        self.init(initial: state, reducer: StateReducer().callAsFunction(_:_:))
    }
}
