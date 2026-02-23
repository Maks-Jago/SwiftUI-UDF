//===--- ConfirmationDialog.swift ----------------------------------------===//
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

/// A type-safe confirmation dialog built using ``ConfirmationDialogComponentBuilder``.
///
/// `ConfirmationDialog` supports ``DialogTitle``, ``DialogMessage``, and ``DialogAction``
/// components. Components like ``DialogIcon`` and ``DialogComponentContent`` are **not**
/// supported and will produce a compile-time error if used.
///
/// ```swift
/// DialogRegistration.register(id: MyDialogs.logout) {
///     ConfirmationDialog {
///         DialogTitle("Log Out")
///         DialogMessage("Are you sure you want to log out?")
///         DialogButton.destructive("Log Out") { performLogout() }
///         DialogButton.cancel("Cancel")
///     }
/// }
/// ```
public struct ConfirmationDialog: Dialog {
    public let payload: DialogPayload
    public let dialogStyle: DialogStyle

    /// Creates a ConfirmationDialog dynamically by building typical dialog components.
    ///
    /// - Parameters:
    ///   - config: A `ConfirmationDialogConfiguration` used to customize the presentation.
    ///   - content: The dialog components making up the confirmation dialog.
    public init(
        config: ConfirmationDialogConfiguration = .default,
        @ConfirmationDialogComponentBuilder _ content: () -> [DialogComponent]
    ) {
        self.payload = DialogComponentParser.parse(content())
        self.dialogStyle = .confirmationDialog(config)
    }
}
