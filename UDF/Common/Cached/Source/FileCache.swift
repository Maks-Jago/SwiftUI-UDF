//
//  FileCache.swift
//  
//
//  Created by Max Kuznetsov on 16.02.2021.
//

import Foundation

public struct FileCache {
    public var fileManager: FileManager
    public var directoryName: String
    public var key: String
    
    private var queue: DispatchQueue
    
    public init(key: String) {
        self.queue = DispatchQueue(label: key, qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .workItem)
        self.key = key
        self.fileManager = .default
        self.directoryName = "StateData"
    }
    
    public init(key: String, fileManager: FileManager = .default, directoryName: String = "StateData") {
        self.queue = DispatchQueue(label: key, qos: .userInitiated, attributes: .concurrent, autoreleaseFrequency: .workItem)
        self.key = key
        self.fileManager = fileManager
        self.directoryName = directoryName
    }
    
    private func url(for key: String) -> URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(directoryName)
            .appendingPathComponent(key)
    }
}

extension FileCache: CacheSource {
    public func save<T>(_ value: T) where T : Encodable {
        queue.async(flags: .barrier) {
            guard let data = try? JSONEncoder().encode(value) else {
                return
            }
            
            guard let url = url(for: key) else {
                return
            }
            
            do {
                try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                try data.write(to: url)
            } catch {
                print(error)
            }
        }
    }
    
    public func load<T>() -> T? where T : Decodable {
        guard let url = url(for: key) else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }
        
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    public func remove() {
        guard let url = url(for: key) else {
            return
        }
        
        try? fileManager.removeItem(at: url)
    }
}
