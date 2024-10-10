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
