//===--- NavigatingFeatureState.swift -----------------------------===//
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

/// A feature that moves between several of its own screens on the navigation stack hosting it.
///
/// A navigation stack shows a pushed value only when a destination for that value's type is registered
/// on the stack. A feature's screens push routes that are internal to its module, so the composing app
/// cannot register them itself. The feature lists the routings of those screens in ``destinations``, and
/// the app registers all of them with one call on every navigation stack the feature can appear on:
///
/// ```swift
/// public struct ProfileFeatureState<
///     AppState: ProfileFeature,
///     FeatureRouting: Routing<ProfileRoute>
/// >: NavigatingFeatureState {
///     // …
///
///     public static var destinations: some ViewModifier {
///         ProfileRouting<AppState>.self
///         EditProfileRouting<AppState>.self
///     }
/// }
///
/// // The app, on the root of each navigation stack:
/// TabRoot()
///     .navigationDestinations(for: ProfileFeatureState<AppState, AppProfileRouting>.self)
/// ```
///
/// Routes that leave the feature are still resolved by ``FeatureState/FeatureRouting``, which the app
/// implements. `destinations` covers only the screens the feature resolves itself. A feature with a
/// single screen has nothing to register and conforms to ``FeatureState`` alone.
///
/// - Important: `destinations` has no default implementation, and none should be added. In generic code a
///   default would be used instead of the feature's own list, and its pushes would silently show nothing.
///   Without a default, a feature that leaves the list out does not compile.
///
/// - SeeAlso: ``DeepLinkableFeatureState``, for screens the app may open directly.
public protocol NavigatingFeatureState: FeatureState {
    /// The modifier that registers the feature's internal screens.
    ///
    /// Inferred from ``destinations``, so a conforming feature writes `some ViewModifier` and never names
    /// this type.
    associatedtype Destinations: ViewModifier

    /// The routings of the screens the feature pushes internally, one per line.
    @DestinationsBuilder
    static var destinations: Destinations { get }
}

public extension View {
    /// Lets the navigation stack this view is the root of show every screen a feature pushes internally.
    ///
    /// Apply it once per feature on each navigation stack the feature can appear on. The app does not need
    /// to know which screens the feature registers.
    ///
    /// - Parameter feature: The feature whose ``NavigatingFeatureState/destinations`` to register.
    /// - Returns: A view whose navigation stack resolves the feature's internal routes.
    func navigationDestinations<Feature: NavigatingFeatureState>(for feature: Feature.Type) -> some View {
        modifier(Feature.destinations)
    }
}
