//===--- View+Dialog.swift ---------------------------------===//
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

// MARK: - Main Dialog API
public extension View {
    /// Attaches a dialog to the view using the specified `DialogStatus`.
    ///
    /// This method modifies the view to present dialogs based on the given `Binding<DialogStatus>`.
    /// The dialog automatically updates its presentation state and content based on changes to the binding.
    ///
    /// - Parameter status: A binding to a `DialogStatus` that controls the presentation and content of the dialog.
    /// - Returns: A modified view that displays dialogs when the specified `DialogStatus` is updated.
    ///
    /// ## Usage:
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var dialog = DialogStatus.dismissed
    ///
    ///     var body: some View {
    ///         VStack {
    ///             Button("Show Error") {
    ///                 dialog = .init(error: "Something went wrong")
    ///             }
    ///         }
    ///         .dialog(state: $dialog)
    ///     }
    /// }
    /// ```
    func dialog(status: Binding<DialogStatus>) -> some View {
        self.modifier(DialogModifier(status: status, queueConfiguration: .init()))
    }
    
    /// Attaches toast dialogs with custom queue configuration.
    ///
    /// - Parameters:
    ///   - status: The status state binding
    ///   - queueConfiguration: Configuration for toast queue behavior
    /// - Returns: A view that displays toast dialogs with specified queue behavior
    func dialog(
        status: Binding<DialogStatus>,
        queueConfiguration: ToastQueueConfiguration = .sequential
    ) -> some View {
        self.modifier(DialogModifier(status: status, queueConfiguration: queueConfiguration))
    }
}

// MARK: - Main Dialog Modifier
/// The main view modifier that handles dialog presentation.
///
/// This modifier routes dialogs to the appropriate presentation system based on their style.
private struct DialogModifier: ViewModifier {
    @Binding var status: DialogStatus
    var queueConfiguration: ToastQueueConfiguration
    
    @State private var alertState: DialogStatus = .dismissed
    @State private var toastState: DialogStatus = .dismissed
    @State private var confirmationDialogStatus: DialogStatus = .dismissed
    
    func body(content: Content) -> some View {
        content
            .onChange(of: status) { newState in
                routeDialog(newState)
            }
            .onAppear {
                routeDialog(status)
            }
            // Propagate dismissals back to original status
            .onChange(of: toastState) { newToastState in
                if case .dismissed = newToastState.status {
                    status = .dismissed
                }
            }
            .onChange(of: alertState) { newAlertState in
                if case .dismissed = newAlertState.status {
                    status = .dismissed
                }
            }
            .onChange(of: confirmationDialogStatus) { newConfirmationState in
                if case .dismissed = newConfirmationState.status {
                    status = .dismissed
                }
            }
            .modifier(AlertDialogModifier(dialogStatus: $alertState))
            .modifier(
                ToastDialogModifier(
                    dialogStatus: $toastState,
                    queueConfiguration: queueConfiguration
                )
            )
            .modifier(ConfirmationDialogModifier(dialogStatus: $status))
    }
    
    private func routeDialog(_ dialog: DialogStatus) {
        switch dialog.status {
        case .presented(let dialogType):
            // Route to appropriate state based on style
            switch dialogType.style {
            case .alert:
                alertState = dialog
                
            case .toast:
                toastState = dialog
                
            case .confirmationDialog:
                confirmationDialogStatus = dialog
            }
            
        case .dismissed:
            alertState = .dismissed
            toastState = .dismissed
            confirmationDialogStatus = .dismissed
        }
    }
}
