//===--- Alert.swift -----------------------------------------------------===//
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

/// A type-safe alert dialog built using ``AlertComponentBuilder``.
///
/// `Alert` supports ``DialogTitle``, ``DialogMessage``, and ``DialogAction`` components.
/// Components like ``DialogIcon`` and ``DialogComponentContent`` are **not** supported
/// and will produce a compile-time error if used.
///
/// ```swift
/// DialogRegistration.register(id: MyDialogs.deleteConfirmation) {
///     Alert {
///         DialogTitle("Delete Item?")
///         DialogMessage("This action cannot be undone.")
///         DialogButton.destructive("Delete") { performDelete() }
///         DialogButton.cancel("Cancel")
///     }
/// }
/// ```
public struct Alert: Dialog {
    public let customType: DialogCustomType<AnyView, AnyView>

    /// Creates an alert by evaluating the provided component builder.
    ///
    /// - Parameter content: A result builder closure producing ``AlertComponent`` values.
    public init(
        @AlertComponentBuilder _ content: () -> [DialogComponent]
    ) {
        let parsed = DialogComponentParser.parse(content())
        self.customType = DialogCustomType.custom(
            content: .init(
                title: parsed.title,
                message: parsed.message,
                actions: parsed.actions,
                iconBuilder: nil,
                customContentBuilder: nil
            ),
            style: .alert
        )
    }
}
