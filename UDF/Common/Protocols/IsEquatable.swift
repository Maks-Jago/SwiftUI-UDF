//
//  IsEquatable.swift
//
//
//  Created by Max Kuznetsov on 12.10.2021.
//

import Foundation

public protocol IsEquatable {
    func isEqual(_ rhs: IsEquatable) -> Bool
}

public extension IsEquatable where Self: Equatable {
    func isEqual(_ rhs: IsEquatable) -> Bool {
        guard let rhs = rhs as? Self else {
            return false
        }

        return self == rhs
    }
}
