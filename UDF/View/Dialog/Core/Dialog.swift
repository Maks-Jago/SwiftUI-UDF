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
    /// for the given identifier.
    ///
    /// The builder closure is evaluated when the dialog is requested,
    /// allowing it to capture the latest state dynamically.
    ///
    /// ```swift
    /// Dialog.register(id: MyDialogs.error) {
    ///     AlertDialog {
    ///         DialogTitle("Error")
    ///         DialogMessage("Something went wrong.")
    ///         DialogButton(title: "OK")
    ///     }
    /// }
    /// ```
    ///
    @available(*, deprecated, message: "Use register(id:store:dialog:) to ensure Swift 6 strict concurrency safety when accessing state.")
    static func register<ID: Hashable & Sendable, D: DialogProtocol>(
        id: ID,
        dialog: @escaping @Sendable () -> D
    ) {
        _DialogRegistry.register(id: id, dialog: dialog)
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

// MARK: - Legacy
public extension Dialog {
    /// Convenience function for registering simple message dialogs.
    ///
    /// - Parameters:
    ///   - id: The identifier for the dialog.
    ///   - category: The dialog category (success, error, warning, info).
    ///   - message: The message to display.
    ///   - style: The dialog style (defaults to .alert).
    @available(*, deprecated, message: "Use the new ResultBuilder-based register(id:dialog:) with AlertDialog, Toast, or ConfirmationDialog instead.")
    static func register<ID: Hashable & Sendable>(
        id: ID,
        category: DialogCategory,
        message: String,
        style: DialogStyle = .alert
    ) {
        _DialogRegistry.register(id: id, category: category, message: message, style: style)
    }
    
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
    ///   - onAutoDismiss: Optional callback executed when toast auto-dismisses due to timer.
    @available(*, deprecated, message: "Use the new ResultBuilder-based register(id:dialog:) with Toast instead.")
    static func registerToast<ID: Hashable & Sendable>(
        id: ID,
        content: @escaping @Sendable () -> DialogContent<EmptyView, EmptyView>,
        configuration: @escaping @Sendable () -> ToastConfiguration = { .default },
        onAutoDismiss: (@Sendable () -> Void)? = nil
    ) {
        _DialogRegistry.registerToast(
            id: id,
            content: content,
            configuration: configuration,
            onAutoDismiss: onAutoDismiss
        )
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
    ///   - customContent: A closure returning the custom SwiftUI content.
    ///   - configuration: Toast configuration for styling and behavior.
    ///   - onAutoDismiss: Optional callback executed when toast auto-dismisses due to timer.
    @available(*, deprecated, message: "Use the new ResultBuilder-based register(id:dialog:) with Toast and DialogView instead.")
    static func registerCustomToast<ID: Hashable & Sendable, CustomContent: View>(
        id: ID,
        title: String,
        customContent: @escaping @Sendable () -> CustomContent,
        configuration: @escaping @Sendable () -> ToastConfiguration = { .default },
        onAutoDismiss: (@Sendable () -> Void)? = nil
    ) {
        _DialogRegistry.registerCustomToast(
            id: id,
            title: title,
            customContent: customContent,
            configuration: configuration,
            onAutoDismiss: onAutoDismiss
        )
    }
}
