//===--- ContainerLifecycle.swift ------------------------------------------===//
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

/// A base class for container lifecycles that maintains global state tracking for active containers.
///
/// In SwiftUI's rendering lifecycle (e.g., during animations, navigation transitions, or list re-renderings),
/// multiple instances of the same container view can temporarily coexist. To prevent race conditions
/// and premature state unloading, this base class provides a centralized registry to track the active count
/// of each container key before executing full unload sequences.
class BaseContainerLifecycle: ObservableObject {
    
    /// A unique key identifying a container type and its specific instance ID.
    ///
    /// This key is used in `activeContainersCount` to distinguish and track active instances of different container types.
    public struct ActiveContainerKey: Hashable, Sendable {
        /// The unique identifier of the container's Swift metatype.
        public let containerType: ObjectIdentifier
        
        /// The unique domain identifier for the specific container instance (e.g. user ID, item ID).
        public let id: AnyHashable

        /// The unique identifier of the store associated with the container.
        public let storeId: ObjectIdentifier

        /// Initializes a new key for tracking container instances.
        ///
        /// - Parameters:
        ///   - containerType: The metatype's `ObjectIdentifier` of the container.
        ///   - id: The unique domain identifier of the container instance.
        ///   - storeId: The unique identifier of the store.
        public init(containerType: ObjectIdentifier, id: AnyHashable, storeId: ObjectIdentifier) {
            self.containerType = containerType
            self.id = id
            self.storeId = storeId
        }
    }

    /// A global registry tracking the number of active, mounted view instances for each container key.
    ///
    /// When a container view is loaded, its count in this dictionary is incremented. When the view is unloaded,
    /// its count is decremented. A container's state will only perform its full teardown and state unloading actions
    /// if the active count remains at zero after a transition grace period.
    @MainActor
    public static var activeContainersCount: [ActiveContainerKey: Int] = [:]
}


/// Manages the lifecycle events of a container within the UDF architecture,
/// including loading and unloading operations, as well as managing container hooks.
///
/// The `ContainerLifecycle` class tracks the lifecycle state of a container.
/// It executes commands when the container loads and unloads and manages hooks to respond to state changes.
/// This class is designed as an `ObservableObject`, allowing SwiftUI views to observe and react to changes.
///
/// - Note: This class is generic over a state type (`State`) that conforms to `AppReducer`.
///
/// ## Properties:
/// - `didLoad`: A private flag indicating whether the container has completed its loading process.
/// - `containerHooks`: A `ContainerHooks` instance that manages hooks used within the container.
/// - `didLoadCommand`: A command executed when the container is first loaded.
/// - `didUnloadCommand`: A command executed when the container is unloaded.
///
/// ## Methods:
/// - `set(didLoad:store:)`: Updates the `didLoad` state and executes the load command if the container has loaded for the first time. It
/// also creates hooks for the container.
/// - `deinit`: Cleans up by removing all hooks and executing the unload command when the `ContainerLifecycle` instance is deallocated.
///
/// ## Initialization:
/// - `init(didLoadCommand:didUnloadCommand:useHooks:)`: Initializes the lifecycle manager with commands to execute on load and unload, as
/// well as a closure for creating hooks.
final class ContainerLifecycle<State: AppReducer>: BaseContainerLifecycle {
    /// A private flag indicating if the container has completed its loading process.
    private var didLoad: Bool = false

    /// The hooks used within the container.
    var containerHooks: ContainerHooks<State>?

    /// A closure that returns an array of hooks to be used in the container.
    private var useHooks: () -> [Hook<State>]

    /// A command that is executed when the container is loaded.
    var didLoadCommand: CommandWith<EnvironmentStore<State>>

    /// A command that is executed when the container is unloaded.
    var didUnloadCommand: CommandWith<EnvironmentStore<State>>

    /// A reference to the EnvironmentStore.
    private var store: EnvironmentStore<State> = EnvironmentStore<State>.global

    /// Sets the `didLoad` state and executes the load command if the container loads for the first time.
    ///
    /// - Parameters:
    ///   - didLoad: A Boolean indicating whether the container has completed its loading.
    ///   - store: The global `EnvironmentStore` holding the state.
    func set(didLoad: Bool, store: EnvironmentStore<State>) {
        self.store = store
        if !self.didLoad, didLoad {
            containerHooks = ContainerHooks(store: store, hooks: useHooks)
            containerHooks?.createHooks()
            didLoadCommand(store)
        }
        self.didLoad = didLoad
    }

    /// Initializes the `ContainerLifecycle` with commands to execute on load and unload,
    /// and a closure to define hooks.
    ///
    /// - Parameters:
    ///   - didLoadCommand: A command to execute when the container is first loaded.
    ///   - didUnloadCommand: A command to execute when the container is unloaded.
    ///   - useHooks: A closure that returns an array of hooks to use within the container.
    init(
        didLoadCommand: @escaping CommandWith<EnvironmentStore<State>>,
        didUnloadCommand: @escaping CommandWith<EnvironmentStore<State>>,
        useHooks: @escaping () -> [Hook<State>]
    ) {
        self.didLoadCommand = didLoadCommand
        self.didUnloadCommand = didUnloadCommand
        self.useHooks = useHooks
    }

    /// Cleans up by removing all hooks and executing the unload command.
    deinit {
        containerHooks?.removeAllHooks()
        self.didUnloadCommand(self.store)
    }
}
