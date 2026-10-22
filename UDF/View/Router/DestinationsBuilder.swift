//===--- DestinationsBuilder.swift --------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI

/// A result builder that combines routing types into one modifier registering all of their routes.
///
/// Each line names a routing type. Its routes become navigation destinations that the routing resolves.
/// An empty block registers nothing.
///
/// ```swift
/// public static var destinations: some ViewModifier {
///     ProfileRouting<AppState>.self
///     EditProfileRouting<AppState>.self
/// }
/// ```
@resultBuilder
public enum DestinationsBuilder {
    /// Turns a routing type into the modifier that registers its routes.
    ///
    /// - Parameter routing: A routing type whose routes the navigation stack should resolve.
    /// - Returns: A modifier registering the routing's routes.
    public static func buildExpression<R: Routing>(_ routing: R.Type) -> RoutingDestination<R> where R.Route: Hashable {
        RoutingDestination()
    }

    /// Registers nothing, for a block that lists no routings.
    ///
    /// - Returns: A modifier that leaves the view unchanged.
    public static func buildBlock() -> EmptyModifier {
        .identity
    }

    /// Starts the combined modifier with the first listed routing.
    ///
    /// - Parameter first: The modifier for the first routing.
    /// - Returns: The same modifier.
    public static func buildPartialBlock<First: ViewModifier>(first: First) -> First {
        first
    }

    /// Adds the next listed routing to the modifiers combined so far.
    ///
    /// - Parameters:
    ///   - accumulated: The modifier combined from the routings listed before.
    ///   - next: The modifier for the next routing.
    /// - Returns: A modifier applying both.
    public static func buildPartialBlock<Accumulated: ViewModifier, Next: ViewModifier>(
        accumulated: Accumulated,
        next: Next
    ) -> ModifiedContent<Accumulated, Next> {
        ModifiedContent(content: accumulated, modifier: next)
    }
}
