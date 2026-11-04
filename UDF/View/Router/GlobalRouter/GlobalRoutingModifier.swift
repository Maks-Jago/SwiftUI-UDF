//===--- GlobalRoutingModifier.swift --------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

/// A view modifier that registers the routes of one routing type as navigation destinations.
///
/// Each pushed route is resolved by a new instance of the routing. `View/navigationDestination(for:)` applies
/// it, and ``DestinationsBuilder`` creates one for each routing listed in ``FeatureState/destinations``.
///
/// ## Generic Parameters:
/// - `R`: A type conforming to `Routing` that defines the navigation routes.
struct GlobalRoutingModifier<R: Routing>: ViewModifier where R.Route: Hashable {
    /// Creates the modifier for a routing type.
    ///
    /// The initializer is nonisolated so a feature's ``FeatureState/destinations`` can create the modifier
    /// outside the main actor.
    ///
    /// - Parameter routing: The routing type whose routes to register.
    nonisolated init(routing: R.Type) {}

    /// Registers the routing's routes on the navigation stack the content belongs to.
    ///
    /// - Parameter content: The content view to be modified.
    /// - Returns: A view whose navigation stack resolves the routing's routes.
    func body(content: Content) -> some View {
        content
            .navigationDestination(
                for: R.Route.self,
                destination: {
                    R().view(for: $0)
                }
            )
    }
}
