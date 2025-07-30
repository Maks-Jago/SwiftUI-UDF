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
    @Binding var dialogStatus: DialogStatus
    var queueConfiguration: ToastQueueConfiguration
    @StateObject private var queueManager: ToastQueueManager
    
    // Track processed dialogs with their presentation state
    @State private var processedDialogs: Set<UUID> = []
    @State private var currentPresentedDialogId: UUID?
    
    init(dialogStatus: Binding<DialogStatus>, queueConfiguration: ToastQueueConfiguration) {
        self._dialogStatus = dialogStatus
        self.queueConfiguration = queueConfiguration
        self._queueManager = StateObject(wrappedValue: ToastQueueManager(configuration: queueConfiguration))
    }
    
    func body(content: Content) -> some View {
        content
            .onChange(of: dialogStatus) { newState in
                updateToastPresentation(newState)
            }
            .onAppear {
                updateToastPresentation(dialogStatus)
            }
            .overlay {
                ToastContainer() { toastId in
                    if currentPresentedDialogId != nil {
                        dialogStatus = DialogStatus.dismissed
                    }
                }
                .environmentObject(queueManager)
            }
    }
}


// MARK: - Toast Modifier Helper Methods
private extension ToastDialogModifier {
    /// Updates the local toast state based on the dialog status changes.
    ///
    /// Only processes dialogs with `.toast` style, filtering out alert dialogs.
    /// This ensures clean separation between alert and toast presentation systems.
    func updateToastPresentation(_ dialogStatus: DialogStatus) {
        switch dialogStatus.status {
        case .presented(let dialogType):
            // Only handle toast-style dialogs
            guard case .toast = dialogType.style else {
                return
            }
            
            if !processedDialogs.contains(dialogStatus.id) ||
                currentPresentedDialogId != dialogStatus.id {
                
                queueManager.enqueue(dialogType)
                processedDialogs.insert(dialogStatus.id)
                currentPresentedDialogId = dialogStatus.id
            }
            
        case .dismissed:
            queueManager.handleSmartDismissal()
            
            if processedDialogs.count > 5 {
                let currentId = currentPresentedDialogId
                processedDialogs.removeAll()
                if let currentId = currentId {
                    processedDialogs.insert(currentId)
                }
            }
        }
    }
}
