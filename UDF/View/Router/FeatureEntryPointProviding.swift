//===--- FeatureEntryPointProviding.swift -----------------------------------===//
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

/// Builds the entry views of the other features that a feature leads to.
///
/// A feature never imports another feature. It declares the screens of other features it leads to as a public
/// enum, its entry points, and requires a provider of them. The composing app conforms one provider per feature
/// and builds each entry point with the other feature's ``FeatureState/entryPoint(input:)``:
///
/// ```swift
/// // In the Profile feature module, the screens of other features it depends on:
/// public enum ProfileRouteDependency {
///     case itemDetails(any Item)
/// }
///
/// public protocol ProfileFeature: AppReducer {
///     associatedtype ProfileEntryPoints: FeatureEntryPointProviding<ProfileRouteDependency>
/// }
///
/// // Inside a routing of the feature, a case shows the other feature:
/// AppState.ProfileEntryPoints().view(for: .itemDetails(item))
///
/// // In the app, one provider covers the entry points of the feature:
/// extension AppState {
///     struct ProfileEntryPoints: FeatureEntryPointProviding {
///         func view(for entryPoint: ProfileRouteDependency) -> some View {
///             switch entryPoint {
///             case let .itemDetails(item):
///                 ItemDetailsFeatureState<AppState>.entryPoint(input: item.id)
///             }
///         }
///     }
/// }
/// ```
///
/// A provider is not a ``Routing``. The compiler rejects it in ``FeatureState/destinations`` and in
/// `navigationDestinations(for:)`, so the app never registers it. It is only called from the feature's own
/// routings. A component that pushes an entry point through a ``Router`` does so with a routing of the feature
/// that forwards each value to the provider.
///
/// Each feature names its requirement after itself, such as `ProfileEntryPoints` and `SearchEntryPoints`. The
/// app's nested type must carry that name, and a shared name would force every feature's entry points into one
/// type.
public protocol FeatureEntryPointProviding<EntryPoint>: Initable {
    /// The screens of other features that a feature leads to.
    associatedtype EntryPoint

    /// The entry view built for one entry point.
    associatedtype Destination: View

    /// Builds the entry view of the feature that an entry point leads to.
    ///
    /// The requirement is a view builder, so a conforming type's implementation is one too without writing
    /// `@ViewBuilder`.
    ///
    /// - Parameter entryPoint: The screen of another feature to build.
    /// - Returns: The entry view of that feature.
    @ViewBuilder
    func view(for entryPoint: EntryPoint) -> Destination
}
