//===--- Router.swift ------------------------------------------===//
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

/// A protocol that defines routing logic for navigating to different views within the application.
///
/// The `Routing` protocol provides an abstraction for routing between different views based on a specific `Route` type.
/// Conforming types must implement the `view(for:)` method to return the appropriate destination view for a given route.
///
/// ## Associated Types:
/// - `Route`: A type that defines the various routes available for navigation.
/// - `Destination`: A `View` that represents the destination for a specific route.
///
/// ## Requirements:
/// - `view(for:)`: A method that returns a `Destination` view for a given route.
///
/// ## Example:
/// ```swift
/// struct ExampleRouting: Routing {
///     enum Route: Hashable {
///         case details
///     }
///
///     @ViewBuilder
///     func view(for route: Route) -> some View {
///         switch route {
///         case .details:
///             DetailsView()
///         }
///     }
/// }
/// ```
public protocol Routing<Route>: Initable {
    associatedtype Route
    associatedtype Destination: View
    
    /// Returns a view for the given route.
    ///
    /// - Parameter route: The route that defines the destination view to navigate to.
    /// - Returns: A view that corresponds to the specified route.
    func view(for route: Route) -> Self.Destination
}

/// A generic router that handles navigation based on a specified routing logic (`Routing`).
///
/// The `Router` class uses a routing type conforming to `Routing` to determine the view to display for a given route.
/// It supports view mocking for testing purposes, allowing an alternative view to be presented based on a route.
///
/// ## Generic Parameters:
/// - `R`: A type conforming to the `Routing` protocol.
///
/// ## Properties:
/// - `routing`: An instance of the routing logic that defines the view for each route.
/// - `mocker`: An optional closure used for mocking views during testing.
///
/// ## Initializers:
/// - `init(routing:)`: Initializes the router with a specified routing instance.
/// - `init()`: Initializes the router with a default instance of the routing type.
/// - `init<MockView: View>(routing:mocked:)`: Initializes the router with a routing instance and a view builder for mocking.
///
/// ## Methods:
/// - `view(for:)`: Returns the view corresponding to a specified route, using the mock view if available.
public final class Router<R: Routing> {
    private typealias MockedBuilder = (_ routing: R, _ route: R.Route) -> AnyView
    
    /// The routing instance that defines the view for each route.
    public var routing: R
    
    /// An optional closure used to provide a mock view for a given route.
    private var mocker: MockedBuilder?
    
    /// Initializes the router with a specified routing instance.
    ///
    /// - Parameter routing: The routing instance that defines the view for each route.
    public init(routing: R) {
        self.routing = routing
        self.mocker = nil
    }
    
    /// Initializes the router with a default instance of the routing type.
    public init() {
        self.routing = R.init()
        self.mocker = nil
    }
    
    /// Initializes the router with a routing instance and a view builder for mocking views.
    ///
    /// - Parameters:
    ///   - routing: The routing instance that defines the view for each route.
    ///   - mocked: A closure that returns a mock view for a given route, used for testing purposes.
    public init<MockView: View>(routing: R, @ViewBuilder mocked: @escaping (_ routing: R, _ route: R.Route) -> MockView) {
        self.routing = routing
        self.mocker = { routing, route in
            AnyView(mocked(routing, route))
        }
    }
    
    /// Returns the view corresponding to the specified route, using the mock view if available.
    ///
    /// - Parameter route: The route that defines the destination view.
    /// - Returns: A view that corresponds to the specified route.
    @ViewBuilder
    public func view(for route: R.Route) -> some View {
        if let mocker {
            mocker(routing, route)
        } else {
            routing.view(for: route)
        }
    }
}
