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
    public let payload: DialogPayload
    public let dialogStyle: DialogStyle

    /// Creates a Toast dynamically by building typical dialog components.
    ///
    /// - Parameters:
    ///   - config: A `ToastConfiguration` used to customize the presentation.
    ///   - content: The dialog components making up the toast.
    public init(
        config: ToastConfiguration = .default,
        @ToastComponentBuilder _ content: () -> [DialogComponent]
    ) {
        self.payload = DialogComponentParser.parse(content())
        self.dialogStyle = .toast(config)
    }
}
