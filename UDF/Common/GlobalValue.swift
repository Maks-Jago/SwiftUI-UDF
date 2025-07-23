//===--- GlobalValue.swift ---------------------------------------===//
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

/// A utility for storing and accessing global singleton values within the application.
actor GlobalValue {
    /// A dictionary to store singletons using their ObjectIdentifier as the key.
    private static var values = [ObjectIdentifier: AnyObject]()

    /// Retrieves a stored singleton for the specified type.
    ///
    /// - Parameter vType: The type of the singleton to retrieve.
    /// - Returns: The singleton instance of the specified type.
    /// - Note: This method will crash if the requested singleton is not set prior to this call.
    static func value<T: AnyObject>(for vType: T.Type) -> T {
        let key = ObjectIdentifier(vType)
        if let singleton = values[key] {
            return singleton as! T
        } else {
            fatalError("You have to initialize EnvironmentStore before using any Containers. Type: \(T.self)")
        }
    }

    /// Stores a singleton value.
    ///
    /// - Parameter value: The singleton instance to store.
    /// - Note: The value is stored using its ObjectIdentifier as the key.
    static func set<T: AnyObject>(_ value: T) {
        let key = ObjectIdentifier(T.self)
        
        if ProcessInfo.processInfo.isRunningTests && values[key] != nil {
            print("ℹ️ GlobalValue: Replacing \(T.self) instance")
        }
        
        values[key] = value
    }

    /// Clears all stored values (use only in tests)
    static func clearAllValues() {
        guard ProcessInfo.processInfo.isRunningTests else {
            assertionFailure("clearAllValues() should only be called in tests")
            return
        }
        values.removeAll()
    }
}
