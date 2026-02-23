//===--- ConfirmationDialog.swift ----------------------------------------===//
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

/// Defines a confirmation dialog structure built logically using `ConfirmationDialogComponentBuilder`.
///
/// Use `ConfirmationDialog` to declare native confirmation dialogs supporting custom configurations.
public struct ConfirmationDialog: Dialog {
    public let customType: DialogCustomType<AnyView, AnyView>

    /// Creates a ConfirmationDialog dynamically by building typical dialog components.
    ///
    /// - Parameters:
    ///   - config: A `ConfirmationDialogConfiguration` used to customize the presentation.
    ///   - content: The dialog components making up the confirmation dialog.
    public init(
        config: ConfirmationDialogConfiguration = .default,
        @ConfirmationDialogComponentBuilder _ content: () -> [DialogComponent]
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
            style: .confirmationDialog(config)
        )
    }
}
