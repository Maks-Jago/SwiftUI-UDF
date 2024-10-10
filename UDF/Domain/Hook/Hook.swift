//===--- Hook.swift ----------------------------------------------===//
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

/// A `Hook` is a structure used to define conditional actions (blocks) to be executed within the store, based on changes to the state.
public struct Hook<State: AppReducer> {
    /// The unique identifier for the hook.
    let id: AnyHashable
    /// The type of the hook, defining its behavior (e.g., `default` or `oneTime`).
    let type: HookType
    /// The condition to be met in the state for the hook's block to execute.
    let condition: (_ state: State) -> Bool
    /// The block to be executed when the condition is met.
    let block: (_ store: EnvironmentStore<State>) -> Void
    
    /// Initializes a new `Hook`.
    /// - Parameters:
    ///   - id: A unique identifier for the hook.
    ///   - type: The type of the hook. Default is `.default`.
    ///   - condition: A closure defining the condition to be met in the state.
    ///   - block: A closure to be executed when the condition is met.
    public init(
        id: AnyHashable,
        type: HookType = .default,
        condition: @escaping (_ state: State) -> Bool,
        block: @escaping (_ store: EnvironmentStore<State>) -> Void
    ) {
        self.id = id
        self.type = type
        self.condition = condition
        self.block = block
    }
    
    /// A static method to create a new `Hook`.
    /// - Parameters:
    ///   - id: A unique identifier for the hook.
    ///   - type: The type of the hook. Default is `.default`.
    ///   - condition: A closure defining the condition to be met in the state.
    ///   - block: A closure to be executed when the condition is met.
    /// - Returns: A `Hook` instance.
    public static func hook(
        id: AnyHashable,
        type: HookType = .default,
        condition: @escaping (_ state: State) -> Bool,
        block: @escaping (_ store: EnvironmentStore<State>) -> Void
    ) -> Hook {
        Hook(
            id: id,
            type: type,
            condition: condition,
            block: block
        )
    }
    
    /// Creates a one-time `Hook` that executes its block only once when the condition is met.
    /// - Parameters:
    ///   - id: A unique identifier for the hook.
    ///   - condition: A closure defining the condition to be met in the state.
    ///   - block: A closure to be executed when the condition is met.
    /// - Returns: A `Hook` instance with type `.oneTime`.
    public static func oneTimeHook(
        id: AnyHashable,
        condition: @escaping (_ state: State) -> Bool,
        block: @escaping (_ store: EnvironmentStore<State>) -> Void
    ) -> Hook {
        hook(id: id, type: .oneTime, condition: condition, block: block)
    }
}
