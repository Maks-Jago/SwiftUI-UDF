//===--- Alert.swift -----------------------------------------------------===//
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

/// Defines an alert structure built logically using `AlertComponentBuilder`.
///
/// Use `Alert` to declare traditional modal alerts.
public struct Alert: Dialog {
    public let customType: DialogCustomType<AnyView, AnyView>

    /// Creates an Alert dynamically by building typical dialog components.
    public init(
        @AlertComponentBuilder _ content: () -> [DialogComponent]
    ) {
        let parsed = DialogComponentParser.parse(content())
        self.customType = DialogCustomType.custom(
            content: .init(
                title: parsed.title,
                message: parsed.message,
                actions: parsed.actions,
                iconBuilder: nil,
                customContentBuilder: nil
            ),
            style: .alert
        )
    }
}
