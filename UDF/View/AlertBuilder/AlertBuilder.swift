//===--- AlertBuilder.swift ---------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2024 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftUI

/// A builder for creating and managing alert states and styles.
///
/// `AlertBuilder` provides mechanisms for constructing alert styles, managing alert status, and registering custom alerts.
/// It contains the nested types `AlertStatus` and `AlertStyle`, which define the properties and behavior of alerts within an application.
public enum AlertBuilder {
    
    // MARK: - AlertStatus
    /// Represents the current state of an alert, including its ID and status (presented or dismissed).
    public struct AlertStatus: Equatable, Identifiable {
        
        /// Returns a dismissed alert status.
        public static var dismissed: Self { get { .init() } }
        
        /// Compares two alert statuses to determine if they are equal.
        public static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs.status, rhs.status) {
            case (let .presented(lhsPresented), let .presented(rhsPresented)):
                return lhsPresented.id == rhsPresented.id && lhs.id == rhs.id
            case (.dismissed, .dismissed):
                return lhs.id == rhs.id
            default:
                return false
            }
        }
        
        public var id: UUID
        public var status: Status
        
        /// Enum representing the status of an alert, either presented with a specific style or dismissed.
        public enum Status: Equatable {
            case presented(AlertStyle)
            case dismissed
            
            public static func == (lhs: Self, rhs: Self) -> Bool {
                switch (lhs, rhs) {
                case (let .presented(lhsPresented), let .presented(rhsPresented)):
                    return lhsPresented == rhsPresented
                case (.dismissed, .dismissed):
                    return true
                default:
                    return false
                }
            }
        }
        
        /// Initializes an alert status with an error message.
        public init(error: String?) {
            if let error = error, !error.isEmpty {
                self = .init(style: .init(failure: error))
            } else {
                self = .init()
            }
        }
        
        /// Initializes an alert status with a message.
        public init(message: String?) {
            if let message = message, !message.isEmpty {
                self = .init(style: .init(message: message))
            } else {
                self = .init()
            }
        }
        
        /// Initializes an alert status with a title and an optional message.
        public init(title: String, message: String?) {
            if let message = message, !message.isEmpty {
                self = .init(style: .init(title: title, message: message))
            } else {
                self = .init()
            }
        }
        
        /// Initializes a dismissed alert status.
        public init() {
            id = UUID()
            status = .dismissed
        }
        
        /// Initializes an alert status with a specific alert style.
        public init(style: AlertStyle) {
            id = style.id
            status = .presented(style)
        }
        
        /// Initializes an alert status using a registered alert builder identified by a unique ID.
        public init<AlertId: Hashable>(id: AlertId) {
            if let builder = AlertBuilder.alertBuilders[id] {
                self = .init(style: builder())
            } else {
                self = .dismissed
            }
        }
    }
    
    // MARK: - AlertStyle
    /// Defines the style of an alert, including its type and content.
    public struct AlertStyle: Equatable {
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
        
        public var id: UUID
        var type: AlertType
        
        /// Enum representing the different types of alerts.
        enum AlertType {
            case validationError(text: () -> String)
            case success(text: () -> String)
            case failure(text: () -> String)
            case message(text: () -> String)
            case messageTitle(title: () -> String, message: () -> String)
            
            @available(*, deprecated, message: "use customActions(title:text:actions) case instead")
            case custom(title: () -> String, text: () -> String, primaryButton: AlertButton, secondaryButton: AlertButton)
            
            @available(*, deprecated, message: "use customActions(title:text:actions) case instead")
            case customDismiss(title: () -> String, text: () -> String, dismissButton: AlertButton)
            
            case customActions(title: () -> String, text: () -> String, actions: () -> [any AlertAction])
        }
        
        // MARK: Initializers
        /// Initializes a validation error alert style with a specific text.
        public init(validationError text: String) {
            self.init(validationError: { text })
        }
        
        /// Initializes a validation error alert style with a closure providing the text.
        public init(validationError text: @escaping () -> String) {
            id = UUID()
            type = .validationError(text: text)
        }
        
        /// Initializes a failure alert style with a specific text.
        public init(failure text: String) {
            self.init(failure: { text })
        }
        
        /// Initializes a failure alert style with a closure providing the text.
        public init(failure text: @escaping () -> String) {
            id = UUID()
            type = .failure(text: text)
        }
        
        /// Initializes a success alert style with a specific text.
        public init(success text: String) {
            self.init(success: { text })
        }
        
        /// Initializes a success alert style with a closure providing the text.
        public init(success text: @escaping () -> String) {
            id = UUID()
            type = .success(text: text)
        }
        
        /// Initializes a message alert style with a specific text.
        public init(message text: String) {
            self.init(message: { text })
        }
        
        /// Initializes a message alert style with a closure providing the text.
        public init(message text: @escaping () -> String) {
            id = UUID()
            type = .message(text: text)
        }
        
        /// Initializes an alert style with a title and message.
        public init(title: String, message: String) {
            self.init(title: { title }, message: { message })
        }
        
        /// Initializes an alert style with closures for title and message.
        public init(title: @escaping () -> String, message: @escaping () -> String) {
            id = UUID()
            type = .messageTitle(title: title, message: message)
        }
        
        @available(*, deprecated, message: "use init(title:text:actions) instead")
        public init(title: String, text: String, primaryButton: AlertButton, secondaryButton: AlertButton) {
            self.init(title: { title }, text: { text }, primaryButton: primaryButton, secondaryButton: secondaryButton)
        }
        
        @available(*, deprecated, message: "use init(title:text:actions) instead")
        public init(title: @escaping () -> String, text: @escaping () -> String, primaryButton: AlertButton, secondaryButton: AlertButton) {
            id = UUID()
            type = .custom(title: title, text: text, primaryButton: primaryButton, secondaryButton: secondaryButton)
        }
        
        @available(*, deprecated, message: "use init(title:text:actions) instead")
        public init(title: String, text: String, dismissButton: AlertButton) {
            self.init(title: { title }, text: { text }, dismissButton: dismissButton)
        }
        
        @available(*, deprecated, message: "use init(title:text:actions) instead")
        public init(title: @escaping () -> String, text: @escaping () -> String, dismissButton: AlertButton) {
            id = UUID()
            type = .customDismiss(title: title, text: text, dismissButton: dismissButton)
        }
        
        /// Initializes a custom alert style with a title, text, and custom actions.
        public init(title: String, text: String, @AlertActionsBuilder actions: @escaping () -> [any AlertAction]) {
            self.init(title: { title }, text: { text }, actions: actions)
        }
        
        /// Initializes a custom alert style with closures for title, text, and actions.
        public init(title: @escaping () -> String, text: @escaping () -> String, @AlertActionsBuilder actions: @escaping () -> [any AlertAction]) {
            id = UUID()
            type = .customActions(title: title, text: text, actions: actions)
        }
    }
    
    // MARK: - Alert Builder Registration
    typealias AlertBuilderBlock = () -> AlertStyle
    
    static var alertBuilders: [AnyHashable: AlertBuilderBlock] = [:]
    
    /// Registers a custom alert builder for a given ID.
    ///
    /// - Parameters:
    ///   - id: A unique identifier for the alert builder.
    ///   - builder: A closure that returns an `AlertStyle`.
    public static func registerAlert<AlertId: Hashable>(by id: AlertId, _ builder: @escaping () -> AlertStyle) {
        alertBuilders[AnyHashable(id)] = builder
    }
}
