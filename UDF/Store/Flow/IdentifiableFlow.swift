//===--- IdentifiableFlow.swift -----------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache License v2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation

/// A protocol that extends `Flow` to include a unique identifier for each flow type.
///
/// `IdentifiableFlow` provides a way to uniquely identify different flows in an application using an associated type `FlowId`.
/// This unique identifier can be used to track, manage, and distinguish flows, especially when dealing with multiple instances of flows in
/// the application.
///
/// By conforming to `IdentifiableFlow`, the flow now has a unique identifier that can be accessed using the `id` property.
public protocol IdentifiableFlow: Flow {
    /// The associated type representing the unique identifier for the flow.
    associatedtype FlowId

    /// A static property that returns the unique identifier for the flow.
    static var id: FlowId { get }
}

public extension IdentifiableFlow where FlowId == Flows.Id {
    /// A default implementation that generates an identifier for the flow using its type name.
    ///
    /// This extension provides a default implementation for the `id` property, creating a `Flows.Id` using the type's name.
    /// It allows conforming types to automatically gain a unique identifier without additional implementation.
    static var id: FlowId { FlowId(value: String(describing: Self.self)) }
}
