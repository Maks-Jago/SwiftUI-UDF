//===--- DialogComponents.swift ----------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

/// A dialog component representing the title text of a dialog.
///
/// `DialogTitle` is supported in ``Alert`` and ``ConfirmationDialog``, but **not** in ``Toast``.
/// If multiple `DialogTitle` components are provided, only the last one is used.
///
/// ```swift
/// Alert {
///     DialogTitle("Delete Item")
///     DialogMessage("This cannot be undone.")
/// }
/// ```
public struct DialogTitle: AlertComponent, ConfirmationDialogComponent {
    let value: String
    
    /// Creates a dialog title component.
    /// - Parameter value: The title string to display.
    public init(_ value: String) {
        self.value = value
    }
}
