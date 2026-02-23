//===--- ToastComponentBuilder.swift ---------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

/// A result builder for constructing the component list of a ``Toast``.
///
/// Only types conforming to ``ToastComponent`` are accepted. Attempting to use
/// unsupported components like ``DialogTitle`` will produce a compile-time error
/// with a descriptive message.
///
/// ```swift
/// Toast {
///     DialogMessage("Saved successfully.")
///     DialogIcon { Image(systemName: "checkmark") }
/// }
/// ```
@resultBuilder
public enum ToastComponentBuilder: DialogBuilder {
    public static func buildExpression(_ expression: some ToastComponent) -> [any DialogComponent] {
        [expression]
    }
}

/// Compile-time restrictions for components that are not supported in toasts.
public extension ToastComponentBuilder {
    @available(*, unavailable, message: "DialogTitle is not supported in Toasts. Use DialogMessage instead.")
    static func buildExpression(_ expression: DialogTitle) -> [any DialogComponent] { [] }
}
