//===--- AlertDialogModifier.swift ---------------------------------===//
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

// MARK: - Alert-Specific Modifier
/// Handles alert-style dialogs using the existing AlertModifier logic.
///
/// This modifier converts `DialogState` to the format expected by the current
/// alert system and preserves all existing alert behavior and presentation logic.
struct AlertDialogModifier: ViewModifier {
    @Binding var dialogState: DialogState
    @State private var alertState: AlertState?
    @State private var dismissedDialog: DialogState?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                updateAlertState()
            }
            .onChange(of: dialogState) { newState in
                updateAlertState()
            }
            .alert(
                alertState?.title ?? "",
                isPresented: Binding(
                    get: { alertState != nil },
                    set: { isPresented in
                        if !isPresented {
                            dismissAlert()
                        }
                    }
                ),
                actions: {
                    if let alertState = alertState {
                        ForEach(Array(alertState.actions.enumerated()), id: \.offset) { _, action in
                            switch action {
                            case let button as DialogButton:
                                Button(button.title, role: button.role) {
                                    button.action()
                                    dismissAlert()
                                }
                                .disabled(button.disabled)
                                .id(button.hashValue)
                                
                            case let textField as DialogTextField:
                                textField
                                
                            default:
                                EmptyView()
                            }
                        }
                    }
                },
                message: {
                    if let message = alertState?.message {
                        Text(message)
                    }
                }
            )
    }
    
    /// Converts DialogState to AlertState for the native alert system.
    private func updateAlertState() {
        switch dialogState.status {
        case .presented(let dialogType):
            // Only handle alert-style dialogs
            guard case .alert = dialogType.style else {
                return
            }
            alertState = convertToAlertState(dialogType)
            
        case .dismissed:
            if alertState != nil {
                alertState = nil
            }
        }
    }
    
    /// Converts a DialogType to AlertState for presentation.
    private func convertToAlertState(_ dialogType: DialogType) -> AlertState {
        switch dialogType {
        case .success(let message, _),
                .error(let message, _),
                .warning(let message, _),
                .info(let message, _):
            return AlertState(
                title: "",
                message: message,
                actions: [
                    DialogButton(title: NSLocalizedString("OK", comment: "OK button"))
                ]
            )
            
        case .custom(let content, _):
            return AlertState(
                title: content.title,
                message: content.message,
                actions: content.actions
            )
        }
    }
    
    /// Dismisses the current alert and updates the dialog state.
    private func dismissAlert() {
        dismissedDialog = dialogState
        dialogState = .dismissed
        alertState = nil
    }
}

// MARK: - Alert State Helper
/// Internal state representation for native iOS alerts.
private struct AlertState {
    let title: String
    let message: String?
    let actions: [any DialogAction]
}
