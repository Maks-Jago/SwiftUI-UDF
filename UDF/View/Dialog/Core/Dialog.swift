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

// MARK: Registration
public extension Dialog {
    @available(*, deprecated, message: "Use the new ResultBuilder-based register(id:dialog:) with AlertDialog, Toast, or ConfirmationDialog instead.")
    static func register<ID: Hashable & Sendable>(
        id: ID,
        builder: @escaping @Sendable () -> any DialogTypeProtocol
    ) {
        _DialogRegistry.register(id: id, builder: builder)
    }
    
    @MainActor
    static func register<ID: Hashable & Sendable, D: DialogProtocol>(
        id: ID,
        dialog: @escaping @Sendable @MainActor () -> D
    ) {
        _DialogRegistry.register(id: id, dialog: dialog)
    }
    
    static func isRegistered<ID: Hashable>(id: ID) -> Bool {
        _DialogRegistry.isRegistered(id: id)
    }
    
    static func unregister<ID: Hashable & Sendable>(id: ID) {
        _DialogRegistry.unregister(id: id)
    }
    
    static func clearAll() {
        _DialogRegistry.clearAll()
    }
    
    static func count() -> Int {
        _DialogRegistry.count()
    }
    
    static func identifiers() -> [AnyHashable] {
        _DialogRegistry.identifiers()
    }
    
    @available(*, deprecated, message: "Use the new ResultBuilder-based register(id:dialog:) with AlertDialog, Toast, or ConfirmationDialog instead.")
    static func register<ID: Hashable & Sendable>(
        id: ID,
        category: DialogCategory,
        message: String,
        style: DialogStyle = .alert
    ) {
        _DialogRegistry.register(id: id, category: category, message: message, style: style)
    }
    
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
