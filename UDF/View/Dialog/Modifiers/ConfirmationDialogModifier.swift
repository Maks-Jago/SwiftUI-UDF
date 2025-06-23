//===--- ConfirmationDialogModifier.swift ---------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2025 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI

// MARK: - Confirmation Dialog-Specific Modifier
/// Handles confirmation dialog style dialogs.
struct ConfirmationDialogModifier: ViewModifier {
    @Binding var dialogStatus: DialogStatus
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog(
                dialogTitle,
                isPresented: Binding(
                    get: { isConfirmationDialogPresented },
                    set: { if !$0 { dialogStatus = .dismissed } }
                ),
                titleVisibility: titleVisibility,
                actions: {
                    if let currentDialogContent {
                        ForEach(currentDialogContent.actions.compactMap { $0 as? DialogButton }, id: \.self) { button in
                            Button(button.title, role: button.role) {
                                button.action()
                                dialogStatus = .dismissed
                            }
                            .disabled(button.disabled)
                        }
                    }
                },
                message: {
                    if let dialogMessage {
                        Text(dialogMessage)
                    }
                }
            )
    }
}

// MARK: - Computed Properties
private extension ConfirmationDialogModifier {
    var dialogTitle: String {
        currentDialogContent?.title ?? ""
    }
    
    var isConfirmationDialogPresented: Bool {
        if case .presented(let dialogType) = dialogStatus.status,
           case .confirmationDialog = dialogType.style {
            return true
        }
        return false
    }
    
    var currentDialogContent: DialogContent? {
        if case .presented(let dialogType) = dialogStatus.status,
           case .confirmationDialog = dialogType.style,
           case .custom(let content, _) = dialogType {
            return content
        }
        return nil
    }
    
    var titleVisibility: Visibility {
        if case .presented(let dialogType) = dialogStatus.status,
           case .confirmationDialog(let config) = dialogType.style {
            return config.titleVisibility
        }
        return .automatic
    }
    
    var dialogMessage: String? {
        currentDialogContent?.message
    }
}
