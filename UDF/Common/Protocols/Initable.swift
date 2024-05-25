//
//  Initable.swift
//  
//
//  Created by Max Kuznetsov on 16.02.2021.
//

import Foundation

public protocol Initable {
    init()
}

extension Dictionary: Initable {}

extension Set: Initable {}

extension Array: Initable {}
