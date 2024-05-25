//
//  AppReducer.swift
//  
//
//  Created by Max Kuznetsov on 20.08.2021.
//

import Foundation

public protocol AppReducer: Equatable, Scope {}

//surmagic xcf
extension AppReducer {
    mutating func reduce(_ action: some Action) -> Bool {
        RuntimeReducing.reduce(action, reducer: &self)
    }

    mutating func initialSetup() {
        RuntimeReducing.initialSetup(reducer: &self)
    }
}
