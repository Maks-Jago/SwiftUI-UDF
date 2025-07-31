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

/// A global router that manages navigation across the app using either `NavigationPath` or stable `Data` representation.
///
/// The `GlobalRouter` allows for centralized control of navigation actions, including navigating to specific routes,
/// returning to previous views, and resetting the navigation stack. It supports both traditional NavigationPath-based
/// navigation and stable Data-based navigation to prevent container recreation issues.
///
/// ## Properties:
/// - `routingPath`: A binding to the `NavigationPath` used for navigating views.
/// - `stableNavigationState`: Optional stable navigation state for preventing container recreation.
///
/// ## Initializers:
/// - `init(path:)`: Initializes the global router with a `Binding<NavigationPath>`.
/// - `init(stableState:)`: Initializes the global router with stable navigation state.
///
/// ## Methods:
/// - `navigate(for:to:)`: Navigates to a specific route using the provided router.
/// - `navigateStable(for:to:)`: Navigates using stable navigation to prevent container recreation.
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
    private var stableNavigationState: StableNavigationManager?

    /// Initializes the global router with a given navigation path.
    ///
    /// - Parameter path: A binding to a `NavigationPath` used for navigation.
    public init(path: Binding<NavigationPath>) {
        self.routingPath = path
        self.stableNavigationState = nil
    }
    
    /// Initializes the global router with stable navigation state.
    ///
    /// - Parameter stableState: A stable navigation manager that uses Data for navigation state.
    public init(stableState: StableNavigationManager) {
        self.routingPath = stableState.derivedNavigationPath
        self.stableNavigationState = stableState
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
    
    // MARK: - Stable Navigation Methods
    
    /// Navigates to a specified route using stable navigation to prevent container recreation.
    ///
    /// - Parameters:
    ///   - routing: The stable routing type to use for navigation.
    ///   - route: The route to navigate to.
    public func navigateStable<R: StableRouting>(for routing: R.Type, to route: R.Route) where R.Route: Hashable & Codable {
        if let stableState = stableNavigationState {
            stableState.navigate(for: routing, to: route)
        } else {
            // Fallback to regular navigation if no stable state is available
            routingPath.wrappedValue.append(route)
        }
    }
    
    /// Navigates back using stable navigation.
    public func backStable() {
        if let stableState = stableNavigationState {
            stableState.back()
        } else {
            back()
        }
    }
    
    /// Navigates back a specified number of steps using stable navigation.
    ///
    /// - Parameter stepsCount: The number of steps to navigate back.
    public func backStable(stepsCount: Int) {
        if let stableState = stableNavigationState {
            stableState.back(steps: stepsCount)
        } else {
            back(stepsCount: stepsCount)
        }
    }
    
    /// Navigates back to the root using stable navigation.
    public func backToRootStable() {
        if let stableState = stableNavigationState {
            stableState.backToRoot()
        } else {
            backToRoot()
        }
    }
    
    /// Resets the navigation stack and navigates to a specific route using stable navigation.
    ///
    /// - Parameters:
    ///   - routing: The stable routing type to use for navigation.
    ///   - route: The route to navigate to.
    public func resetStackStable<R: StableRouting>(routing: R.Type, to route: R.Route) where R.Route: Hashable & Codable {
        if let stableState = stableNavigationState {
            stableState.resetStack(routing: routing, to: route)
        } else {
            resetStack(routing: routing, to: route)
        }
    }
}

private struct GlobalRouterKey: @preconcurrency EnvironmentKey {
    @MainActor static var defaultValue: GlobalRouter = .init(path: .constant(NavigationPath()))
}

public extension EnvironmentValues {
    /// Provides access to the global router from the environment.
    var globalRouter: GlobalRouter {
        get { self[GlobalRouterKey.self] }
        set { self[GlobalRouterKey.self] = newValue }
    }
}
