//===--- Cached.swift -----------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

/// A property wrapper that caches a value of type `T` conforming to `Codable` and `Initable`.
/// The cached value is stored both in memory and in a storage source (`CacheSource`).
/// Supports syncing the value to persistent storage with a debounce interval.
@propertyWrapper
public struct Cached<T: Codable>: Initable {
    public var key: String
    public var defaultValue: T
    public var intervalToSync: TimeInterval

    private var storage: CacheSource
    private var inMemoryValue: T

    private lazy var debouncer: Debouncer<T> = {
        let debouncer = Debouncer<T>(intervalToSync, on: .global(qos: .background))
        debouncer.on { [self] value in
            storage.save(value)
        }
        return debouncer
    }()

    /// This initializer should not be used. Use one of the other initializers instead.
    @available(*, deprecated, message: "Use `init(key:defaultValue:intervalToSync:storage)` instead.")
    public init() {
        fatalError("use init(key:defaultValue:intervalToSync:storage)")
    }

    /// Initializes a `Cached` property wrapper with a key, a default value, a sync interval, and a storage source.
    ///
    /// - Parameters:
    ///   - key: A unique key used for caching.
    ///   - defaultValue: The default value to be used if no cached value exists.
    ///   - intervalToSync: The time interval after which changes are saved to the storage.
    ///   - storage: The storage source used to save and load the cached value.
    public init(key: String, defaultValue: T, intervalToSync: TimeInterval = 1, storage: CacheSource) {
        self.key = key
        self.defaultValue = defaultValue
        self.intervalToSync = intervalToSync
        self.storage = storage
        self.inMemoryValue = storage.load() ?? defaultValue
    }

    /// Initializes a `Cached` property wrapper with a key, a default value, and a sync interval, using `FileCache` as the storage.
    ///
    /// - Parameters:
    ///   - key: A unique key used for caching.
    ///   - defaultValue: The default value to be used if no cached value exists.
    ///   - intervalToSync: The time interval after which changes are saved to the storage.
    public init(key: String, defaultValue: T, intervalToSync: TimeInterval = 1) {
        self.init(key: key, defaultValue: defaultValue, intervalToSync: intervalToSync, storage: FileCache(key: key))
    }

    /// Initializes a `Cached` property wrapper with a key, a default value conforming to `Initable`, a sync interval, and a storage source.
    ///
    /// - Parameters:
    ///   - key: A unique key used for caching.
    ///   - defaultValue: The default value conforming to `Initable` to be used if no cached value exists.
    ///   - intervalToSync: The time interval after which changes are saved to the storage.
    ///   - storage: The storage source used to save and load the cached value.
    public init(key: String, defaultValue: T = .init(), intervalToSync: TimeInterval = 1, storage: CacheSource) where T: Initable {
        self.key = key
        self.defaultValue = defaultValue
        self.intervalToSync = intervalToSync
        self.storage = storage
        self.inMemoryValue = storage.load() ?? defaultValue
    }

    /// Initializes a `Cached` property wrapper with a key, a default value conforming to `Initable`, and a sync interval, using `FileCache`
    /// as the storage.
    ///
    /// - Parameters:
    ///   - key: A unique key used for caching.
    ///   - defaultValue: The default value conforming to `Initable` to be used if no cached value exists.
    ///   - intervalToSync: The time interval after which changes are saved to the storage.
    public init(key: String, defaultValue: T = .init(), intervalToSync: TimeInterval = 1) where T: Initable {
        self.init(key: key, defaultValue: defaultValue, intervalToSync: intervalToSync, storage: FileCache(key: key))
    }

    /// The wrapped value of the property wrapper, stored both in memory and in the storage source.
    public var wrappedValue: T {
        get {
            inMemoryValue
        }
        set {
            inMemoryValue = newValue
            debouncer.receive(newValue)
        }
    }

    /// Resets the cached value to the default value and removes it from the storage.
    public mutating func reset() {
        storage.remove()
        wrappedValue = defaultValue
    }
}

/// Extends `Cached` to conform to `IsEquatable` where the cached type `T` conforms to both `Reducing` and `Equatable`.
extension Cached: IsEquatable where T: Reducing & Equatable {}

/// Extends `Cached` to conform to `Reducing` where the cached type `T` conforms to both `Reducing` and `Equatable`.
extension Cached: Reducing where T: Reducing & Equatable {}

/// Extends `Cached` to conform to `WrappedReducer` where the cached type `T` conforms to both `Reducing` and `Equatable`.
extension Cached: WrappedReducer where T: Reducing & Equatable {
    /// Provides access to the underlying reducer.
    /// - `get`: Returns the wrapped value.
    /// - `set`: Updates the wrapped value if the new value can be cast to the expected type `T`.
    public var reducer: Reducing {
        get { wrappedValue }
        set {
            if let newValue = newValue as? T {
                wrappedValue = newValue
            }
        }
    }
}

/// Extends `Cached` to conform to `Equatable` where the cached type `T` conforms to `Equatable`.
extension Cached: Equatable where T: Equatable {
    /// Compares two `Cached` instances for equality.
    /// - Returns: `true` if the default values, keys, sync intervals, and in-memory values are equal.
    public static func == (lhs: Cached<T>, rhs: Cached<T>) -> Bool {
        lhs.defaultValue == rhs.defaultValue &&
            lhs.key == rhs.key &&
            lhs.intervalToSync == rhs.intervalToSync &&
            lhs.inMemoryValue == rhs.inMemoryValue
    }
}

/// Extends `Cached` to conform to `Hashable` where the cached type `T` conforms to `Hashable`.
extension Cached: Hashable where T: Hashable {
    /// Hashes the essential components of the cached instance.
    /// - Parameter hasher: The hasher to use when combining the components of this instance.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(defaultValue)
        hasher.combine(key)
        hasher.combine(intervalToSync)
        hasher.combine(inMemoryValue)
    }
}
