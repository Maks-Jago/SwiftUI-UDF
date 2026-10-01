//===--- DialogRegistration.swift ---------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2025 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

enum _DialogRegistry {
    nonisolated(unsafe) private static var registry: [AnyHashable: () -> any DialogTypeProtocol] = [:]

    private static let queue = DispatchQueue(
        label: "com.swiftui-udf.dialog.registry",
        qos: .userInitiated,
        attributes: .concurrent
    )

    static func register<ID: Hashable & Sendable>(
        id: ID,
        builder: @escaping @Sendable () -> DialogType
    ) {
        queue.async(flags: .barrier) {
            registry[AnyHashable(id)] = builder
        }
    }

    static func register<ID: Hashable & Sendable, D: DialogProtocol>(
        id: ID,
        dialog: @escaping @Sendable () -> D
    ) {
        queue.async(flags: .barrier) {
            registry[AnyHashable(id)] = { dialog() }
        }
    }

    internal static func get<ID: Hashable>(id: ID) -> (any DialogTypeProtocol)? {
        queue.sync {
            registry[AnyHashable(id)]?()
        }
    }

    static func isRegistered<ID: Hashable>(id: ID) -> Bool {
        queue.sync {
            registry[AnyHashable(id)] != nil
        }
    }

    static func unregister<ID: Hashable & Sendable>(id: ID) {
        queue.async(flags: .barrier) {
            registry.removeValue(forKey: AnyHashable(id))
        }
    }

    static func clearAll() {
        queue.async(flags: .barrier) {
            registry.removeAll()
        }
    }

    static func count() -> Int {
        queue.sync {
            registry.count
        }
    }

    static func identifiers() -> [AnyHashable] {
        queue.sync {
            Array(registry.keys)
        }
    }
}
