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

/// A helper utility that converts an array of ``DialogComponent`` values into a ``DialogPayload``.
///
/// Used internally by ``Alert``, ``Toast``, and ``ConfirmationDialog`` to transform
/// the result builder output into structured data suitable for ``DialogCustomType`` construction.
///
/// When multiple components of the same type are provided (e.g., two ``DialogTitle`` instances),
/// the **last** one wins.
package struct DialogComponentParser {
    
    /// Parses an array of ``DialogComponent`` values into a ``DialogPayload``.
    ///
    /// - Parameter components: The flat array of components produced by a result builder.
    /// - Returns: A ``DialogPayload`` containing the extracted title, message, actions, icon, and custom content.
    package static func parse(
        _ components: [DialogComponent]
    ) -> DialogPayload {
        var payload = DialogPayload()

        for component in components {
            switch component {
            case let titleComponent as DialogTitle:
                let titleValue = titleComponent.value
                payload.title = { [titleValue] in titleValue }
                
            case let messageComponent as DialogMessage:
                let messageValue = messageComponent.value
                payload.message = { [messageValue] in messageValue }
                
            case let iconComponent as DialogIcon:
                payload.icon = iconComponent.value
                
            case let contentComponent as DialogView:
                payload.customContentView = contentComponent.value
                
            case let action as any DialogAction:
                payload.actions.append(action)
                
            default:
                break
            }
        }

        return payload
    }
}
