//
//  CacheSource.swift
//  
//
//  Created by Max Kuznetsov on 16.02.2021.
//

import Foundation

public protocol CacheSource {
    init(key: String)
    
    func save<T: Encodable>(_ value: T)
    func load<T: Decodable>() -> T?
    
    func remove()
}
