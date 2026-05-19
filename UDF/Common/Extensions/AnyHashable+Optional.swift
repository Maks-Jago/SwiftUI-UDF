//
//  AnyHashable+Optional.swift
//  SwiftUI-UDF
//
//  Created by Max Kuznetsov on 13.05.2026.
//

public extension AnyHashable? {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            true
        case let (.some(lhs), .some(rhs)):
            lhs == rhs
        default:
            false
        }
    }
}
