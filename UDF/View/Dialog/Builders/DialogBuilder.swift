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
/// ``AlertDialogComponentBuilder``, ``ToastComponentBuilder``, and ``ConfirmationDialogComponentBuilder``
/// only need to define their specific `buildExpression` overloads.
///
/// Conforming types inherit default implementations for all standard result builder
/// control-flow methods (conditionals, optionals, loops, availability checks).
public protocol DialogBuilder {
    /// Supports conditional presentation via `if-else` blocks.
    ///
    /// - Parameter component: The components produced in the `if` branch.
    /// - Returns: An array containing the input components.
    static func buildEither(first component: [any DialogComponent]) -> [any DialogComponent]

    /// Supports conditional presentation via `if-else` blocks.
    ///
    /// - Parameter component: The components produced in the `else` branch.
    /// - Returns: An array containing the input components.
    static func buildEither(second component: [any DialogComponent]) -> [any DialogComponent]

    /// Supports conditional presentation via `if` blocks without an `else` branch.
    ///
    /// - Parameter component: The optional components produced in the `if` block.
    /// - Returns: The array of components if the condition was met, or an empty array otherwise.
    static func buildOptional(_ component: [any DialogComponent]?) -> [any DialogComponent]

    /// Supports empty result builder expressions.
    ///
    /// - Parameter expression: An empty expression.
    /// - Returns: An empty array.
    static func buildExpression(_ expression: ()) -> [any DialogComponent]

    /// Supports result builder expressions using `@available` checks.
    ///
    /// - Parameter components: The components produced within the availability check.
    /// - Returns: An array containing the input components.
    static func buildLimitedAvailability(_ components: [any DialogComponent]) -> [any DialogComponent]

    /// Combines multiple expressions into a single ordered list of components.
    ///
    /// - Parameter components: A variadic list of component arrays produced by the builder's expressions.
    /// - Returns: A flattened array containing all components in the order they were defined.
    static func buildBlock(_ components: [any DialogComponent]...) -> [any DialogComponent]

    /// Supports building components within loops and collections.
    ///
    /// - Parameter components: A nested array of components produced during iteration.
    /// - Returns: A flattened array containing all components collected from the iteration.
    static func buildArray(_ components: [[any DialogComponent]]) -> [any DialogComponent]
}

/// Default implementations for all `DialogBuilder` result builder methods.
public extension DialogBuilder {
    /// Default implementation for `buildEither(first:)` that returns the component array as-is.
    static func buildEither(first component: [any DialogComponent]) -> [any DialogComponent] {
        component
    }

    /// Default implementation for `buildEither(second:)` that returns the component array as-is.
    static func buildEither(second component: [any DialogComponent]) -> [any DialogComponent] {
        component
    }

    /// Default implementation for `buildOptional(_:)` that returns the components or an empty array if nil.
    static func buildOptional(_ component: [any DialogComponent]?) -> [any DialogComponent] {
        component ?? []
    }

    /// Default implementation for `buildExpression(_:)` that returns an empty array.
    static func buildExpression(_ expression: ()) -> [any DialogComponent] {
        []
    }

    /// Default implementation for `buildLimitedAvailability(_:)` that returns the components as-is.
    static func buildLimitedAvailability(_ components: [any DialogComponent]) -> [any DialogComponent] {
        components
    }

    /// Default implementation for `buildBlock(_:)` that flattens the input arrays into a single array.
    static func buildBlock(_ components: [any DialogComponent]...) -> [any DialogComponent] {
        components.flatMap { $0 }
    }

    /// Default implementation for `buildArray(_:)` that flattens nested arrays into a single array.
    static func buildArray(_ components: [[any DialogComponent]]) -> [any DialogComponent] {
        components.flatMap { $0 }
    }
}
