//===--- CacheSource.swift -----------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

/// `CacheSource` is a protocol that defines the interface for caching data.
/// Implementing types must provide mechanisms to save, load, and remove cached data.
public protocol CacheSource {
    
    /// Initializes a cache source with a unique key.
    ///
    /// - Parameter key: A unique key used to identify the cached data.
    init(key: String)
    
    /// Saves an encodable value to the cache.
    ///
    /// - Parameter value: The value to be saved, which must conform to the `Encodable` protocol.
    func save<T: Encodable>(_ value: T)
    
    /// Loads a decodable value from the cache.
    ///
    /// - Returns: An optional value of type `T` that conforms to the `Decodable` protocol. Returns `nil` if the value could not be loaded or decoded.
    func load<T: Decodable>() -> T?
    
    /// Removes the cached data.
    func remove()
}
