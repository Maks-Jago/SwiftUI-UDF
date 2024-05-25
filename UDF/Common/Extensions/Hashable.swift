//
//  Hashable.swift
//  
//
//  Created by Max Kuznetsov on 18.10.2020.
//

import Foundation

public extension Hashable {
    static func ==(lhs: AnyHashable, rhs: Self) -> Bool {
        lhs == AnyHashable(rhs)
    }
}

public extension Hashable {
    static func ==(lhs: Self, rhs: AnyHashable) -> Bool {
        AnyHashable(lhs) == rhs
    }
}

public extension Hashable {
    static func ==(lhs: AnyHashable?, rhs: Self) -> Bool {
        switch lhs {
        case .some(let value):
            return value == rhs
            
        default:
            return false
        }
    }
}

public extension Hashable {
    static func ==(lhs: Self, rhs: AnyHashable?) -> Bool {
        switch rhs {
        case .some(let value):
            return lhs == value
            
        default:
            return false
        }
    }
}
