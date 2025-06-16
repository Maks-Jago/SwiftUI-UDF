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
/// Handles confirmation dialog style notifications.
struct ConfirmationDialogModifier: ViewModifier {
    @Binding var notificationState: NotificationState
    @State private var dialogState: DialogState?
    
    func body(content: Content) -> some View {
        content
            .onChange(of: notificationState) { _ in
                updateDialogState()
            }
            .onAppear {
                updateDialogState()
            }
            .confirmationDialog(
                dialogState?.title ?? "",
                isPresented: Binding(
                    get: { dialogState != nil },
                    set: { if !$0 { dismissDialog() }}
                ),
                titleVisibility: dialogState?.titleVisibility ?? .automatic,
                actions: {
                    if let dialogState {
                        ForEach(dialogState.regularButtons.indices, id: \.self) { index in
                            let button = dialogState.regularButtons[index]
                            Button(button.title) {
                                button.action()
                                dismissDialog()
                            }
                        }
                        
                        ForEach(dialogState.destructiveButtons.indices, id: \.self) { index in
                            let button = dialogState.destructiveButtons[index]
                            Button(button.title, role: .destructive) {
                                button.action()
                                dismissDialog()
                            }
                        }
                        
                        if let cancelButton = dialogState.cancelButton {
                            Button(cancelButton.title, role: .cancel) {
                                cancelButton.action()
                                dismissDialog()
                            }
                        }
                    }
                },
                message: {
                    if let message = dialogState?.message {
                        Text(message)
                    }
                }
            )
    }
}

// MARK: - Confirmation Dialog Modifier Helper Methods
private extension ConfirmationDialogModifier {
    func updateDialogState() {
        switch notificationState.status {
        case .presented(let notificationType):
            guard case .confirmationDialog(let config) = notificationType.style else {
                return
            }
            
            if case .custom(let content, _) = notificationType {
                let (cancel, destructive, regular) = content.buttonsByRole()
                dialogState = DialogState(
                    title: content.title,
                    message: content.message,
                    titleVisibility: config.titleVisibility,
                    cancelButton: cancel,
                    destructiveButtons: destructive,
                    regularButtons: regular
                )
            }
            
        case .dismissed:
            dialogState = nil
        }
    }
    
    func dismissDialog() {
        notificationState = .dismissed
        dialogState = nil
    }
}

// MARK: - Dialog State Helper
private struct DialogState {
    let title: String
    let message: String?
    let titleVisibility: Visibility
    let cancelButton: NotificationButton?
    let destructiveButtons: [NotificationButton]
    let regularButtons: [NotificationButton]
}
