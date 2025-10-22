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
        /// Presents a destination view using the specified router and adds global navigation support.
        ///
        /// This method modifies the view to support navigation destinations using the given `Router` and `GlobalRoutingModifier`.
        ///
        /// - Parameter routing: A `Routing` type that provides the destination views for the routes.
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
        ///             .navigationDestination(for: MyRouting.self)
        ///             .navigationDestination(for: AnotherRouting.self)
        ///         }
        ///     }
        /// }
        /// ```
        func navigationDestination<R: Routing>(for routing: R.Type) -> some View where R.Route: Hashable {
            modifier(GlobalRoutingModifier(routing: routing))
        }
    }
#endif

private extension Binding {
    /// Converts an optional binding to a boolean binding that indicates whether the value is present.
    ///
    /// - Returns: A boolean binding that is `true` if the wrapped value is not `nil`, and `false` otherwise.
    func isPresented<T: Sendable>() -> Binding<Bool> where Value == T? {
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
