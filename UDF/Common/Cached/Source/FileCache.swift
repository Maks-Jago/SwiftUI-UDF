//===--- FileCache.swift -----------------------------------------------===//
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

/// `FileCache` is responsible for managing cached data in a specified directory within the app's document directory.
public struct FileCache {
    
    /// The `FileManager` instance used to interact with the file system.
    public var fileManager: FileManager
    
    /// The name of the directory where cached data will be stored.
    public var directoryName: String
    
    /// The unique key associated with this cache instance.
    public var key: String
    
    /// The dispatch queue used for file operations.
    private var queue: DispatchQueue
    
    /// Initializes a new `FileCache` with the given key, using the default `FileManager` and directory name.
    ///
    /// - Parameter key: The unique key associated with this cache instance.
    public init(key: String) {
        self.queue = DispatchQueue(
            label: key,
            qos: .userInitiated,
            attributes: .concurrent,
            autoreleaseFrequency: .workItem
        )
        self.key = key
        self.fileManager = .default
        self.directoryName = "StateData"
    }
    
    /// Initializes a new `FileCache` with the given key, file manager, and directory name.
    ///
    /// - Parameters:
    ///   - key: The unique key associated with this cache instance.
    ///   - fileManager: The `FileManager` instance to use for file operations. Defaults to `.default`.
    ///   - directoryName: The name of the directory where cached data will be stored. Defaults to `"StateData"`.
    public init(key: String, fileManager: FileManager = .default, directoryName: String = "StateData") {
        self.queue = DispatchQueue(
            label: key,
            qos: .userInitiated,
            attributes: .concurrent,
            autoreleaseFrequency: .workItem
        )
        self.key = key
        self.fileManager = fileManager
        self.directoryName = directoryName
    }
    
    /// Returns the URL for the specified key within the cache directory.
    ///
    /// - Parameter key: The key for which to retrieve the URL.
    /// - Returns: An optional `URL` representing the path to the cached data.
    private func url(for key: String) -> URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(directoryName)
            .appendingPathComponent(key)
    }
}

/// Extension of `FileCache` to conform to the `CacheSource` protocol.
/// This implementation provides methods to save, load, and remove cache data using the file system.
extension FileCache: CacheSource {
    
    /// Saves an encodable value to the cache asynchronously using a barrier flag to ensure thread safety.
    ///
    /// - Parameter value: The value to be saved, which must conform to the `Encodable` protocol.
    public func save<T>(_ value: T) where T: Encodable {
        queue.async(flags: .barrier) {
            guard let data = try? JSONEncoder().encode(value) else {
                return
            }
            
            guard let url = url(for: key) else {
                return
            }
            
            do {
                // Create the directory if it doesn't exist
                try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                // Write the encoded data to the specified URL
                try data.write(to: url)
            } catch {
                print(error)
            }
        }
    }
    
    /// Loads a decodable value from the cache.
    ///
    /// - Returns: An optional value of type `T` that conforms to the `Decodable` protocol. Returns `nil` if the value could not be loaded or decoded.
    public func load<T>() -> T? where T: Decodable {
        guard let url = url(for: key) else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    /// Removes the cached data from the file system.
    public func remove() {
        guard let url = url(for: key) else {
            return
        }
        
        try? fileManager.removeItem(at: url)
    }
}
