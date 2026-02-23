//===--- DialogBuilder.swift ---------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

public protocol DialogBuilder {
    static func buildEither(first component: [any DialogComponent]) -> [any DialogComponent]
    static func buildEither(second component: [any DialogComponent]) -> [any DialogComponent]
    static func buildOptional(_ component: [any DialogComponent]?) -> [any DialogComponent]
    static func buildExpression(_ expression: ()) -> [any DialogComponent]
    static func buildLimitedAvailability(_ components: [any DialogComponent]) -> [any DialogComponent]
    static func buildBlock(_ components: [any DialogComponent]...) -> [any DialogComponent]
    static func buildArray(_ components: [[any DialogComponent]]) -> [any DialogComponent]
}

public extension DialogBuilder {
    static func buildEither(first component: [any DialogComponent]) -> [any DialogComponent] {
        component
    }
    static func buildEither(second component: [any DialogComponent]) -> [any DialogComponent] {
        component
    }
    static func buildOptional(_ component: [any DialogComponent]?) -> [any DialogComponent] {
        component ?? []
    }
    static func buildExpression(_ expression: ()) -> [any DialogComponent] {
        []
    }
    static func buildLimitedAvailability(_ components: [any DialogComponent]) -> [any DialogComponent] {
        components
    }
    static func buildBlock(_ components: [any DialogComponent]...) -> [any DialogComponent] {
        components.flatMap { $0 }
    }
    static func buildArray(_ components: [[any DialogComponent]]) -> [any DialogComponent] {
        components.flatMap { $0 }
    }
}
