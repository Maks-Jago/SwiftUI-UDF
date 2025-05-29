//===--- GlobalRouter.swift -------------------------------------===//
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

/// A global router that manages navigation across the app using a unified `NavigationPath`.
///
/// The `GlobalRouter` allows for centralized control of navigation actions, including navigating to specific routes,
/// returning to previous views, and resetting the navigation stack. It works with instances of `Router` and conforms
/// to a path-binding mechanism to update the view hierarchy.
///
/// ## Properties:
/// - `routingPath`: A binding to the `NavigationPath` used for navigating views.
///
/// ## Initializers:
/// - `init(path:)`: Initializes the global router with a `Binding<NavigationPath>`.
///
/// ## Methods:
/// - `navigate(for:to:)`: Navigates to a specific route using the provided router.
/// - `backToRoot()`: Navigates back to the root of the navigation stack.
/// - `back()`: Navigates back one step in the navigation stack.
/// - `back(stepsCount:)`: Navigates back a specified number of steps in the navigation stack.
/// - `resetStack(routing:to:)`: Resets the navigation stack and navigates to a specific route.
///
/// ## Example of Injection:
/// ```swift
/// NavigationStack(path: props.navigationPath) {
///     props.router.view(for: .home)
/// }
/// .tag(TabItem.home)
/// .environment(\.globalRouter, GlobalRouter(path: props.navigationPath))
/// ```
///
/// ## Example of Usage in a Container or Component:
/// ```swift
/// @Environment(\.globalRouter) private var globalRouter
/// ```
public final class GlobalRouter {
    private var routingPath: Binding<NavigationPath>

    /// Initializes the global router with a given navigation path.
    ///
    /// - Parameter path: A binding to a `NavigationPath` used for navigation.
    public init(path: Binding<NavigationPath>) {
        self.routingPath = path
    }

    /// Navigates to a specified route.
    ///
    /// - Parameters:
    ///   - routing: The routing type to use for navigation.
    ///   - route: The route to navigate to.
    public func navigate<R: Routing>(for routing: R.Type, to route: R.Route) where R.Route: Hashable {
        routingPath.wrappedValue.append(route)
    }

    /// Navigates back to the root of the navigation stack.
    public func backToRoot() {
        guard !routingPath.wrappedValue.isEmpty else {
            return
        }
        routingPath.wrappedValue.removeLast(routingPath.wrappedValue.count)
    }

    /// Navigates back one step in the navigation stack.
    public func back() {
        guard !routingPath.wrappedValue.isEmpty else {
            return
        }
        routingPath.wrappedValue.removeLast()
    }

    /// Navigates back a specified number of steps in the navigation stack.
    ///
    /// - Parameter stepsCount: The number of steps to navigate back.
    public func back(stepsCount: Int) {
        guard !routingPath.wrappedValue.isEmpty else {
            return
        }
        routingPath.wrappedValue.removeLast(stepsCount)
    }

    /// Resets the navigation stack and navigates to a specific route.
    ///
    /// - Parameters:
    ///   - routing: The routing type to use for navigation.
    ///   - route: The route to navigate to.
    public func resetStack<R: Routing>(routing: R.Type, to route: R.Route) where R.Route: Hashable {
        var newPath = NavigationPath()
        newPath.append(route)
        routingPath.wrappedValue = newPath
    }
}

private struct GlobalRouterKey: EnvironmentKey {
    static var defaultValue: GlobalRouter = .init(path: .constant(NavigationPath()))
}

public extension EnvironmentValues {
    /// Provides access to the global router from the environment.
    var globalRouter: GlobalRouter {
        get { self[GlobalRouterKey.self] }
        set { self[GlobalRouterKey.self] = newValue }
    }
}
