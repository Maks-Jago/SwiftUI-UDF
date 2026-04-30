//===--- NavigationStackBound.swift ----------------------------------------===//
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

/// A view that stabilizes the identity of a `NavigationStack`'s path binding.
///
/// In UDF, bindings are often projected from a central store. If the store's state changes,
/// the binding's identity can change, causing SwiftUI to speculatively re-evaluate
/// the navigation tree. This leads to phantom `@StateObject` allocations and spurious
/// `onContainerDidLoad`/`onContainerDidUnload` triggers in descendant views.
///
/// `NavigationStackBound` insulates the `NavigationStack` from this churn by maintaining
/// a local, identity-stable `@State` copy of the path, which it synchronizes with the
/// external UDF state.
///
/// - Parameters:
///   - Data: The type of the navigation path (e.g., `NavigationPath` or `Array`).
///   - Content: The type of the underlying `NavigationStack`.
public struct NavigationStackBound<Data: Equatable, Content: View>: View {
    /// The externally-owned path, typically projected from UDF state.
    @Binding private var external: Data
    
    /// Stable, locally-owned path used to prevent identity churn.
    @State private var local: Data
    
    /// Internal closure that constructs the underlying `NavigationStack` using the stabilized path.
    private let content: (Binding<Data>) -> Content

    /// Creates a `NavigationStackBound` that bridges an external `NavigationPath`
    /// to an internal identity-stable `@State` path.
    ///
    /// - Parameters:
    ///   - path: A binding to the external `NavigationPath`.
    ///   - root: A view builder that creates the root view of the navigation stack.
    public init<Root: View>(
        path: Binding<NavigationPath>,
        @ViewBuilder root: @escaping () -> Root
    ) where Data == NavigationPath, Content == NavigationStack<NavigationPath, Root> {
        self._external = path
        self._local = State(initialValue: path.wrappedValue)
        
        self.content = { boundPath in
            SwiftUI.NavigationStack(path: boundPath, root: root)
        }
    }

    /// Creates a `NavigationStackBound` that bridges an external collection-based path
    /// (e.g. `Array<Hashable>`) to an internal identity-stable `@State` path.
    ///
    /// - Parameters:
    ///   - path: A binding to the external collection-based path.
    ///   - root: A view builder that creates the root view of the navigation stack.
    public init<Root: View>(
        path: Binding<Data>,
        @ViewBuilder root: @escaping () -> Root
    ) where Data: MutableCollection & RandomAccessCollection & RangeReplaceableCollection,
            Data.Element: Hashable,
            Content == NavigationStack<Data, Root> {
        self._external = path
        self._local = State(initialValue: path.wrappedValue)
        
        self.content = { boundPath in
            SwiftUI.NavigationStack(path: boundPath, root: root)
        }
    }

    public var body: some View {
        content($local)
            .onChange(of: external) { newExternal in
                guard local != newExternal else { return }
                local = newExternal
            }
            .onChange(of: local) { newLocal in
                guard external != newLocal else { return }
                external = newLocal
            }
    }
}
