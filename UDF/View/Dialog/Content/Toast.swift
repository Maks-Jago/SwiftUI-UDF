//===--- Toast.swift -----------------------------------------------------===//
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

/// A type-safe toast dialog built using ``ToastComponentBuilder``.
///
/// `Toast` supports ``DialogMessage``, ``DialogIcon``, ``DialogComponentContent``,
/// and ``DialogAction`` components. ``DialogTitle`` is **not** supported and will
/// produce a compile-time error if used.
///
/// ```swift
/// DialogRegistration.register(id: MyDialogs.savedToast) {
///     Toast(config: .init(hapticFeedback: .success)) {
///         DialogIcon { Image(systemName: "checkmark.circle.fill") }
///         DialogMessage("Changes saved.")
///     }
/// }
/// ```
public struct Toast: Dialog {
    public let customType: DialogCustomType<AnyView, AnyView>

    /// Creates a Toast dynamically by building typical dialog components.
    ///
    /// - Parameters:
    ///   - config: A `ToastConfiguration` used to customize the presentation.
    ///   - content: The dialog components making up the toast.
    public init(
        config: ToastConfiguration = .default,
        @ToastComponentBuilder _ content: () -> [DialogComponent]
    ) {
        let parsed = DialogComponentParser.parse(content())
        self.customType = DialogCustomType.custom(
            content: .init(
                title: parsed.title,
                message: parsed.message,
                actions: parsed.actions,
                iconBuilder: parsed.icon,
                customContentBuilder: parsed.customContentView
            ),
            style: .toast(config)
        )
    }
}
