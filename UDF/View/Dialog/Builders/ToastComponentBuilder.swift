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

@resultBuilder
public enum ToastComponentBuilder: DialogBuilder {
    public static func buildExpression(_ expression: some ToastComponent) -> [any DialogComponent] {
        [expression]
    }
}

public extension ToastComponentBuilder {
    @available(*, unavailable, message: "DialogTitle is not supported in Toasts. Use DialogMessage instead.")
    static func buildExpression(_ expression: DialogTitle) -> [any DialogComponent] { [] }
}
