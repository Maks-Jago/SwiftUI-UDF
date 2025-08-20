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

// TODO: Try to refuse GlobalValue for SwiftTesting
/// A utility for storing and accessing global singleton values within the application.
struct GlobalValue {
    /// A dictionary to store singletons using their type's name as the key.
    /// Thread-safety guaranteed by concurrent queue with barrier synchronization.
    nonisolated(unsafe) private static var values = [String: AnyObject]()

    /// Concurrent queue for thread-safe read/write operations.
    private static let queue = DispatchQueue(label: "GlobalValue.queue", attributes: .concurrent)

    /// Retrieves a stored singleton for the specified type in a thread-safe manner.
    ///
    /// - Parameter vType: The type of the singleton to retrieve.
    /// - Returns: The singleton instance of the specified type.
    /// - Note: This method will crash if the requested singleton has not been set prior to this call.
    static func value<T: AnyObject>(for vType: T.Type) -> T {
        let key = String(reflecting: T.self)
        return queue.sync {
            if let singleton = values[key] {
                return singleton as! T
            } else {
                fatalError("You have to initialize EnvironmentStore before using any Containers")
            }
        }
    }

    /// Stores a singleton value in a thread-safe manner.
    ///
    /// - Parameter value: The singleton instance to store.
    /// - Note: The value is stored using its type's fully qualified name as the key.
    static func set<T: AnyObject>(_ value: T) {
        let key = String(reflecting: T.self)
        queue.sync(flags: .barrier) {
            values[key] = value
        }
    }
}
