//===--- ToastNotificationModifier.swift ---------------------------------===//
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

/// Handles toast-style notifications using the ToastView and ToastContainer system.
///
/// This modifier is inspired by the original ToastModifier from the Toastie package
/// but adapted to work with the unified NotificationState system. It provides full
/// toast functionality including positioning, animations, gestures, and auto-dismissal.
struct ToastNotificationModifier: ViewModifier {
    @Binding var notificationState: NotificationState
    var queueConfiguration: ToastQueueConfiguration
    @StateObject private var queueManager: ToastQueueManager
    
    init(notificationState: Binding<NotificationState>, queueConfiguration: ToastQueueConfiguration) {
        self._notificationState = notificationState
        self.queueConfiguration = queueConfiguration
        self._queueManager = StateObject(wrappedValue: ToastQueueManager(configuration: queueConfiguration))
    }
    
    func body(content: Content) -> some View {
        content
            .onChange(of: notificationState) { newState in
                updateToastPresentation(newState)
            }
            .onAppear {
                updateToastPresentation(notificationState)
            }
            .overlay {
                ToastContainer() { _ in }
                    .environmentObject(queueManager)
            }
    }
}


// MARK: - Toast Modifier Helper Methods
private extension ToastNotificationModifier {
    /// Updates the local toast state based on the notification state changes.
    ///
    /// Only processes notifications with `.toast` style, filtering out alert notifications.
    /// This ensures clean separation between alert and toast presentation systems.
    func updateToastPresentation(_ state: NotificationState) {
        switch notificationState.status {
        case .presented(let notificationType):
            // Only handle toast-style notifications
            guard case .toast = notificationType.style else {
                return
            }
            
            queueManager.enqueue(notificationType)
            
        case .dismissed:
            // Intentionally left empty - individual toasts manage their own dismissal
            // We don't want to clear all toasts when a single notification is dismissed
            break
        }
    }
}
