//===--- Collection+Contains.swift ---------------------------------===//
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

public extension Collection where Self.Element: Hashable {
    /// Checks if the collection contains a given element of type `AnyHashable`.
    ///
    /// - Parameter element: The `AnyHashable` element to search for in the collection.
    /// - Returns: A Boolean value indicating whether the collection contains the specified element.
    func contains(_ element: AnyHashable) -> Bool {
        contains { elem in
            AnyHashable(elem) == element
        }
    }
}
