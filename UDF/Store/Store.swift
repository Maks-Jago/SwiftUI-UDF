//===--- BaseStore.swift -----------------------------------------===//
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

/// The `Store` protocol defines the requirements for a state management store that conforms to the UDF architecture.
/// It is an actor, meaning that it is designed to handle state changes in a thread-safe manner using Swift's concurrency model.
///
/// Types conforming to `Store` must define a `State` that implements the `AppReducer` protocol and provide mechanisms
/// to dispatch actions and bind them to commands.
public protocol Store<State>: Actor {
    associatedtype State: AppReducer
    
    /// The current state of the store.
    var state: State { get }
    
    /// Dispatches an action to the store with optional priority and additional debug information.
    ///
    /// - Parameters:
    ///   - action: The action to dispatch.
    ///   - priority: The priority of the action. Defaults to `.default`.
    ///   - fileName: The name of the file where the action is dispatched. Defaults to the caller's file.
    ///   - functionName: The name of the function where the action is dispatched. Defaults to the caller's function.
    ///   - lineNumber: The line number where the action is dispatched. Defaults to the caller's line.
    ///   /// Example usage:
    /// ```swift
    /// // This method is triggered when the container appears.
    /// func onContainerAppear(store: EnvironmentStore<AppState>) {
    ///     store.dispatch(Actions.UpdateStatus(screen: .displayReady))
    /// }
    /// ```
    nonisolated func dispatch(_ action: some Action, priority: ActionPriority, fileName: String, functionName: String, lineNumber: Int)
}

public extension Store {
    
