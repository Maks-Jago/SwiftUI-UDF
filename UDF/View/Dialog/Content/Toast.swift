//===--- Toast.swift -----------------------------------------------------===//
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

/// Defines a toast structure built logically using `ToastComponentBuilder`.
///
/// Use `Toast` to declare non-modal overlay toasts supporting custom configurations.
public struct Toast: Dialog {
    public let customType: DialogCustomType<AnyView, AnyView>

    /// Creates a Toast dynamically by building typical dialog components.
    ///
    /// - Parameters:
    ///   - config: A `ToastConfiguration` used to customize the presentation.
    ///   - content: The dialog components making up the toast.
    public init(
        config: ToastConfiguration = .default,
        @ToastComponentBuilder _ content: () -> [DialogComponent]
    ) {
        let parsed = DialogComponentParser.parse(content())
        self.customType = DialogCustomType.custom(
            content: .init(
                title: parsed.title,
                message: parsed.message,
                actions: parsed.actions,
                iconBuilder: parsed.icon,
                customContentBuilder: parsed.customContentView
            ),
            style: .toast(config)
        )
    }
}
