//===--- AlertModifier.swift -------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You Are Launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

public extension View {
    /// Attaches an alert to the view using the specified `AlertBuilder.AlertStatus`.
    ///
    /// This method modifies the view to present an alert based on the given `Binding<AlertBuilder.AlertStatus>`.
    /// The alert automatically updates its presentation state and content based on changes to the binding.
    ///
    /// - Parameter status: A binding to an `AlertBuilder.AlertStatus` that controls the presentation and content of the alert.
    /// - Returns: A modified view that displays an alert when the specified `AlertStatus` is updated.
    func alert(status: Binding<AlertBuilder.AlertStatus>) -> some View {
        self.modifier(AlertModifier(alert: status))
    }
}

private struct AlertModifier: ViewModifier {
    @Binding var alertStatus: AlertBuilder.AlertStatus
    @State private var localAlert: AlertBuilder.AlertStatus?
    @State private var alertToDissmiss: AlertBuilder.AlertStatus? = nil
    
    /// Initializes the alert modifier with the given binding to an `AlertBuilder.AlertStatus`.
    ///
    /// - Parameter alert: A binding to an `AlertBuilder.AlertStatus` that determines the alert's state and content.
    ///  Example usage:
    /// ```swift
    /// struct ContentComponent: Component {
    ///     struct Props {
    ///         let alertStatus: Binding<AlertBuilder.AlertStatus>
    ///     }
    ///
    ///     var props: Props
    ///
    ///     var body: some View {
    ///         Button("Show Alert") {
    ///             props.alertStatus.wrappedValue = .presented(.customActions(title: { "Alert" }, text: { "This is a custom alert" }, actions: { [
    ///                 AlertButton(title: "OK") { print("OK tapped") }
    ///             ]}))
    ///         }
    ///         .alert(status: props.alertStatus)
    ///     }
    /// }
    init(alert: Binding<AlertBuilder.AlertStatus>) {
        _alertStatus = alert
        if alert.wrappedValue.status != .dismissed {
            _localAlert = .init(initialValue: alert.wrappedValue)
        } else {
            localAlert = nil
        }
    }
    
    /// Builds the view content, attaching an alert that reflects the current `AlertStatus`.
    public func body(content: Content) -> some View {
        updateAlertStatus()
        
        /// Extracts the alert type from the current `localAlert` status.
        ///
        /// This logic determines the type of the alert to be presented. It checks if `localAlert`'s status is `.presented`
        /// and extracts the `alertStyle.type`. If `localAlert` is not in the `.presented` state, it defaults to a basic
        /// message alert type with an empty text.
        ///
        /// - Returns: The alert type derived from the `localAlert` if it is `.presented`; otherwise, defaults to an empty message type.
        let type = if case let .presented(alertStyle) = localAlert?.status {
            alertStyle.type
        } else {
            AlertBuilder.AlertStyle.AlertType.message(text: { "" })
        }
        
        let texts = texts(for: type)
        
        return content.alert(texts.title(), isPresented: $localAlert.willSet({ (newValue, oldValue) in
            guard newValue != oldValue else {
                return
            }
            
            if let newValue = newValue {
                alertStatus = newValue
            } else if oldValue?.status != .dismissed {
                alertToDissmiss = localAlert
                alertStatus = .dismissed
            }
        }).isPresented(), actions: {
            let actions = alertActions(for: type)
            ForEach(Array(actions.enumerated()), id: \.offset) { _, action in
                switch action {
                case let action as AlertButton: action.id(action.hashValue)
                case let action as AlertTextField: action
                default:
                    EmptyView()
                }
            }
        }, message: {
            Text(texts.text())
        })
    }
    
