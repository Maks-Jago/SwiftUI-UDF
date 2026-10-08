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
import SwiftUI

/// Registration system for reusable dialogs.
///
/// The dialog registration system allows you to pre-define dialogs
/// that can be reused throughout your application by referencing them with
/// a unique identifier. This is particularly useful for common dialogs
/// like error states, success messages, or complex alerts that appear in
/// multiple places.
///
/// ## Thread Safety:
/// All registration operations are thread-safe and can be called from any queue.
/// The internal registry is protected by a concurrent queue with barrier writes.
///
/// ## Usage:
/// ```swift
/// // Register a dialog
/// Dialog.register(id: "networkError") {
///     .error("No internet connection", style: .alert)
/// }
/// 
/// // Use the registered dialog
/// dialog = .init(id: "networkError")
///
/// // Check if registered
/// if Dialog.isRegistered(id: "networkError") {
///     // Use it
/// }
/// ```
enum _DialogRegistry {
    
    // MARK: - Private Storage
    
    /// Internal registry storage for dialog builders.
    /// Protected by queue for thread safety.
    nonisolated(unsafe) private static var registry: [AnyHashable: () -> any DialogTypeProtocol] = [:]

    /// Concurrent queue for thread-safe registry access.
    /// Uses barrier writes to ensure data consistency.
    private static let queue = DispatchQueue(
        label: "com.swiftui-udf.dialog.registry",
        qos: .userInitiated,
        attributes: .concurrent
    )
    
    // MARK: - Public Registration API
    
    /// Registers a convenient standard dialog factory for a given identifier.
    ///
    /// This registration overload is optimized for standard ``DialogType`` instances
    /// representing simple `.success`, `.error`, `.warning`, or `.info` states.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the dialog. Can be any Hashable type.
    ///   - builder: A closure that returns a standard ``DialogType`` when called.
    public static func register<ID: Hashable & Sendable>(
        id: ID,
        builder: @escaping @Sendable () -> DialogType
    ) {
        queue.async(flags: .barrier) {
            registry[AnyHashable(id)] = builder
        }
    }
    
    /// Registers a type-safe ``DialogProtocol`` (``AlertDialog``, ``Toast``, or ``ConfirmationDialog``)
    /// for the given identifier.
    ///
    /// The builder closure is evaluated when the dialog is requested,
    /// allowing it to capture the latest state dynamically.
    ///
    /// ```swift
    /// Dialog.register(id: MyDialogs.error, store: store) { _ in
    ///     AlertDialog {
    ///         DialogTitle("Error")
    ///         DialogMessage("Something went wrong.")
    ///         DialogButton(title: "OK")
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - id: A unique, hashable identifier for this dialog.
    ///   - dialog: A closure that returns a ``DialogProtocol`` conforming value.
    public static func register<ID: Hashable & Sendable, D: DialogProtocol>(
        id: ID,
        dialog: @escaping @Sendable () -> D
    ) {
        queue.async(flags: .barrier) {
            registry[AnyHashable(id)] = { dialog() }
        }
    }
    
    /// Retrieves a registered dialog for the given identifier.
    ///
    /// This function is called internally by `DialogStatus.init(id:)` to
    /// resolve registered dialogs. It executes the builder closure and
    /// returns the resulting dialog type.
    ///
    /// - Parameter id: The identifier of the registered dialog.
    /// - Returns: The dialog type if registered, nil otherwise.
    ///
    /// ## Thread Safety:
    /// This function is thread-safe and can be called from any queue.
    internal static func get<ID: Hashable>(id: ID) -> (any DialogTypeProtocol)? {
        queue.sync {
            registry[AnyHashable(id)]?()
        }
    }
    
    /// Checks if a dialog is registered for the given identifier.
    ///
    /// - Parameter id: The identifier to check.
    /// - Returns: True if a dialog is registered for this identifier.
    ///
    /// ## Example:
    /// ```swift
    /// if Dialog.isRegistered(id: "networkError") {
    ///     dialog = .init(id: "networkError")
    /// } else {
    ///     dialog = .init(error: "Unknown error occurred")
    /// }
    /// ```
    public static func isRegistered<ID: Hashable>(id: ID) -> Bool {
        queue.sync {
            registry[AnyHashable(id)] != nil
        }
    }
    
    /// Unregisters a dialog for the given identifier.
    ///
    /// After calling this function, attempts to create dialogs using
    /// the specified identifier will result in a dismissed state.
    ///
    /// - Parameter id: The identifier of the dialog to unregister.
    ///
    /// ## Example:
    /// ```swift
    /// Dialog.unregister(id: "temporaryPromotion")
    /// ```
    public static func unregister<ID: Hashable & Sendable>(id: ID) {
        queue.async(flags: .barrier) {
            registry.removeValue(forKey: AnyHashable(id))
        }
    }
    
    /// Clears all registered dialogs.
    ///
    /// This function removes all dialogs from the registry. It's primarily
    /// useful for testing scenarios or application reset functionality.
    ///
    /// ## Warning:
    /// Use this function carefully as it will affect all parts of your application
    /// that depend on registered dialogs.
    ///
    /// ## Example:
    /// ```swift
    /// // In test teardown
    /// Dialog.clearAll()
    /// ```
    public static func clearAll() {
        queue.async(flags: .barrier) {
            registry.removeAll()
        }
    }
    
    // MARK: - Registry Information
    
    /// Returns the number of currently registered dialogs.
    ///
    /// This function is primarily useful for debugging and testing purposes.
    ///
    /// - Returns: The count of registered dialogs.
    public static func count() -> Int {
        queue.sync {
            registry.count
        }
    }
    
    /// Returns all currently registered dialog identifiers.
    ///
    /// This function is primarily useful for debugging and introspection purposes.
    /// The returned identifiers are not guaranteed to be in any particular order.
    ///
    /// - Returns: An array of all registered dialog identifiers.
    public static func identifiers() -> [AnyHashable] {
        queue.sync {
            Array(registry.keys)
        }
    }
    
}
