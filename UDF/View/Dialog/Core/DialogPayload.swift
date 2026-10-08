//===--- DialogPayload.swift --------------------------------------------===//
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
/// by ``AlertDialog``, ``Toast``, and ``ConfirmationDialog`` to construct
/// their content for presentation through ``DialogProtocol``.
///
/// Title and message closures return the strings captured when the components were parsed.
/// Icon and custom content closures are evaluated on the main actor when their views are requested.
public struct DialogPayload: Sendable {
    /// A closure returning the dialog title string. Defaults to an empty string.
    var title: @Sendable () -> String = { "" }
    
    /// A closure returning the optional dialog message string. Defaults to `nil`.
    var message: @Sendable () -> String? = { nil }
    
    /// The list of interactive actions (buttons, text fields) for the dialog.
    var actions: [any DialogAction] = []
    
    /// An optional closure returning the icon view. Only used by ``Toast``.
    var icon: (@MainActor () -> AnyView)? = nil
    
    /// An optional closure returning the custom content view. Only used by ``Toast``.
    var customContentView: (@MainActor () -> AnyView)? = nil
}