    /// Generates alert actions based on the alert type.
    ///
    /// - Parameter type: The type of alert to generate actions for.
    /// - Returns: An array of alert actions appropriate for the alert type.
    func alertActions(for type: AlertBuilder.AlertStyle.AlertType) -> [any AlertAction] {
        switch type {
        case let .custom(_, _, primaryButton, secondaryButton):
            if primaryButton.role == .destructive {
                return [primaryButton, secondaryButton.role(.cancel)]
            } else if secondaryButton.role == .destructive {
                return [primaryButton.role(.cancel), secondaryButton]
            } else {
                return [primaryButton, secondaryButton]
            }
            
        case .customDismiss(_, _, let dismissButton):
            return [dismissButton]
            
        case .customActions(_, _, let actions):
            return actions()
            
        default:
            return [AlertButton(title: NSLocalizedString("Ok", comment: "Ok"))]
        }
    }
    
    /// Provides the title and text for the alert based on the alert type.
    ///
    /// - Parameter type: The type of the alert.
    /// - Returns: A tuple containing closures for the title and text of the alert.
    func texts(for type: AlertBuilder.AlertStyle.AlertType) -> (title: () -> String, text: () -> String) {
        switch type {
        case .validationError(let text):
            return ({""}, text)
        case .success(let text):
            return ({""}, text)
        case .failure(let text):
            return ({""}, text)
        case .message(let text):
            return ({""}, text)
        case let .messageTitle(title, text):
            return (title, text)
        case let .customActions(title, text, _):
            return (title, text)
        case let .custom(title, text, _, _):
            return (title, text)
        case let .customDismiss(title, text, _):
            return (title, text)
        }
    }
    
    /// Updates the local alert status based on the current `alertStatus`.
    ///
    /// This method handles state transitions to determine when to present, dismiss, or update the alert.
    /// It compares the current `localAlert` status with the `alertStatus` and performs the appropriate updates
    /// asynchronously on the main thread.
    ///
    /// - Cases:
    ///   - `(nil, .dismissed)`: No local alert is present, and the alert status is `dismissed`. No action is needed.
    ///   - `(.some, .dismissed)`: A local alert is currently being presented, but the alert status has changed to `dismissed`.
    ///     Dismiss the alert asynchronously by setting `localAlert` to `nil`.
    ///   - `(.some(let lhs), .presented) where lhs == .dismissed`: The local alert was previously dismissed, but now the alert status is set to `presented`.
    ///     Update the `localAlert` to the current `alertStatus` asynchronously.
    ///   - `(.some, .presented)`: A local alert is already being presented, but there may be changes to the alert's state.
    ///     If the current `localAlert` is different from `alertStatus`, update `localAlert` asynchronously.
    ///   - `(.none, .presented) where alertStatus != alertToDissmiss`: No local alert is present, and the alert status is set to `presented`.
    ///     If the `alertStatus` is not the one that was previously dismissed, update `localAlert` asynchronously to present the alert.
    ///   - `default`: No action is taken for any other state transitions.
    private func updateAlertStatus() {
        switch (localAlert?.status, alertStatus.status) {
        case (nil, .dismissed):
            break
            
        case (.some, .dismissed):
            DispatchQueue.main.async {
                localAlert = nil
            }
            
        case (.some(let lhs), .presented) where lhs == .dismissed:
            DispatchQueue.main.async {
                localAlert = alertStatus
            }
            
        case (.some, .presented):
            if localAlert != alertStatus {
                DispatchQueue.main.async {
                    localAlert = alertStatus
                }
            }
            
        case (.none, .presented) where alertStatus != alertToDissmiss:
            DispatchQueue.main.async {
                localAlert = alertStatus
            }
            
        default:
            break
        }
    }
}

fileprivate extension Binding {
    /// Executes a closure before setting the new value.
    func willSet(_ willSet: @escaping ((newValue: Value, oldValue: Value)) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                willSet((newValue, self.wrappedValue))
                self.wrappedValue = newValue
            }
        )
    }
    
    /// Returns a boolean binding indicating whether the optional value is present.
    func isPresented<T>() -> Binding<Bool> where Value == Optional<T> {
        Binding<Bool>(
            get: {
                switch self.wrappedValue {
                case .some: return true
                case .none: return false
                }
            },
            set: {
                if !$0 {
                    self.wrappedValue = nil
                }
            }
        )
    }
}
