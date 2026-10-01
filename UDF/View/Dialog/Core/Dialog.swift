//===--- Dialog.swift ----------------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI

/// A namespace for dialog registration and management.
public enum Dialog {}

// MARK: - Registration
public extension Dialog {
    /// Registers a convenient standard dialog factory for a given identifier.
    ///
    /// The builder closure will be called each time the dialog is requested,
    /// allowing for dynamic content based on current application state.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the dialog. Can be any Hashable type.
    ///   - builder: A closure that returns a dialog type when called.
    static func register<ID: Hashable & Sendable>(
        id: ID,
        builder: @escaping @Sendable () -> DialogType
    ) {
        _DialogRegistry.register(id: id, builder: builder)
    }
    
    /// Registers a type-safe ``DialogProtocol`` (``AlertDialog``, ``Toast``, or ``ConfirmationDialog``)
    /// for the given identifier, explicitly passing the environment store to the builder closure.
    ///
    /// This is required in Swift 6 to avoid strict concurrency warnings when capturing
    /// variables from a `@MainActor` context (like a View). By passing the store explicitly,
    /// it is safely evaluated before being passed to the `@Sendable` builder closure.
    ///
    /// ```swift
    /// Dialog.register(id: MyDialogs.error, store: store) { store in
    ///     AlertDialog {
    ///         DialogTitle(store.state.errorTitle)
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - id: A unique, hashable identifier for this dialog.
    ///   - store: The environment store to pass into the dialog builder.
    ///   - dialog: A closure that receives the store and returns a ``DialogProtocol`` conforming value.
    static func register<ID: Hashable & Sendable, D: DialogProtocol, State: AppReducer>(
        id: ID,
        store: EnvironmentStore<State>,
        dialog: @escaping @Sendable (EnvironmentStore<State>) -> D
    ) {
        _DialogRegistry.register(id: id) { dialog(store) }
    }

    /// Checks if a dialog is registered for the given identifier.
    ///
    /// - Parameter id: The identifier to check.
    /// - Returns: True if a dialog is registered for this identifier.
    static func isRegistered<ID: Hashable>(id: ID) -> Bool {
        _DialogRegistry.isRegistered(id: id)
    }
    
    /// Unregisters a dialog for the given identifier.
    ///
    /// After calling this function, attempts to create dialogs using
    /// the specified identifier will result in a dismissed state.
    ///
    /// - Parameter id: The identifier of the dialog to unregister.
    static func unregister<ID: Hashable & Sendable>(id: ID) {
        _DialogRegistry.unregister(id: id)
    }
    
    /// Clears all registered dialogs.
    ///
    /// This function removes all dialogs from the registry. It's primarily
    /// useful for testing scenarios or application reset functionality.
    static func clearAll() {
        _DialogRegistry.clearAll()
    }
    
    /// Returns the number of currently registered dialogs.
    ///
    /// - Returns: The count of registered dialogs.
    static func count() -> Int {
        _DialogRegistry.count()
    }
    
    /// Returns all currently registered dialog identifiers.
    ///
    /// The returned identifiers are not guaranteed to be in any particular order.
    ///
    /// - Returns: An array of all registered dialog identifiers.
    static func identifiers() -> [AnyHashable] {
        _DialogRegistry.identifiers()
    }
}
