//===--- AlertDialog.swift ---------------------------------------------------===//
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

/// A type-safe alert dialog built using ``AlertDialogComponentBuilder``.
///
/// `AlertDialog` supports ``DialogTitle``, ``DialogMessage``, and ``DialogAction`` components.
/// Components like ``DialogIcon`` and ``DialogView`` are **not** supported
/// and will produce a compile-time error if used.
///
/// ```swift
/// DialogRegistration.register(id: MyDialogs.deleteConfirmation) {
///     AlertDialog {
///         DialogTitle("Delete Item?")
///         DialogMessage("This action cannot be undone.")
///         DialogButton.destructive("Delete") { performDelete() }
///         DialogButton.cancel("Cancel")
///     }
/// }
/// ```
public struct AlertDialog: Dialog {
    public let payload: DialogPayload
    public let dialogStyle: DialogStyle = .alert

    /// Creates an alert dialog by evaluating the provided component builder.
    ///
    /// - Parameter content: A result builder closure producing ``AlertDialogComponent`` values.
    @MainActor
    public init(
        @AlertDialogComponentBuilder _ content: @MainActor () -> [DialogComponent]
    ) {
        self.payload = DialogComponentParser.parse(content())
    }
}
