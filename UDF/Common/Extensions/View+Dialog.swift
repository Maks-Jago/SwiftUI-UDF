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
    /// Attaches a dialog to the view using the specified `DialogState`.
    ///
    /// This method modifies the view to present dialogs based on the given `Binding<DialogState>`.
    /// The dialog automatically updates its presentation state and content based on changes to the binding.
    ///
    /// - Parameter state: A binding to a `DialogState` that controls the presentation and content of the dialog.
    /// - Returns: A modified view that displays dialogs when the specified `DialogState` is updated.
    ///
    /// ## Usage:
    /// ```swift
    /// struct ContentView: View {
    ///     @State private var dialog = DialogState.dismissed
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
    func dialog(state: Binding<DialogState>) -> some View {
        self.modifier(DialogModifier(state: state, queueConfiguration: .init()))
    }
    
    /// Attaches toast dialogs with custom queue configuration.
    ///
    /// - Parameters:
    ///   - state: The dialog state binding
    ///   - queueConfiguration: Configuration for toast queue behavior
    /// - Returns: A view that displays toast dialogs with specified queue behavior
    func dialog(
        state: Binding<DialogState>,
        queueConfiguration: ToastQueueConfiguration = .sequential
    ) -> some View {
        self.modifier(DialogModifier(state: state, queueConfiguration: queueConfiguration))
    }
}

// MARK: - Main Dialog Modifier
/// The main view modifier that handles dialog presentation.
///
/// This modifier routes dialogs to the appropriate presentation system based on their style.
private struct DialogModifier: ViewModifier {
    @Binding var state: DialogState
    var queueConfiguration: ToastQueueConfiguration
    
    @State private var alertState: DialogState = .dismissed
    @State private var toastState: DialogState = .dismissed
    @State private var dialogState: DialogState = .dismissed
    
    func body(content: Content) -> some View {
        content
            .onChange(of: state) { newState in
                routeDialog(newState)
            }
            .onAppear {
                routeDialog(state)
            }
            .modifier(AlertDialogModifier(dialogState: $alertState))
            .modifier(ToastDialogModifier(
                dialogState: $toastState,
                queueConfiguration: queueConfiguration
            ))
            .modifier(ConfirmationDialogModifier(dialogState: $dialogState))
    }
    
    private func routeDialog(_ dialog: DialogState) {
        switch dialog.status {
        case .presented(let dialogType):
            // Route to appropriate state based on style
            switch dialogType.style {
            case .alert:
                alertState = dialog
                
            case .toast:
                toastState = dialog
                
            case .confirmationDialog:
                dialogState = dialog
            }
            
        case .dismissed:
            // Only dismiss states that match the dismissed dialog ID
            if alertState.id == dialog.id {
                alertState = .dismissed
            }
            
            if toastState.id == dialog.id {
                toastState = .dismissed
            }
        
            if dialogState.id == dialog.id {
                dialogState = .dismissed
            }
        }
    }
}
