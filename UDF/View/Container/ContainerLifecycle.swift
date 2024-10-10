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
/// - `set(didLoad:store:)`: Updates the `didLoad` state and executes the load command if the container has loaded for the first time. It also creates hooks for the container.
/// - `deinit`: Cleans up by removing all hooks and executing the unload command when the `ContainerLifecycle` instance is deallocated.
///
/// ## Initialization:
/// - `init(didLoadCommand:didUnloadCommand:useHooks:)`: Initializes the lifecycle manager with commands to execute on load and unload, as well as a closure for creating hooks.
final class ContainerLifecycle<State: AppReducer>: ObservableObject {
    /// A private flag indicating if the container has completed its loading process.
    private var didLoad: Bool = false
    
    /// The hooks used within the container.
    let containerHooks: ContainerHooks<State>
    
    /// A command that is executed when the container is loaded.
    var didLoadCommand: CommandWith<EnvironmentStore<State>>
    
    /// A command that is executed when the container is unloaded.
    var didUnloadCommand: CommandWith<EnvironmentStore<State>>
    
    /// Sets the `didLoad` state and executes the load command if the container loads for the first time.
    ///
    /// - Parameters:
    ///   - didLoad: A Boolean indicating whether the container has completed its loading.
    ///   - store: The global `EnvironmentStore` holding the state.
    func set(didLoad: Bool, store: EnvironmentStore<State>) {
        if !self.didLoad, didLoad {
            didLoadCommand(store)
            containerHooks.createHooks()
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
        self.containerHooks = .init(store: EnvironmentStore<State>.global, hooks: useHooks)
    }
    
    /// Cleans up by removing all hooks and executing the unload command.
    deinit {
        containerHooks.removeAllHooks()
        self.didUnloadCommand(EnvironmentStore<State>.global)
    }
}
