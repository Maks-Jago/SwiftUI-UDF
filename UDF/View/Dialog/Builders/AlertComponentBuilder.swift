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

@resultBuilder
public enum AlertComponentBuilder: DialogBuilder {
    public static func buildExpression(_ expression: some AlertComponent) -> [any DialogComponent] {
        [expression]
    }
}

public extension AlertComponentBuilder {
    @available(*, unavailable, message: "DialogIcon is not supported in Alerts.")
    static func buildExpression(_ expression: DialogIcon) -> [any DialogComponent] { [] }

    @available(*, unavailable, message: "DialogComponentContent is not supported in Alerts.")
    static func buildExpression(_ expression: DialogComponentContent) -> [any DialogComponent] { [] }
}
