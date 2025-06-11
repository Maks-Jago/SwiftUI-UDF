//===--- NotificationRegistration.swift ---------------------------------===//
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

/// Registration system for reusable notifications.
///
/// The notification registration system allows you to pre-define notifications
/// that can be reused throughout your application by referencing them with
/// a unique identifier. This is particularly useful for common notifications
/// like error states, success messages, or complex alerts that appear in
/// multiple places.
///
/// ## Thread Safety:
/// All registration operations are thread-safe and can be called from any queue.
/// The internal registry is protected by a concurrent queue with barrier writes.
///
/// ## Usage:
/// ```swift
/// // Register a notification
/// NotificationRegistry.register(id: "networkError") {
///     .error("No internet connection", style: .alert)
/// }
/// 
/// // Use the registered notification
/// notification = .init(id: "networkError")
/// 
/// // Check if registered
/// if NotificationRegistry.isRegistered(id: "networkError") {
///     // Use it
/// }
/// ```
public enum NotificationRegistry {
    
    // MARK: - Private Storage
    
    /// Internal registry storage for notification builders.
    /// Protected by registrationQueue for thread safety.
    nonisolated(unsafe) private static var registry: [AnyHashable: () -> NotificationType] = [:]
    
    /// Concurrent queue for thread-safe registry access.
    /// Uses barrier writes to ensure data consistency.
    private static let queue = DispatchQueue(
        label: "com.swiftui-udf.notification.registry",
        qos: .userInitiated,
        attributes: .concurrent
    )
    
    // MARK: - Public Registration API
    
    /// Registers a notification builder for a given identifier.
    ///
    /// The builder closure will be called each time the notification is requested,
    /// allowing for dynamic content based on current application state.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the notification. Can be any Hashable type.
    ///   - builder: A closure that returns a NotificationType when called.
    ///
    /// ## Example:
    /// ```swift
    /// NotificationRegistry.register(id: "deleteConfirmation") {
    ///     .custom(content: NotificationContent("Delete Item", message: "This cannot be undone") {
    ///         NotificationButton.destructive("Delete") { performDelete() }
    ///         NotificationButton.cancel("Cancel")
    ///     })
    /// }
    /// ```
    public static func register<ID: Hashable & Sendable>(
        id: ID,
        builder: @escaping @Sendable () -> NotificationType
    ) {
        queue.async(flags: .barrier) {
            registry[AnyHashable(id)] = builder
        }
    }
    
    /// Retrieves a registered notification for the given identifier.
    ///
    /// This function is called internally by `NotificationState.init(id:)` to
    /// resolve registered notifications. It executes the builder closure and
    /// returns the resulting notification type.
    ///
    /// - Parameter id: The identifier of the registered notification.
    /// - Returns: The notification type if registered, nil otherwise.
    ///
    /// ## Thread Safety:
    /// This function is thread-safe and can be called from any queue.
    internal static func get<ID: Hashable>(id: ID) -> NotificationType? {
        return queue.sync {
            registry[AnyHashable(id)]?()
        }
    }
    
    /// Checks if a notification is registered for the given identifier.
    ///
    /// - Parameter id: The identifier to check.
    /// - Returns: True if a notification is registered for this identifier.
    ///
    /// ## Example:
    /// ```swift
    /// if NotificationRegistry.isRegistered(id: "networkError") {
    ///     notification = .init(id: "networkError")
    /// } else {
    ///     notification = .init(error: "Unknown error occurred")
    /// }
    /// ```
    public static func isRegistered<ID: Hashable>(id: ID) -> Bool {
        return queue.sync {
            registry[AnyHashable(id)] != nil
        }
    }
    
    /// Unregisters a notification for the given identifier.
    ///
    /// After calling this function, attempts to create notifications using
    /// the specified identifier will result in a dismissed state.
    ///
    /// - Parameter id: The identifier of the notification to unregister.
    ///
    /// ## Example:
    /// ```swift
    /// NotificationRegistry.unregister(id: "temporaryPromotion")
    /// ```
    public static func unregister<ID: Hashable & Sendable>(id: ID) {
        queue.async(flags: .barrier) {
            registry.removeValue(forKey: AnyHashable(id))
        }
    }
    
    /// Clears all registered notifications.
    ///
    /// This function removes all notifications from the registry. It's primarily
    /// useful for testing scenarios or application reset functionality.
    ///
    /// ## Warning:
    /// Use this function carefully as it will affect all parts of your application
    /// that depend on registered notifications.
    ///
    /// ## Example:
    /// ```swift
    /// // In test teardown
    /// NotificationRegistry.clearAll()
    /// ```
    public static func clearAll() {
        queue.async(flags: .barrier) {
            registry.removeAll()
        }
    }
    
    // MARK: - Registry Information
    
    /// Returns the number of currently registered notifications.
    ///
    /// This function is primarily useful for debugging and testing purposes.
    ///
    /// - Returns: The count of registered notifications.
    public static func count() -> Int {
        return queue.sync {
            registry.count
        }
    }
    
    /// Returns all currently registered notification identifiers.
    ///
    /// This function is primarily useful for debugging and introspection purposes.
    /// The returned identifiers are not guaranteed to be in any particular order.
    ///
    /// - Returns: An array of all registered notification identifiers.
    public static func identifiers() -> [AnyHashable] {
        return queue.sync {
            Array(registry.keys)
        }
    }
    
    // MARK: - Convenience Registration
    
    /// Convenience function for registering simple message notifications.
    ///
    /// - Parameters:
    ///   - id: The identifier for the notification.
    ///   - category: The notification category (success, error, warning, info).
    ///   - message: The message to display.
    ///   - style: The notification style (defaults to .alert).
    public static func register<ID: Hashable & Sendable>(
        id: ID,
        category: NotificationCategory,
        message: String,
        style: NotificationStyle = .alert
    ) {
        register(id: id) {
            switch category {
            case .success:
                return .success(message, style: style)
            case .error:
                return .error(message, style: style)
            case .warning:
                return .warning(message, style: style)
            case .info:
                return .info(message, style: style)
            case .custom:
                let content = NotificationContent(message)
                return .custom(content: content, style: style)
            }
        }
    }
}
