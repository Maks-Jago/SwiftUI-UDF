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
    @State private var confirmationDialogState: ConfirmationDialogState?
    
    func body(content: Content) -> some View {
        content
            .onChange(of: dialogStatus) { _ in
                updateDialogStatus()
            }
            .onAppear {
                updateDialogStatus()
            }
            .confirmationDialog(
                confirmationDialogState?.title ?? "",
                isPresented: Binding(
                    get: { confirmationDialogState != nil },
                    set: { if !$0 { dismissDialog() }}
                ),
                titleVisibility: confirmationDialogState?.titleVisibility ?? .automatic,
                actions: {
                    if let confirmationDialogState {
                        ForEach(confirmationDialogState.buttons, id: \.self) { button in
                            Button(button.title, role: button.role) {
                                button.action()
                                dismissDialog()
                            }
                            .disabled(button.disabled)
                        }
                    }
                },
                message: {
                    if let message = confirmationDialogState?.message {
                        Text(message)
                    }
                }
            )
    }
}

// MARK: - Confirmation Dialog Modifier Helper Methods
private extension ConfirmationDialogModifier {
    func updateDialogStatus() {
        switch dialogStatus.status {
        case .presented(let dialogType):
            guard case .confirmationDialog(let config) = dialogType.style else {
                return
            }
            
            if case .custom(let content, _) = dialogType {
                confirmationDialogState = ConfirmationDialogState(
                    title: content.title,
                    message: content.message,
                    titleVisibility: config.titleVisibility,
                    buttons: content.actions.compactMap { $0 as? DialogButton }
                )
            }
            
        case .dismissed:
            confirmationDialogState = nil
        }
    }
    
    func dismissDialog() {
        dialogStatus = .dismissed
        confirmationDialogState = nil
    }
}

// MARK: - Dialog State Helper
private struct ConfirmationDialogState {
    let title: String
    let message: String?
    let titleVisibility: Visibility
    let buttons: [DialogButton]
}
