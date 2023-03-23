//
//  Cached.swift
//  
//
//  Created by Max Kuznetsov on 16.02.2021.
//

import Foundation

@propertyWrapper
public final class Cached<T: Codable>: Initable {
    public var key: String
    public var defaultValue: T
    public var intervalToSync: TimeInterval

    private var storage: CacheSource
    private var inMemoryValue: T
    
    private lazy var debouncer: Debouncer<T> = {
        let debouncer = Debouncer<T>(intervalToSync, on: .global(qos: .background))
        debouncer.on { [weak self] value in
            self?.storage.save(value)
        }
        
        return debouncer
    }()

    public init() {
        fatalError("use init(key:defaultValue:intervalToSync:storage)")
    }
    
    public init(key: String, defaultValue: T, intervalToSync: TimeInterval = 1, storage: CacheSource) {
        self.key = key
        self.defaultValue = defaultValue
        self.intervalToSync = intervalToSync
        self.storage = storage
        self.inMemoryValue = storage.load() ?? defaultValue
    }
    
    public convenience init(key: String, defaultValue: T, intervalToSync: TimeInterval = 1) {
        self.init(key: key, defaultValue: defaultValue, intervalToSync: intervalToSync, storage: FileCache(key: key))
    }
    
    public init(key: String, defaultValue: T = .init(), intervalToSync: TimeInterval = 1, storage: CacheSource) where T: Initable {
        self.key = key
        self.defaultValue = defaultValue
        self.intervalToSync = intervalToSync
        self.storage = storage
        self.inMemoryValue = storage.load() ?? defaultValue
    }
    
    public convenience init(key: String, defaultValue: T = .init(), intervalToSync: TimeInterval = 1) where T: Initable {
        self.init(key: key, defaultValue: defaultValue, intervalToSync: intervalToSync, storage: FileCache(key: key))
    }

    public var wrappedValue: T {
        get {
            inMemoryValue
        }
        set {
            inMemoryValue = newValue
            debouncer.receive(newValue)
        }
    }

    public func reset() {
        storage.remove()
        wrappedValue = defaultValue
    }
}

extension Cached: IsEquatable where T: Reducing & Equatable {}
extension Cached: Reducing where T: Reducing & Equatable {}

extension Cached: WrappedReducer where T: Reducing & Equatable {
    public var reducer: Reducing {
        get { wrappedValue }
        set {
            if let newValue = newValue as? T {
                wrappedValue = newValue
            }
        }
    }
}

extension Cached: Equatable where T: Equatable {
    public static func == (lhs: Cached<T>, rhs: Cached<T>) -> Bool {
        lhs.defaultValue == rhs.defaultValue &&
        lhs.key == rhs.key &&
        lhs.intervalToSync == rhs.intervalToSync &&
        lhs.inMemoryValue == rhs.inMemoryValue
    }
}

extension Cached: Hashable where T: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(defaultValue)
        hasher.combine(key)
        hasher.combine(intervalToSync)
        hasher.combine(inMemoryValue)
    }
}
