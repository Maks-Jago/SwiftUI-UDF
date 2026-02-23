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

/// A base protocol providing common result builder methods for dialog component builders.
///
/// `DialogBuilder` abstracts the shared `buildBlock`, `buildEither`, `buildOptional`,
/// `buildArray`, and other result builder methods so that concrete builders like
/// ``AlertComponentBuilder``, ``ToastComponentBuilder``, and ``ConfirmationDialogComponentBuilder``
/// only need to define their specific `buildExpression` overloads.
///
/// Conforming types inherit default implementations for all standard result builder
/// control-flow methods (conditionals, optionals, loops, availability checks).
public protocol DialogBuilder {
    static func buildEither(first component: [any DialogComponent]) -> [any DialogComponent]
    static func buildEither(second component: [any DialogComponent]) -> [any DialogComponent]
    static func buildOptional(_ component: [any DialogComponent]?) -> [any DialogComponent]
    static func buildExpression(_ expression: ()) -> [any DialogComponent]
    static func buildLimitedAvailability(_ components: [any DialogComponent]) -> [any DialogComponent]
    static func buildBlock(_ components: [any DialogComponent]...) -> [any DialogComponent]
    static func buildArray(_ components: [[any DialogComponent]]) -> [any DialogComponent]
}

/// Default implementations for all `DialogBuilder` result builder methods.
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
