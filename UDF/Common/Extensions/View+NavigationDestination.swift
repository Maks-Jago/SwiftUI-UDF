//===--- View+NavigationDestination.swift -----------------------===//
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

#if os(iOS)
    public extension View {
        /// Presents a destination view based on the selected route using the specified router.
        ///
        /// This method modifies the view to present a destination view when a route is selected, using a binding to an optional route.
        /// It listens for changes to `selectedRoute` and displays the appropriate view using the `Router`.
        ///
        /// - Parameters:
        ///   - router: A `Router` instance that provides the destination view for the specified route.
        ///   - selectedRoute: A binding to an optional route, indicating the selected route to navigate to.
        /// - Returns: A modified view that presents the destination view when a route is selected.
        /// Example usage:
        /// Example usage:
        /// ```swift
        /// struct ContentView: Component {
        ///     struct Props {
        ///         let router: Router<MyRouting>
        ///     }
        ///
        ///     @State private var selectedRoute: MyRouting.Route? = nil
        ///     var props: Props
        ///
        ///     var body: some View {
        ///         NavigationStack {
        ///             Text("Main View")
        ///                 .navigationDestination(router: props.router, selectedRoute: $selectedRoute)
        ///         }
        ///     }
        /// }
        /// ```
        func navigationDestination<R: Routing>(router: Router<R>, selectedRoute: Binding<R.Route?>) -> some View {
            self.navigationDestination(isPresented: selectedRoute.isPresented()) {
                if let route = selectedRoute.wrappedValue {
                    router.view(for: route)
                }
            }
        }

        /// Presents a destination view using the specified router and adds global navigation support.
        ///
        /// This method modifies the view to support navigation destinations using the given `Router` and `GlobalRoutingModifier`.
        ///
        /// - Parameter router: A `Router` instance that provides the destination views for the routes.
        /// - Returns: A modified view that integrates global navigation support using the provided router.
        /// Example usage:
        /// ```swift
        /// struct ContentView: Component {
        ///     struct Props {
        ///         let router: Router<MyRouting>
        ///     }
        ///
        ///     var props: Props
        ///     @Environment(\.globalRouter) private var globalRouter
        ///
        ///     var body: some View {
        ///         NavigationStack {
        ///             VStack {
        ///                Text("Main View")
        ///                 Button("Tap me") {
        ///                     globalRouter.navigate(to: .someView, with: props.router)
        ///                 }
        ///             }
        ///             .navigationDestination(router: props.router)
        ///         }
        ///     }
        /// }
        /// ```
        func navigationDestination<R: Routing>(router: Router<R>) -> some View where R.Route: Hashable {
            modifier(GlobalRoutingModifier(router: router))
        }
    }
#endif

private extension Binding {
    /// Converts an optional binding to a boolean binding that indicates whether the value is present.
    ///
    /// - Returns: A boolean binding that is `true` if the wrapped value is not `nil`, and `false` otherwise.
    func isPresented<T>() -> Binding<Bool> where Value == T? {
        Binding<Bool>(
            get: {
                switch self.wrappedValue {
                case .some: true
                case .none: false
                }
            },
            set: {
                if !$0 {
                    self.wrappedValue = nil
                }
            }
        )
    }
}
