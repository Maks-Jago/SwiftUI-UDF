//===--- NavigationStack+Deprecated.swift ----------------------------------===//
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

/// An internal protocol used to unify the generic constraints of `NavigationPath` and `Array`.
///
/// This protocol exists solely to work around Swift compiler limitations regarding function overloading
/// and generic constraints. By having both `NavigationPath` and `Array` conform to this protocol,
/// we can provide a **single** global `NavigationStack` shadow function, rather than two separate overloads.
/// This completely eliminates "Ambiguous use of NavigationStack" errors when developers use the standard
/// `NavigationStack` API.
public protocol _UDFBindablePath {
    /// Builds and returns the underlying native `SwiftUI.NavigationStack`.
    ///
    /// - Parameters:
    ///   - path: The binding to the navigation path.
    ///   - root: The root view of the navigation stack.
    /// - Returns: A standard `SwiftUI.NavigationStack`.
    @MainActor
    static func _buildStack<Root: View>(
        path: Binding<Self>,
        @ViewBuilder root: @escaping () -> Root
    ) -> SwiftUI.NavigationStack<Self, Root>
}

extension NavigationPath: _UDFBindablePath {
    @MainActor
    public static func _buildStack<Root: View>(
        path: Binding<NavigationPath>,
        @ViewBuilder root: @escaping () -> Root
    ) -> SwiftUI.NavigationStack<NavigationPath, Root> {
        SwiftUI.NavigationStack(path: path, root: root)
    }
}

extension Array: _UDFBindablePath where Element: Hashable {
    @MainActor
    public static func _buildStack<Root: View>(
        path: Binding<Array<Element>>,
        @ViewBuilder root: @escaping () -> Root
    ) -> SwiftUI.NavigationStack<Array<Element>, Root> {
        SwiftUI.NavigationStack(path: path, root: root)
    }
}

/// A global shadow function that overrides the standard `NavigationStack` initializers to emit a compile-time warning.
///
/// ## Why this exists
///
/// Using SwiftUI's native `NavigationStack(path:)` with a binding projected from UDF state causes
/// unstable binding identities. This instability forces SwiftUI to speculatively re-evaluate the
/// navigation tree on every state update, leading to phantom `@StateObject` allocations and spurious
/// `onContainerDidLoad` / `onContainerDidUnload` lifecycle triggers.
///
/// This function intercepts those calls and issues a deprecation warning, instructing developers to
/// switch to `NavigationStackBound`, which encapsulates the native stack while stabilizing the binding identity.
///
/// - Parameters:
///   - path: The binding to the navigation path (either `NavigationPath` or `Array`).
///   - root: The root view of the stack.
/// - Returns: A standard `SwiftUI.NavigationStack` (with a compiler warning).
@available(*, deprecated, message: "UDF Warning: Use NavigationStackBound when binding to UDF-managed state to prevent transient view lifecycle issues.")
@MainActor
public func NavigationStack<Data: _UDFBindablePath, Root: View>(
    path: Binding<Data>,
    @ViewBuilder root: @escaping () -> Root
) -> SwiftUI.NavigationStack<Data, Root> {
    Data._buildStack(path: path, root: root)
}
