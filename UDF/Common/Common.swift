//===--- Common.swift --------------------------------------------===//
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

/// A utility function that provides access to the global `EnvironmentStore` of a specific state type.
///
/// - Parameters:
///   - stateType: The type of the state that conforms to `AppReducer`.
///   - useBlock: A closure that takes the global `EnvironmentStore` for the given state type as an argument.
public func useStore<State: AppReducer>(_ stateType: State.Type, _ useBlock: @escaping (_ store: EnvironmentStore<State>) -> Void) {
    useBlock(EnvironmentStore<State>.global)
}

/// Executes an asynchronous block in a synchronous manner by blocking the executing thread using a semaphore.
///
/// This function allows you to run asynchronous code in a synchronous context,
/// such as when you need to bridge between asynchronous and synchronous APIs.
///
/// - Parameters:
///   - block: An async block to execute.
func executeSynchronously(_ block: @escaping @Sendable () async -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    Task.detached(priority: .userInitiated) {
        await block()
        semaphore.signal()
    }
    _ = semaphore.wait(timeout: .now() + 0.2)
}
