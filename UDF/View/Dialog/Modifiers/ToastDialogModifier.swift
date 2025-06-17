//===--- ToastDialogModifier.swift ---------------------------------===//
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

// MARK: - Toast-Specific Modifier

/// Handles toast-style dialogs using the ToastView and ToastContainer system.
///
/// This modifier is inspired by the original ToastModifier from the Toastie package
/// but adapted to work with the unified Dialog State system. It provides full
/// toast functionality including positioning, animations, gestures, and auto-dismissal.
struct ToastDialogModifier: ViewModifier {
    @Binding var dialogState: DialogState
    var queueConfiguration: ToastQueueConfiguration
    @StateObject private var queueManager: ToastQueueManager
    
    init(dialogState: Binding<DialogState>, queueConfiguration: ToastQueueConfiguration) {
        self._dialogState = dialogState
        self.queueConfiguration = queueConfiguration
        self._queueManager = StateObject(wrappedValue: ToastQueueManager(configuration: queueConfiguration))
    }
    
    func body(content: Content) -> some View {
        content
            .onChange(of: dialogState) { newState in
                updateToastPresentation(newState)
            }
            .onAppear {
                updateToastPresentation(dialogState)
            }
            .overlay {
                ToastContainer() { _ in }
                    .environmentObject(queueManager)
            }
    }
}


// MARK: - Toast Modifier Helper Methods
private extension ToastDialogModifier {
    /// Updates the local toast state based on the dialog state changes.
    ///
    /// Only processes dialogs with `.toast` style, filtering out alert dialogs.
    /// This ensures clean separation between alert and toast presentation systems.
    func updateToastPresentation(_ state: DialogState) {
        switch dialogState.status {
        case .presented(let dialogType):
            // Only handle toast-style dialogs
            guard case .toast = dialogType.style else {
                return
            }
            
            queueManager.enqueue(dialogType)
            
        case .dismissed:
            // Intentionally left empty - individual toasts manage their own dismissal
            // We don't want to clear all toasts when a single dialog is dismissed
            break
        }
    }
}
