//===--- Weak.swift -----------------------------------------------===//
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

/// A class that holds a weak reference to an `AnyObject`.
final class Weak {
    /// The weakly referenced object.
    weak var value: AnyObject?
    
    /// Initializes the `Weak` wrapper with an `AnyObject`.
    /// - Parameter value: The object to be weakly referenced.
    init(value: AnyObject) {
        self.value = value
    }
}

extension Array where Element: Weak {
    /// Removes all elements in the array where the weak reference is `nil`.
    mutating func reap() {
        self = self.filter { $0.value != nil }
    }
}
