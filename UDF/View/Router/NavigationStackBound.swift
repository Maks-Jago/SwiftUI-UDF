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

import Foundation
import SwiftUI

/// A `NavigationStack` wrapper that bridges an externally-owned `NavigationPath`
/// (typically backed by UDF state via a Container's `map(store:)`) to a stable,
/// locally-owned binding suitable for `NavigationStack`.
///
/// ## Why this exists
///
/// SwiftUI's `NavigationStack` is sensitive to the *identity* of the `Binding`
/// it receives. When the path lives in a UDF `Form` and is mapped into a
/// Container's `Props` as a freshly-constructed `Binding(get:set:)`, every
/// state mutation reconstructs that binding. During an in-flight UIKit push
/// animation, `NavigationStack` reacts to the new binding identity by
/// speculatively re-walking its destination subtree — which causes phantom
/// `@StateObject` initializations in any descendant `ConnectedContainer`,
/// including spurious `onContainerDidLoad` / `onContainerDidUnload` triggers.
///
/// `NavigationStackBound` insulates `NavigationStack` from that churn:
///
/// - It internally owns a `@State`-backed local `NavigationPath` whose
///   projected binding (`$local`) has stable storage identity across body
///   re-evaluations.
/// - It mirrors the external binding into local state on inbound changes and
///   forwards user-driven local mutations back to the external binding.
///
/// The external binding remains the single source of truth — all navigation
/// mutations still flow through your existing actions. This wrapper changes
/// only *how the binding identity is delivered* to `NavigationStack` itself,
/// not where the path lives.
///
/// ## Behavioral notes
///
/// - The first sync seeds the local path from the external binding at
///   construction time, so deep links and restored state appear in the stack
///   on the first frame (no empty-stack flash).
/// - Inbound (state → local) and outbound (local → state) propagation is
///   gated by equality checks alone: the loop terminates because each side
///   reads the *current* value through its own storage, and once both sides
///   agree the guards short-circuit. No suppression flag is needed.
/// - The Container that vends the external binding **must** keep the path's
///   form inside its `scope(for:)`. If the scope excludes the form, the
///   Container's `ContainerState` won't re-evaluate on path changes, the
///   wrapper won't see the updated `Binding`, and pushes will not propagate.
///
/// ## Usage
///
/// ```swift
/// // Container
/// func scope(for state: AppState) -> Scope {
///     state.welcomeForm   // must include the form that owns the path
/// }
///
/// func map(store: EnvironmentStore<AppState>) -> RootComponent.Props {
///     .init(path: store.$state.welcomeForm.path)
/// }
///
/// // Component
/// struct Props { var path: Binding<NavigationPath> }
///
/// var body: some View {
///     NavigationStackBound(to: props.path) {
///         WelcomeScreen()
///             .navigationDestination(for: AuthRouting.self)
///     }
///     .environment(\.globalRouter, GlobalRouter(path: props.path))
/// }
/// ```
public struct NavigationStackBound<Root: View>: View {
    /// The externally-owned path (typically projected from UDF state).
    @Binding private var external: NavigationPath

    /// Stable, locally-owned path. `$local` is the identity-stable binding
    /// that `NavigationStack` consumes.
    @State private var local: NavigationPath

    /// The root view of the navigation stack.
    private let root: () -> Root

    /// Creates a `NavigationStackBound` that bridges the supplied external
    /// path to an internally-owned, identity-stable binding.
    ///
    /// - Parameters:
    ///   - path: The externally-owned `NavigationPath` binding (typically
    ///     constructed by a Container in `map(store:)` to read from and
    ///     dispatch into UDF state).
    ///   - root: The root view content of the navigation stack.
    public init(
        to path: Binding<NavigationPath>,
        @ViewBuilder _ root: @escaping () -> Root
    ) {
        _external = path
        _local = State(initialValue: path.wrappedValue)
        self.root = root
    }

    public var body: some View {
        NavigationStack(path: $local) {
            root()
        }
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
