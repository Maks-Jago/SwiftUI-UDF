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

/// A dialog component representing the message body of a dialog.
///
/// `DialogMessage` is supported in all dialog types: ``AlertDialog``, ``Toast``,
/// and ``ConfirmationDialog``. If multiple `DialogMessage` components are
/// provided, only the last one is used.
///
/// ```swift
/// Toast {
///     DialogMessage("Your changes have been saved.")
/// }
/// ```
public struct DialogMessage: AlertDialogComponent, ToastComponent, ConfirmationDialogComponent {
    let value: String
    
    /// Creates a dialog message component.
    /// - Parameter value: The message string to display.
    public init(_ value: String) {
        self.value = value
    }
}
