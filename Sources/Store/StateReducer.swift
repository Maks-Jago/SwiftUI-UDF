//
//  StateReducer.swift
//  
//
//  Created by Max Kuznetsov on 22.07.2021.
//

import Foundation

struct StateReducer<State: Reducible> {

    func callAsFunction(_ state: inout State, _ action: AnyAction) {
        #if DEBUG
        print("Reduce\t\t\t", action)
        print("---------------------------------------------------------------------------------------------------------------------------------------------------------------------------")
        #endif
        state.reduce(action)
    }
}

extension EnvironmentStore {
    convenience init(initial state: State) where State: Reducible {
        self.init(initial: state, reducer: StateReducer().callAsFunction(_:_:))
    }
}
