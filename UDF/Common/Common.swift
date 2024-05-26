//
//  Common.swift
//  
//
//  Created by Max Kuznetsov on 07.09.2023.
//

import Foundation

public func useStore<State: AppReducer>(_ stateType: State.Type, _ useBlock: @escaping (_ store: EnvironmentStore<State>) -> Void) {
    useBlock(EnvironmentStore<State>.global)
}
