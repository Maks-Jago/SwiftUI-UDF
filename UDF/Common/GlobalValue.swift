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
    /// A dictionary to store singletons using their type's name as the key.
    private static let queue = DispatchQueue(label: "GlobalValue.queue", attributes: .concurrent)
    private static var values = [String: AnyObject]()

    /// Retrieves a stored singleton for the specified type.
    ///
    /// - Parameter vType: The type of the singleton to retrieve.
    /// - Returns: The singleton instance of the specified type.
    /// - Note: This method will crash if the requested singleton is not set prior to this call.
    static func value<T: AnyObject>(for vType: T.Type) -> T {
        let key = String(reflecting: T.self)  // reflecting даёт полное имя с модулем
        return queue.sync {
            if let singleton = values[key] {
                return singleton as! T
            } else {
                if ProcessInfo.processInfo.isRunningTests {
                    print("⚠️ GlobalValue: No instance found for \(T.self) in tests. This usually means a test is trying to use containers before creating an EnvironmentStore.")
                }
                fatalError("You have to initialize EnvironmentStore before using any Containers. Type: \(T.self)")
            }
        }
    }

    /// Stores a singleton value.
    ///
    /// - Parameter value: The singleton instance to store.
    /// - Note: The value is stored using its type's name as the key.
    static func set<T: AnyObject>(_ value: T) {
        let key = String(reflecting: T.self)  // reflecting даёт полное имя с модулем
        queue.sync(flags: .barrier) {
            if ProcessInfo.processInfo.isRunningTests && values[key] != nil {
                print("ℹ️ GlobalValue: Replacing \(T.self) instance")
            }
            values[key] = value
        }
    }

    /// Clears all stored values (use only in tests)
    static func clearAllValues() {
        guard ProcessInfo.processInfo.isRunningTests else {
            assertionFailure("clearAllValues() should only be called in tests")
            return
        }
        queue.sync(flags: .barrier) {
            values.removeAll()
        }
    }
    
    /// Clears stored value for specific type (use only in tests)
    static func clearValue<T: AnyObject>(for type: T.Type) {
        guard ProcessInfo.processInfo.isRunningTests else {
            assertionFailure("clearValue() should only be called in tests")
            return
        }
        let key = String(reflecting: T.self)
        queue.sync(flags: .barrier) {
            values.removeValue(forKey: key)
        }
    }
    
    /// Checks if value exists for given type (use only in tests)
    static func hasValue<T: AnyObject>(for type: T.Type) -> Bool {
        guard ProcessInfo.processInfo.isRunningTests else {
            assertionFailure("hasValue() should only be called in tests")
            return false
        }
        let key = String(reflecting: T.self)
        return queue.sync {
            values[key] != nil
        }
    }
}
