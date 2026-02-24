//===--- AlertComponentBuilder.swift ---------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

/// A result builder for constructing the component list of an ``Alert``.
///
/// Only types conforming to ``AlertComponent`` are accepted. Attempting to use
/// unsupported components like ``DialogIcon`` or ``DialogView`` will
/// produce a compile-time error with a descriptive message.
///
/// ```swift
/// Alert {
///     DialogTitle("Error")
///     DialogMessage("Something went wrong.")
///     DialogButton(title: "OK")
/// }
/// ```
@resultBuilder
public enum AlertComponentBuilder: DialogBuilder {
    public static func buildExpression(_ expression: some AlertComponent) -> [any DialogComponent] {
        [expression]
    }
}

/// Compile-time restrictions for components that are not supported in alerts.
public extension AlertComponentBuilder {
    @available(*, unavailable, message: "DialogIcon is not supported in Alerts.")
    static func buildExpression(_ expression: DialogIcon) -> [any DialogComponent] { [] }

    @available(*, unavailable, message: "DialogView is not supported in Alerts.")
    static func buildExpression(_ expression: DialogView) -> [any DialogComponent] { [] }
}
