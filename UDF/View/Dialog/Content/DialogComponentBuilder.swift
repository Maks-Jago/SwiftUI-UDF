//===--- DialogComponentBuilder.swift ----------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2025 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

@resultBuilder
public enum DialogComponentBuilder {
    public static func buildEither(first component: [any DialogComponent]) -> [any DialogComponent] {
        component
    }
    public static func buildEither(second component: [any DialogComponent]) -> [any DialogComponent] {
        component
    }
    public static func buildOptional(_ component: [any DialogComponent]?) -> [any DialogComponent] {
        component ?? []
    }
    public static func buildExpression(_ expression: some DialogComponent) -> [any DialogComponent] {
        [expression]
    }
    public static func buildExpression(_ expression: ()) -> [any DialogComponent] {
        []
    }
    public static func buildLimitedAvailability(_ components: [any DialogComponent]) -> [any DialogComponent] {
        components
    }
    public static func buildBlock(_ components: [any DialogComponent]...) -> [any DialogComponent] {
        components.flatMap { $0 }
    }
    public static func buildArray(_ components: [[any DialogComponent]]) -> [any DialogComponent] {
        components.flatMap { $0 }
    }
}
