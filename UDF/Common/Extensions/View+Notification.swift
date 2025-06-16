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
    
    @State private var alertState: NotificationState = .dismissed
    @State private var toastState: NotificationState = .dismissed
    @State private var dialogState: NotificationState = .dismissed
    
    func body(content: Content) -> some View {
        content
            .onChange(of: state) { newState in
                routeNotification(newState)
            }
            .onAppear {
                routeNotification(state)
            }
            .modifier(AlertNotificationModifier(notificationState: $alertState))
            .modifier(ToastNotificationModifier(
                notificationState: $toastState,
                queueConfiguration: queueConfiguration
            ))
            .modifier(ConfirmationDialogModifier(notificationState: $dialogState))
    }
    
    private func routeNotification(_ notification: NotificationState) {
        switch notification.status {
        case .presented(let notificationType):
            // Route to appropriate state based on style
            switch notificationType.style {
            case .alert:
                print("🔀 Routing to alert state")
                alertState = notification
                
            case .toast:
                print("🔀 Routing to toast state")
                toastState = notification
                
            case .confirmationDialog:
                print("🔀 Routing to dialog state")
                dialogState = notification
            }
            
        case .dismissed:
            print("🔀 Dismissal received for notification ID: \(notification.id)")
            
            // Only dismiss states that match the dismissed notification ID
            if alertState.id == notification.id {
                print("🔀 Dismissing alert state")
                alertState = .dismissed
            }
            if toastState.id == notification.id {
                print("🔀 Dismissing toast state")
                toastState = .dismissed
            }
            if dialogState.id == notification.id {
                print("🔀 Dismissing dialog state")
                dialogState = .dismissed
            }
        }
    }
}
