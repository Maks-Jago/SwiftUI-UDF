//===--- DeepLinkableFeatureState.swift ---------------------------===//
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

/// A feature that lets the app open some of its screens directly by their link.
///
/// The feature resolves those screens in an ordinary ``Routing``, its ``LinkRouting``, whose routes are the
/// feature's links. The app owns URLs and tabs: it turns an incoming URL into a path of links and puts that
/// path on a navigation stack, so the feature never learns where a link came from.
///
/// A link carries only what its screen needs to open with nothing loaded, usually identifiers. The feature
/// pushes the same values itself, so every linkable screen has exactly one address:
///
/// ```swift
/// public enum ProfileLink: Hashable, Sendable {
///     case profile(User.ID)
///     case followers(User.ID)
/// }
///
/// public struct ProfileLinkRouting<AppState: ProfileFeature>: Routing {
///     public init() {}
///
///     public func view(for link: ProfileLink) -> some View {
///         switch link {
///         case let .profile(id):
///             ProfileContainer<AppState>(id: id)
///         case let .followers(id):
///             FollowersContainer<AppState>(userID: id)
///         }
///     }
/// }
///
/// public struct ProfileFeatureState<
///     AppState: ProfileFeature,
///     FeatureRouting: Routing<ProfileRoute>
/// >: DeepLinkableFeatureState {
///     public typealias LinkRouting = ProfileLinkRouting<AppState>
///
///     // …
/// }
///
/// // Inside the feature, the same value pushes the screen:
/// globalRouter.navigate(for: ProfileLinkRouting<AppState>.self, to: .followers(user.id))
///
/// // In the app, a link from a URL replaces the stack:
/// store.dispatch(Actions.NavigateResetStack(path: [ProfileLink.profile(id), ProfileLink.followers(id)]))
/// ```
///
/// A linked screen can open with nothing loaded, so it loads what it shows from the link's values.
///
/// Deep linking does not require internal navigation. A single-screen feature conforms to this protocol
/// alone; a feature with several screens conforms to ``NavigatingFeatureState`` as well. Either way the app
/// registers it with the same `navigationDestinations(for:)` call.
public protocol DeepLinkableFeatureState: FeatureState {
    /// The routing of the screens the app may open directly. Its routes are the feature's links.
    ///
    /// Routes must be `Hashable` for a navigation stack to resolve them and `Sendable` for the app to put
    /// them in navigation actions.
    associatedtype LinkRouting: Routing where LinkRouting.Route: Hashable & Sendable
}

public extension View {
    /// Lets the navigation stack this view is the root of show every screen a feature exposes as a link.
    ///
    /// - Parameter feature: The feature whose ``DeepLinkableFeatureState/LinkRouting`` to register.
    /// - Returns: A view whose navigation stack resolves the feature's links.
    func navigationDestinations<Feature: DeepLinkableFeatureState>(for feature: Feature.Type) -> some View {
        modifier(RoutingDestination<Feature.LinkRouting>())
    }

    /// Lets the navigation stack this view is the root of show every screen a feature pushes internally and
    /// every screen it exposes as a link.
    ///
    /// A feature that conforms to both protocols matches both single-protocol overloads. This overload is
    /// more specific than either, so the compiler chooses it and the call stays unambiguous.
    ///
    /// - Parameter feature: The feature whose destinations and link routing to register.
    /// - Returns: A view whose navigation stack resolves the feature's internal routes and links.
    func navigationDestinations<Feature: NavigatingFeatureState & DeepLinkableFeatureState>(
        for feature: Feature.Type
    ) -> some View {
        modifier(Feature.destinations)
            .modifier(RoutingDestination<Feature.LinkRouting>())
    }
}
