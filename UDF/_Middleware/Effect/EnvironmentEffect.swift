//===--- EnvironmentEffect.swift ------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

/// An effect that receives external dependencies from its middleware.
///
/// Both `StateEffectable` and `StateConcurrencyEffect` inherit this protocol to share environment injection support.
/// Effects that do not require external dependencies use the default `Void` environment.
public protocol EnvironmentEffect {
    associatedtype Environment: Sendable

    /// The environment used by the effect to access external dependencies.
    var environment: Environment! { get set }
}

public extension EnvironmentEffect {
    /// Provides an empty environment for effects that do not require external dependencies.
    var environment: Void! {
        get { () }
        set { }
    }
}
