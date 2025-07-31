//===--- BindableContainer.swift -------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI

/// A protocol that represents a container in the UDF architecture, which is identifiable and can be connected
/// to the app's state via a `ConnectedContainer`.
///
/// The `BindableContainer` protocol combines the functionalities of `Container` and `Identifiable`,
/// allowing containers to have unique identifiers and manage their state in a type-safe manner.
/// This protocol also provides a default implementation of the `body` property to automatically
/// connect the container with the `ConnectedContainer`.
///
/// ## Requirements:
/// - Must conform to `Container` and `Identifiable`.
///
/// ## Usage:
/// Conforming to `BindableContainer` enables a container to be connected to its state with an identifier,
/// which is useful when managing state across multiple instances of the container.
///
/// ## Example Usage:
/// ```swift
/// struct MyContainer: BindableContainer {
///     // Unique identifier for this container
///     var id: Item.ID
///
///     typealias ContainerComponent = MyComponent
///
///     func map(store: EnvironmentStore<MyAppState>) -> MyComponent.Props {
///         .init()
///     }
///
///     func scope(for state: MyAppState) -> Scope {
///         state.itemsForm[id]
///         state.itemsFlow[id]
///     }
///
///     func onContainerAppear(store: EnvironmentStore<MyAppState>) {
///         // Handle view appearance
///     }
/// }
/// ```
public protocol BindableContainer: Container, Identifiable {}

public extension BindableContainer {
    /// The main view body that connects the container to the state using `ConnectedContainer`.
    ///
    /// This default implementation creates a `ConnectedContainer` for the `BindableContainer`,
    /// passing in the container's type, identifier, state mapping, scope, lifecycle events, and hooks.
    @MainActor
    var body: some View {
        ConnectedContainer<ContainerComponent, ContainerState>(
            containerType: Self.self,
            containerId: { self.id },
            map: map,
            scope: scope(for:),
            onContainerAppear: onContainerAppear,
            onContainerDisappear: onContainerDisappear,
            onContainerDidLoad: onContainerDidLoad,
            onContainerDidUnload: onContainerDidUnload,
            useHooks: useHooks
        )
    }
}
