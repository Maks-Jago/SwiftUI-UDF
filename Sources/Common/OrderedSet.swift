//
//  OrderedSet.swift
//  
//
//  Created by Max Kuznetsov on 18.10.2020.
//

import Foundation

public extension OrderedSet {
    
    @available(*, deprecated, message: "Use `elements` property instead of contents")
    var contents: [Element] {
        self.elements
    }
}
