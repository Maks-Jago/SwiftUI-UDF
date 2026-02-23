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

/// A dialog component representing arbitrary custom SwiftUI content for a dialog.
///
/// `DialogComponentContent` is only supported in ``Toast``. Attempting to use it
/// in an ``Alert`` or ``ConfirmationDialog`` will produce a compile-time error.
///
/// Use this component when the standard title/message layout is insufficient
/// and you need a fully custom view inside the toast.
///
/// ```swift
/// Toast {
///     DialogComponentContent {
///         VStack {
///             ProgressView()
///             Text("Uploading...")
///         }
///     }
/// }
/// ```
public struct DialogComponentContent: ToastComponent {
    let value: @Sendable () -> AnyView

    /// Creates a dialog custom content component with a SwiftUI view.
    /// - Parameter content: A `@ViewBuilder` closure producing the custom content view.
    public init<Content: View & Sendable>(@ViewBuilder _ content: @Sendable @escaping () -> Content) {
        self.value = { @Sendable in AnyView(content()) }
    }
}
