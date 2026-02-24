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

/// A dialog component representing a custom icon view for a dialog.
///
/// `DialogIcon` is only supported in ``Toast``. Attempting to use it in an
/// ``AlertDialog`` or ``ConfirmationDialog`` will produce a compile-time error.
///
/// ```swift
/// Toast {
///     DialogIcon {
///         Image(systemName: "checkmark.circle.fill")
///     }
///     DialogMessage("Upload complete.")
/// }
/// ```
public struct DialogIcon: ToastComponent {
    let value: @MainActor () -> AnyView

    /// Creates a dialog icon component with a custom SwiftUI view.
    /// - Parameter content: A `@ViewBuilder` closure producing the icon view.
    public init<Content: View>(
        @ViewBuilder _ content: @MainActor @escaping () -> Content
    ) {
        self.value = { AnyView(content()) }
    }
}
