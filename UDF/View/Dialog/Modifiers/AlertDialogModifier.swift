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
/// This modifier converts `DialogStatus` to the format expected by the current
/// alert system and preserves all existing alert behavior and presentation logic.
struct AlertDialogModifier: ViewModifier {
    @Binding var dialogStatus: DialogStatus
    @State private var localDialogStatus: DialogStatus?
    @State private var alertState: AlertState?
    @State private var dismissedDialog: DialogStatus?
    
    func body(content: Content) -> some View {
        updateAlertStatus()
        
        return content
            .alert(
                alertState?.title ?? "",
                isPresented: Binding(
                    get: { alertState != nil },
                    set: { isPresented in
                        if !isPresented {
                            handleAlertDismissal()
                        }
                    }
                ),
                actions: {
                    if let alertState {
                        ForEach(Array(alertState.actions.enumerated()), id: \.offset) { _, action in
                            if let button = action as? DialogButton {
                                Button(role: button.role) {
                                    button.action()
                                } label: {
                                    Text(button.title)
                                }
                                .disabled(button.disabled)
                            } else if let textField = action as? DialogTextField {
                                #if os(iOS)
                                DialogTextFieldView(
                                    title: textField.title,
                                    text: textField.text,
                                    textInputAutocapitalization: textField.textInputAutocapitalization,
                                    submitLabel: textField.submitLabel
                                )
                                #else
                                DialogTextFieldView(
                                    title: textField.title,
                                    text: textField.text,
                                    submitLabel: textField.submitLabel
                                )
                                #endif
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
    
    /// Updates the alert status based on dialog state changes.
    private func updateAlertStatus() {
        switch (localDialogStatus?.status, dialogStatus.status) {
        case (nil, .dismissed):
            // No local dialog and external is dismissed - nothing to do
            break
            
        case (.some, .dismissed):
            // Local dialog exists but external is dismissed - dismiss it
            if alertState != nil {
                DispatchQueue.main.async {
                    alertState = nil
                    localDialogStatus = nil
                }
            }
            
        case let (.some(localStatus), .presented(newType)) where localStatus == .dismissed:
            // Local was dismissed but new dialog presented - show it
            if case .alert = newType.style {
                DispatchQueue.main.async {
                    localDialogStatus = dialogStatus
                    alertState = convertToAlertState(newType)
                }
            }
            
        case (.some, .presented(let newType)):
            // Both have dialogs - check if actually changed
            if localDialogStatus != dialogStatus, case .alert = newType.style {
                DispatchQueue.main.async {
                    localDialogStatus = dialogStatus
                    alertState = convertToAlertState(newType)
                }
            }
            
        case (.none, .presented(let newType)) where dialogStatus != dismissedDialog:
            // No local dialog but external presented (and not the one we just dismissed)
            if case .alert = newType.style {
                DispatchQueue.main.async {
                    localDialogStatus = dialogStatus
                    alertState = convertToAlertState(newType)
                }
            }
            
        default:
            break
        }
    }
    
    /// Converts a DialogType to AlertState for presentation.
    private func convertToAlertState(_ dialogType: any DialogTypeProtocol) -> AlertState {
        switch dialogType {
        case let dialogType as DialogType:
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
            }

        default:
            return AlertState(
                title: dialogType.title,
                message: dialogType.message,
                actions: dialogType.actions
            )
        }
    }
    
    /// Handles alert dismissal and updates states appropriately.
    private func handleAlertDismissal() {
        if let localDialogStatus = localDialogStatus {
            dismissedDialog = localDialogStatus
            dialogStatus = .dismissed
        }
        alertState = nil
        localDialogStatus = nil
    }
}

// MARK: - Alert State Helper
/// Internal state representation for native iOS alerts.
private struct AlertState: Equatable {
    let title: String
    let message: String?
    let actions: [any DialogAction]
    
    static func == (lhs: AlertState, rhs: AlertState) -> Bool {
        lhs.title == rhs.title &&
        lhs.message == rhs.message &&
        lhs.actions.count == rhs.actions.count &&
        zip(lhs.actions, rhs.actions).allSatisfy { $0.hashValue == $1.hashValue }
    }
}
