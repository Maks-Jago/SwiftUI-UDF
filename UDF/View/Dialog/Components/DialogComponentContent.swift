//===--- DialogComponents.swift ----------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI

public struct DialogComponentContent: ToastComponent {
    let value: @Sendable () -> AnyView

    public init<Content: View & Sendable>(@ViewBuilder _ content: @Sendable @escaping () -> Content) {
        self.value = { @Sendable in AnyView(content()) }
    }
}
