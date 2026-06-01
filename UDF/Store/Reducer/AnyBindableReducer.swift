//===--- Reducing.swift ------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

protocol AnyBindableReducer: Sendable {
    /// The type of the container this reducer is bound to (e.g., UserDetailsContainer.self)
    var boundContainerType: any Any.Type { get }

    /// Returns whether a reducer instance currently exists in the dictionary for the given ID
    func hasReducer(for id: any Hashable) -> Bool

    /// Returns whether the reducer instance for the given ID is the last active one (refCount == 1)
    func isLastInstance(for id: any Hashable) -> Bool
}
