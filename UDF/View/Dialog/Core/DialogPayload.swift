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

/// An intermediate data structure holding parsed dialog component values.
///
/// `DialogPayload` is produced by ``DialogComponentParser`` and consumed
/// by ``Alert``, ``Toast``, and ``ConfirmationDialog`` to construct
/// the final ``DialogCustomType`` for presentation.
///
/// All properties are closures to support deferred evaluation at presentation time
/// and to satisfy Swift 6 strict concurrency (`@Sendable`) requirements.
public struct DialogPayload {
    /// A closure returning the dialog title string. Defaults to an empty string.
    var title: @Sendable () -> String = { "" }
    
    /// A closure returning the optional dialog message string. Defaults to `nil`.
    var message: @Sendable () -> String? = { nil }
    
    /// The list of interactive actions (buttons, text fields) for the dialog.
    var actions: [any DialogAction] = []
    
    /// An optional closure returning the icon view. Only used by ``Toast``.
    var icon: (@Sendable () -> AnyView)? = nil
    
    /// An optional closure returning the custom content view. Only used by ``Toast``.
    var customContentView: (@Sendable () -> AnyView)? = nil
}
