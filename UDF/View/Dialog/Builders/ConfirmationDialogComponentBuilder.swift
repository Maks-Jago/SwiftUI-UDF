//===--- ConfirmationDialogComponentBuilder.swift ---------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

/// A result builder for constructing the component list of a ``ConfirmationDialog``.
///
/// Only types conforming to ``ConfirmationDialogComponent`` are accepted.
/// Attempting to use unsupported components like ``DialogIcon`` or
/// ``DialogView`` will produce a compile-time error with a descriptive message.
///
/// ```swift
/// ConfirmationDialog {
///     DialogTitle("Delete?")
///     DialogMessage("This action cannot be undone.")
///     DialogButton.destructive("Delete") { performDelete() }
///     DialogButton.cancel("Cancel")
/// }
/// ```
@resultBuilder
public enum ConfirmationDialogComponentBuilder: DialogBuilder {
    public static func buildExpression(_ expression: some ConfirmationDialogComponent) -> [any DialogComponent] {
        [expression]
    }
}

/// Compile-time restrictions for components that are not supported in confirmation dialogs.
public extension ConfirmationDialogComponentBuilder {
    @available(*, unavailable, message: "DialogIcon is not supported in Confirmation Dialogs.")
    static func buildExpression(_ expression: DialogIcon) -> [any DialogComponent] { [] }

    @available(*, unavailable, message: "DialogView is not supported in Confirmation Dialogs.")
    static func buildExpression(_ expression: DialogView) -> [any DialogComponent] { [] }
}
