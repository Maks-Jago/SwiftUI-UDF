//===--- Binding+Init.swift -----------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI

public extension Binding {
    /// Initializes a `Binding` using an autoclosure that returns a `Binding<Value>`.
    ///
    /// - Parameter bind: An autoclosure that provides a `Binding<Value>`.
    init(_ bind: @autoclosure @escaping () -> Binding<Value>) {
        self.init(
            get: { bind().wrappedValue },
            set: { bind().wrappedValue = $0 }
        )
    }
}
