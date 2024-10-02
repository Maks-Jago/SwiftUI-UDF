//===--- GlobalRoutingModifier.swift --------------------------------------===//
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

/// A view modifier that integrates a router into the global navigation system.
///
/// The `GlobalRoutingModifier` adds the given router to the `GlobalRouter` environment,
/// allowing for the navigation to routes defined within the router. It also sets up
/// a `navigationDestination` to present the appropriate view for each route using SwiftUI's
/// navigation system.
///
/// ## Generic Parameters:
/// - `R`: A type conforming to `Routing` that defines the navigation routes.
///
/// ## Properties:
/// - `globalRouter`: The global router accessed from the environment.
/// - `router`: The router to be added to the global navigation system.
///
/// ## Initializer:
/// - `init(router:)`: Initializes the modifier with the specified router.
///
/// ## Methods:
/// - `body(content:)`: Modifies the content view to add the router to the global router and
///   set up navigation destinations for the specified routes.
struct GlobalRoutingModifier<R: Routing>: ViewModifier where R.Route: Hashable {
    @Environment(\.globalRouter) var globalRouter
    
    var router: Router<R>
    
    /// Initializes the modifier with the specified router.
    ///
    /// - Parameter router: The router to be added to the global navigation system.
    init(router: Router<R>) {
        self.router = router
    }
    
    /// Modifies the content view to add the router to the global router and set up navigation destinations.
    ///
    /// - Parameter content: The content view to be modified.
    /// - Returns: A view that adds the router to the global navigation system and sets up navigation destinations.
    func body(content: Content) -> some View {
        let _ = self.globalRouter.add(router: router)
        content
            .navigationDestination(
                for: R.Route.self,
                destination: router.view(for:)
            )
    }
}
