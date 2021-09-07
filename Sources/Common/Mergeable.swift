//
//  Mergeable.swift
//  
//
//  Created by Max Kuznetsov on 20.08.2021.
//

import Foundation
//import Runtime

//public extension Mergeable {
//    func filled(from value: Self, mutate: (_ filled: inout Self, _ old: Self) -> Void) -> Self {
//        var mutableSelf = self
//        do {
//            let info = try typeInfo(of: Self.self)
//
//            for property in info.properties {
//                let newValue = try property.get(from: value)
//                try property.set(value: newValue, on: &mutableSelf)
//            }
//
//        } catch {
//            return value
//        }
//
//        mutate(&mutableSelf, self)
//        return mutableSelf
//    }
//}
