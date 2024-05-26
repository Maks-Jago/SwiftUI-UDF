//
//  Reducing.swift
//  
//
//  Created by Max Kuznetsov on 20.08.2021.
//

import Foundation

public protocol Reducing: Initable, IsEquatable {
    mutating func reduce(_ action: some Action)
}

extension Reducing {
    mutating public func reduce(_ action: some Action) {}
}

public typealias Reducible = Reducing & Equatable
