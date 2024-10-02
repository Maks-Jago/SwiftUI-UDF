//===--- GlobalRouter.swift -------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
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
/// - `routers`: A list of weak references to registered routers for managing navigation routes.
/// 
/// ## Initializers:
/// - `init(path:)`: Initializes the global router with a `Binding<NavigationPath>`.
/// 
/// ## Methods:
/// - `add(router:)`: Registers a router to the global router.
/// - `navigate(to:with:)`: Navigates to a specific route using the provided router.
/// - `backToRoot()`: Navigates back to the root of the navigation stack.
/// - `back()`: Navigates back one step in the navigation stack.
/// - `back(stepsCount:)`: Navigates back a specified number of steps in the navigation stack.
/// - `resetStack(to:with:)`: Resets the navigation stack and navigates to a specific route.
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
    private var routers: [Weak] = []
    
    /// Initializes the global router with a given navigation path.
    ///
    /// - Parameter path: A binding to a `NavigationPath` used for navigation.
    public init(path: Binding<NavigationPath>) {
        self.routingPath = path
    }
    
    /// Registers a router to the global router.
    ///
    /// - Parameter router: The router to add.
    func add<R: Routing>(router: Router<R>) {
        routers.reap()
        routers.append(.init(value: router))
    }
    
    /// Navigates to a specified route using the provided router.
    ///
    /// - Parameters:
    ///   - route: The route to navigate to.
    ///   - router: The router to use for navigation.
    public func navigate<R: Routing>(to route: R.Route, with router: Router<R>) where R.Route: Hashable {
        let registeredRoute = routers.first { obj in
            guard let value = obj.value else {
                return false
            }
            
            return ObjectIdentifier(value) == ObjectIdentifier(router)
        }
        
        guard registeredRoute != nil else {
            fatalError("Router: \(router) is not attached to the view hierarchy. Use `navigationDestination(router:)` to add router")
        }
        
        routers.reap()
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
    ///   - route: The route to navigate to.
    ///   - router: The router to use for navigation.
    public func resetStack<R: Routing>(to route: R.Route, with router: Router<R>) where R.Route: Hashable {
        routingPath.wrappedValue.removeLast(routingPath.wrappedValue.count)
        navigate(to: route, with: router)
    }
}

private struct GlobalRouterKey: EnvironmentKey {
    static var defaultValue: GlobalRouter = GlobalRouter(path: .constant(NavigationPath()))
}

public extension EnvironmentValues {
    /// Provides access to the global router from the environment.
    var globalRouter: GlobalRouter {
        get { self[GlobalRouterKey.self] }
        set { self[GlobalRouterKey.self] = newValue }
    }
}
