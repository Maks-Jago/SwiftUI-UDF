//===--- View+Notification.swift ---------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2025 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

// MARK: - Main Notification API
public extension View {
    /// Attaches a notification to the view using the specified `NotificationState`.
    ///
    /// This method modifies the view to present notifications based on the given `Binding<NotificationState>`.
    /// The notification automatically updates its presentation state and content based on changes to the binding.
    ///
    /// - Parameter state: A binding to a `NotificationState` that controls the presentation and content of the notification.
    /// - Returns: A modified view that displays notifications when the specified `NotificationState` is updated.
    ///
    /// ## Usage:
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var notification = NotificationState.dismissed
    ///     
    ///     var body: some View {
    ///         VStack {
    ///             Button("Show Error") {
    ///                 notification = .init(error: "Something went wrong")
    ///             }
    ///         }
    ///         .notification(state: $notification)
    ///     }
    /// }
    /// ```
    func notification(state: Binding<NotificationState>) -> some View {
        self.modifier(NotificationModifier(state: state, queueConfiguration: .init()))
    }
    
    /// Attaches toast notifications with custom queue configuration.
    ///
    /// - Parameters:
    ///   - state: The notification state binding
    ///   - queueConfiguration: Configuration for toast queue behavior
    /// - Returns: A view that displays toast notifications with specified queue behavior
    func notification(
        state: Binding<NotificationState>,
        queueConfiguration: ToastQueueConfiguration = .sequential
    ) -> some View {
        self.modifier(NotificationModifier(state: state, queueConfiguration: queueConfiguration))
    }
}

// MARK: - Main Notification Modifier
/// The main view modifier that handles notification presentation.
///
/// This modifier routes notifications to the appropriate presentation system based on their style.
private struct NotificationModifier: ViewModifier {
    @Binding var state: NotificationState
    var queueConfiguration: ToastQueueConfiguration
    
    func body(content: Content) -> some View {
        content
            .modifier(AlertNotificationModifier(notificationState: $state))
            .modifier(ToastNotificationModifier(
                notificationState: $state, 
                queueConfiguration: queueConfiguration
            ))
    }
}

// MARK: - Alert-Specific Modifier
/// Handles alert-style notifications using the existing AlertModifier logic.
///
/// This modifier converts `NotificationState` to the format expected by the current
/// alert system and preserves all existing alert behavior and presentation logic.
private struct AlertNotificationModifier: ViewModifier {
    @Binding var notificationState: NotificationState
    @State private var alertState: AlertState?
    @State private var dismissedNotification: NotificationState?
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                updateAlertState()
            }
            .onChange(of: notificationState) { newState in
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
                            case let button as NotificationButton:
                                Button(button.title, role: button.role) {
                                    button.action()
                                    dismissAlert()
                                }
                                .disabled(button.disabled)
                                .id(button.hashValue)
                                
                            case let textField as NotificationTextField:
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
    
    /// Converts NotificationState to AlertState for the native alert system.
    private func updateAlertState() {
        switch notificationState.status {
        case .presented(let notificationType):
            // Only handle alert-style notifications
            guard case .alert = notificationType.style else {
                return
            }
            alertState = convertToAlertState(notificationType)
            
        case .dismissed:
            if alertState != nil {
                alertState = nil
            }
        }
    }
    
    /// Converts a NotificationType to AlertState for presentation.
    private func convertToAlertState(_ notificationType: NotificationType) -> AlertState {
        switch notificationType {
        case .success(let message, _),
                .error(let message, _),
                .warning(let message, _),
                .info(let message, _):
            return AlertState(
                title: "",
                message: message,
                actions: [
                    NotificationButton(title: NSLocalizedString("OK", comment: "OK button"))
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
    
    /// Dismisses the current alert and updates the notification state.
    private func dismissAlert() {
        dismissedNotification = notificationState
        notificationState = .dismissed
        alertState = nil
    }
}

// MARK: - Toast-Specific Modifier

/// Handles toast-style notifications using the ToastView and ToastContainer system.
///
/// This modifier is inspired by the original ToastModifier from the Toastie package
/// but adapted to work with the unified NotificationState system. It provides full
/// toast functionality including positioning, animations, gestures, and auto-dismissal.
private struct ToastNotificationModifier: ViewModifier {
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

// MARK: - Alert State Helper
/// Internal state representation for native iOS alerts.
private struct AlertState {
    let title: String
    let message: String?
    let actions: [any NotificationAction]
}
