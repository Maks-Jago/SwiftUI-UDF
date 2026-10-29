//===--- RoutingDestination.swift ---------------------------------===//
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

/// A modifier that registers the routes of one routing type as navigation destinations.
///
/// ``DestinationsBuilder`` creates one for each routing listed in ``FeatureState/destinations``.
public struct RoutingDestination<R: Routing>: ViewModifier where R.Route: Hashable {
    nonisolated init() {}

    public func body(content: Content) -> some View {
        content.navigationDestination(for: R.Route.self) { route in
            R().view(for: route)
        }
    }
}