    /// Dispatches an action to the store with default priority and additional debug information.
    ///
    /// - Parameters:
    ///   - action: The action to dispatch.
    ///   - priority: The priority of the action. Defaults to `.default`.
    ///   - fileName: The name of the file where the action is dispatched. Defaults to the caller's file.
    ///   - functionName: The name of the function where the action is dispatched. Defaults to the caller's function.
    ///   - lineNumber: The line number where the action is dispatched. Defaults to the caller's line.
    nonisolated func dispatch(
        _ action: some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        dispatch(action, priority: priority, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
    }
    
    // MARK: - Binding Actions
    
    /// Binds an action to be executed as a command.
    ///
    /// - Parameters:
    ///   - action: The action to bind.
    ///   - priority: The priority of the action. Defaults to `.default`.
    ///   - fileName: The name of the file where the command is created. Defaults to the caller's file.
    ///   - functionName: The name of the function where the command is created. Defaults to the caller's function.
    ///   - lineNumber: The line number where the command is created. Defaults to the caller's line.
    /// - Returns: A command that, when executed, dispatches the specified action.
    /// /// Example usage:
    /// ```swift
    /// struct ExampleComponent: Component {
    ///     struct Props {
    ///         let executeAction: Command
    ///     }
    ///
    ///     var props: Props
    ///
    ///     var body: some View {
    ///         VStack {
    ///             Text("Example Component")
    ///             Button("Action") {
    ///                 // Execute the action provided through props
    ///                 props.executeAction()
    ///             }
    ///         }
    ///     }
    /// }
    ///
    /// import SwiftUI
    ///
    /// // Define the container for the ExampleComponent
    /// struct ExampleContainer: Container {
    ///     // Define the component that this container will use
    ///     typealias ContainerComponent = ExampleComponent
    ///
    ///     func scope(for state: ContainerState) -> Scope {
    ///         .none
    ///     }
    ///
    ///     // Bind an action to provide the command for the component's props
    ///     func map(store: EnvironmentStore<ContainerState>) -> ExampleComponent.Props {
    ///         .init(executeAction: store.bind(ToggleAction()))
    ///     }
    /// }
    ///
    /// // Example action to be dispatched
    /// struct ToggleAction: Action {}
    /// ```
    ///
    /// In this example:
    /// - `ExampleComponent` accepts a `Command` in its `Props`, which will be executed when the button is tapped.
    /// - `ExampleContainer` binds the `ToggleAction` using the `store.bind` method and passes it to the component's props.
    func bind(
        _ action: some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> Command {
        return {
            self.dispatch(
                action,
                priority: priority,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }
    
    /// Binds a parameterized action to be executed as a command with a single parameter.
    ///
    /// - Parameters:
    ///   - action: A closure that returns an action when given a parameter of type `T`.
    ///   - priority: The priority of the action. Defaults to `.default`.
    ///   - fileName: The name of the file where the command is created. Defaults to the caller's file.
    ///   - functionName: The name of the function where the command is created. Defaults to the caller's function.
    ///   - lineNumber: The line number where the command is created. Defaults to the caller's line.
    /// - Returns: A command that takes a parameter and dispatches the specified action.
    func bind<T>(
        _ action: @escaping (T) -> some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> CommandWith<T> {
        return { value in
            self.dispatch(
                action(value),
                priority: priority,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }
    
    /// Binds a parameterized action to be executed as a command with two parameters.
    ///
    /// - Parameters:
    ///   - action: A closure that returns an action when given two parameters of types `T1` and `T2`.
    ///   - priority: The priority of the action. Defaults to `.default`.
    ///   - fileName: The name of the file where the command is created. Defaults to the caller's file.
    ///   - functionName: The name of the function where the command is created. Defaults to the caller's function.
    ///   - lineNumber: The line number where the command is created. Defaults to the caller's line.
    /// - Returns: A command that takes two parameters and dispatches the specified action.
    func bind<T1, T2>(
        _ action: @escaping (T1, T2) -> some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> CommandWith2<T1, T2> {
        return { v1, v2 in
            self.dispatch(
                action(v1, v2),
                priority: priority,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }
    
    /// Binds a parameterized action to be executed as a command with three parameters.
    ///
    /// - Parameters:
    ///   - action: A closure that returns an action when given three parameters of types `T1`, `T2`, and `T3`.
    ///   - priority: The priority of the action. Defaults to `.default`.
    ///   - fileName: The name of the file where the command is created. Defaults to the caller's file.
    ///   - functionName: The name of the function where the command is created. Defaults to the caller's function.
    ///   - lineNumber: The line number where the command is created. Defaults to the caller's line.
    /// - Returns: A command that takes three parameters and dispatches the specified action.
    func bind<T1, T2, T3>(
        _ action: @escaping (T1, T2, T3) -> some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> CommandWith3<T1, T2, T3> {
        return { v1, v2, v3 in
            self.dispatch(
                action(v1, v2, v3),
                priority: priority,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }
    
    /// Binds a parameterized action to be executed as a command with four parameters.
    ///
    /// - Parameters:
    ///   - action: A closure that returns an action when given four parameters of types `T1`, `T2`, `T3`, and `T4`.
    ///   - priority: The priority of the action. Defaults to `.default`.
    ///   - fileName: The name of the file where the command is created. Defaults to the caller's file.
    ///   - functionName: The name of the function where the command is created. Defaults to the caller's function.
    ///   - lineNumber: The line number where the command is created. Defaults to the caller's line.
    /// - Returns: A command that takes four parameters and dispatches the specified action.
    func bind<T1, T2, T3, T4>(
        _ action: @escaping (T1, T2, T3, T4) -> some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> CommandWith4<T1, T2, T3, T4> {
        return { v1, v2, v3, v4 in
            self.dispatch(
                action(v1, v2, v3, v4),
                priority: priority,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }
    
    /// Binds a parameterized action to be executed as a command with five parameters.
    ///
    /// - Parameters:
    ///   - action: A closure that returns an action when given five parameters of types `T1`, `T2`, `T3`, `T4`, and `T5`.
    ///   - priority: The priority of the action. Defaults to `.default`.
    ///   - fileName: The name of the file where the command is created. Defaults to the caller's file.
    ///   - functionName: The name of the function where the command is created. Defaults to the caller's function.
    ///   - lineNumber: The line number where the command is created. Defaults to the caller's line.
    /// - Returns: A command that takes five parameters and dispatches the specified action.
    func bind<T1, T2, T3, T4, T5>(
        _ action: @escaping (T1, T2, T3, T4, T5) -> some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> CommandWith5<T1, T2, T3, T4, T5> {
        return { v1, v2, v3, v4, v5 in
            self.dispatch(
                action(v1, v2, v3, v4, v5),
                priority: priority,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }
}
