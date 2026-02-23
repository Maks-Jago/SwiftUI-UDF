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

@resultBuilder
public enum ConfirmationDialogComponentBuilder: DialogBuilder {
    public static func buildExpression(_ expression: some ConfirmationDialogComponent) -> [any DialogComponent] {
        [expression]
    }
}

public extension ConfirmationDialogComponentBuilder {
    @available(*, unavailable, message: "DialogIcon is not supported in Confirmation Dialogs.")
    static func buildExpression(_ expression: DialogIcon) -> [any DialogComponent] { [] }

    @available(*, unavailable, message: "DialogComponentContent is not supported in Confirmation Dialogs.")
    static func buildExpression(_ expression: DialogComponentContent) -> [any DialogComponent] { [] }
}
