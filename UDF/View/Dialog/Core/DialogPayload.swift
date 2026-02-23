//===--- DialogComponentParser.swift ---------------------------------===//
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

public struct DialogPayload {
    var title: @Sendable () -> String = { "" }
    var message: @Sendable () -> String? = { nil }
    var actions: [any DialogAction] = []
    var icon: (@Sendable () -> AnyView)? = nil
    var customContentView: (@Sendable () -> AnyView)? = nil
}
