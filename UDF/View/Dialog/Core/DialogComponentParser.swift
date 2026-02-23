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

/// A helper parsing utility used internally by `Alert`, `Toast`, and `ConfirmationDialog`.
package struct DialogComponentParser {
    
    /// Parses an array of dialog components into a structured tuple of properties.
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
                
            case let contentComponent as DialogComponentContent:
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
