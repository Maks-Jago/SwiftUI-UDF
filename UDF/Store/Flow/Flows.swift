//===--- Flows.swift ---------------------------------------------===//
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

/// A namespace for defining various flow-related utilities and structures in the UDF architecture.
public enum Flows {}

public extension Flows {
    /// A unique identifier for flows, conforming to `Hashable` and `Codable`.
    ///
    /// The `Id` struct is used to uniquely identify different flows in the application, making it possible to track and manage
    /// their states effectively. It wraps a `String` value that serves as the unique identifier.
    struct Id: Hashable, Codable {
        /// The unique string value representing the flow's identifier.
        var value: String

        /// Initializes a new `Flows.Id` with the given string value.
        ///
        /// - Parameter value: A string representing the unique identifier of the flow.
        public init(value: String) {
            self.value = value
        }
    }
}
