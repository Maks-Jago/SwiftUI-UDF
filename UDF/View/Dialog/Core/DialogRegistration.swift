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
/// DialogRegistry.register(id: "networkError") {
///     .error("No internet connection", style: .alert)
/// }
/// 
/// // Use the registered dialog
/// dialog = .init(id: "networkError")
///
/// // Check if registered
/// if DialogRegistry.isRegistered(id: "networkError") {
///     // Use it
/// }
/// ```
public enum DialogRegistry {
    
    // MARK: - Private Storage
    
    /// Internal registry storage for dialog builders.
    /// Protected by registrationQueue for thread safety.
    nonisolated(unsafe) private static var registry: [AnyHashable: () -> any DialogTypeProtocol] = [:]

    /// Concurrent queue for thread-safe registry access.
    /// Uses barrier writes to ensure data consistency.
    private static let queue = DispatchQueue(
        label: "com.swiftui-udf.dialog.registry",
        qos: .userInitiated,
        attributes: .concurrent
    )
    
    // MARK: - Public Registration API
    
    /// Registers a dialog builder for a given identifier.
    ///
    /// The builder closure will be called each time the dialog is requested,
    /// allowing for dynamic content based on current application state.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the dialog. Can be any Hashable type.
    ///   - builder: A closure that returns a dialogType when called.
    ///
    /// ## Example:
    /// ```swift
    /// DialogRegistry.register(id: "deleteConfirmation") {
    ///     DialogCustomType.custom(
    ///         content: DialogContent("Delete Item", message: "This cannot be undone") {
    ///             DialogButton.destructive("Delete") { performDelete() }
    ///             DialogButton.cancel("Cancel")
    ///         },
    ///         style: .alert
    ///     )
    /// }
    /// ```
    public static func register<ID: Hashable & Sendable>(
        id: ID,
        builder: @escaping @Sendable () -> any DialogTypeProtocol
    ) {
        queue.async(flags: .barrier) {
            registry[AnyHashable(id)] = builder
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
    /// if DialogRegistry.isRegistered(id: "networkError") {
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
    /// DialogRegistry.unregister(id: "temporaryPromotion")
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
    /// DialogRegistry.clearAll()
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
    
    // MARK: - Convenience Registration
    
    /// Convenience function for registering simple message dialogs.
    ///
    /// - Parameters:
    ///   - id: The identifier for the dialog.
    ///   - category: The dialog category (success, error, warning, info).
    ///   - message: The message to display.
    ///   - style: The dialog style (defaults to .alert).
    public static func register<ID: Hashable & Sendable>(
        id: ID,
        category: DialogCategory,
        message: String,
        style: DialogStyle = .alert
    ) {
        register(id: id) {
            switch category {
            case .success:
                return DialogType.success(message: message, style: style)
            case .error:
                return DialogType.error(message: message, style: style)
            case .warning:
                return DialogType.warning(message: message, style: style)
            case .info:
                return DialogType.info(message: message, style: style)
            case .custom:
                let content = DialogContent(message)
                return DialogCustomType.custom(content: content, style: style)
            }
        }
    }
}

// MARK: - ToastRegistry Extension

/// Toast-specific registration extensions for `DialogRegistry`.
///
/// This extension provides convenient methods for registering toast dialogs
/// with common configurations and patterns. Toasts are non-modal dialogs
/// that appear as overlay notifications.
public extension DialogRegistry {
    
    /// Registers a toast dialog with custom content and configuration.
    ///
    /// This method provides a convenient way to register toast dialogs with
    /// rich content and custom styling. Unlike alerts, toasts support theming,
    /// positioning, and non-modal presentation.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the toast.
    ///   - content: The dialog content with title, message, and actions.
    ///   - configuration: Toast-specific configuration for styling and behavior.
    ///
    /// ## Example:
    /// ```swift
    /// DialogRegistry.registerToast(id: "uploadProgress") {
    ///     DialogContent(
    ///         title: "Uploading File",
    ///         actions: {
    ///             DialogButton.cancel("Cancel") { cancelUpload() }
    ///         }
    ///     )
    /// } configuration: {
    ///     ToastConfiguration(
    ///         theme: .vibrant,
    ///         position: .bottom,
    ///         defaultDuration: 5.0
    ///     )
    /// }
    /// ```
    static func registerToast<ID: Hashable & Sendable>(
        id: ID,
        content: @escaping @Sendable () -> DialogContent<EmptyView, EmptyView>,
        configuration: @escaping @Sendable () -> ToastConfiguration = { .default }
    ) {
        register(id: id) {
            DialogCustomType.custom(
                content: content(),
                style: .toast(configuration())
            )
        }
    }
    
    /// Registers a toast with custom SwiftUI content.
    ///
    /// This method allows registration of toasts with completely custom SwiftUI views,
    /// providing maximum flexibility for rich notifications, progress indicators,
    /// and interactive toast experiences.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the toast.
    ///   - title: The toast title.
    ///   - customView: A closure returning the custom SwiftUI content.
    ///   - configuration: Toast configuration for styling and behavior.
    ///
    /// ## Example:
    /// ```swift
    /// DialogRegistry.registerCustomToast(id: "downloadProgress", title: "Downloading") {
    ///     VStack(spacing: 8) {
    ///         ProgressView(value: downloadProgress)
    ///         Text("\(Int(downloadProgress * 100))% complete")
    ///             .font(.caption)
    ///     }
    /// }
    /// ```
    static func registerCustomToast<ID: Hashable & Sendable, CustomContent: View>(
        id: ID,
        title: String,
        customContent: @escaping @Sendable () -> CustomContent,
        configuration: @escaping @Sendable () -> ToastConfiguration = { .default }
    ) {
        register(id: id) {
            let content = DialogContent(title: title, customContent: customContent)
            return DialogCustomType.custom(content: content, style: .toast(configuration()))
        }
    }
}
