//
//  AlertStyleUpd.swift
//
//
//  Created by Oksana Fedorchuk on 09.04.2024.
//

import Foundation
import SwiftUI

public struct AlertStyleUpd: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    public var id = UUID()
    public var alertType: AlertType = .none
    public var title: String = ""
    public var body: String = ""
    public var message: String = ""
    public var actions: [AlertAction] = []
    
    public enum AlertType {
        case none
        ///            func alert<A>(LocalizedStringKey, isPresented: Binding<Bool>, actions: () -> A) -> some View
        ///            Presents an alert when a given condition is true, using a localized string key for the title.
        case title
        case error
        ///            func alert<A, M>(LocalizedStringKey, isPresented: Binding<Bool>, actions: () -> A, message: () -> M) -> some View
        ///            Presents an alert with a message when a given condition is true, using a localized string key for a title.
        case message
    }
    
    public init() {}
    
    public init(error: String) {
        self.alertType = .error
        self.title = error
    }
    
    public init(title: String, @AlertActionBuilder<AlertAction> actions: () -> [AlertAction]) {
        self.alertType = .title
        self.title = title
        self.actions = actions()
    }
    
    public init(title: String, message: String, @AlertActionBuilder<AlertAction> actions: () -> [AlertAction]) {
        self.alertType = .message
        self.title = title
        self.message = message
        self.actions = actions()
    }
    
    @resultBuilder
    public enum AlertActionBuilder<AlertAction> {
        public static func buildEither(first component: [AlertAction]) -> [AlertAction] {
            component
        }
        
        public static func buildEither(second component: [AlertAction]) -> [AlertAction] {
            component
        }
        
        public static func buildOptional(_ component: [AlertAction]?) -> [AlertAction] {
            component ?? []
        }
        
        public static func buildExpression(_ expression: AlertAction) -> [AlertAction] {
            [expression]
        }
        
        public static func buildExpression(_ expression: ()) -> [AlertAction] {
            []
        }
        
        static func buildLimitedAvailability(_ components: [AlertAction]) -> [AlertAction] {
            components
        }
        
        public static func buildBlock(_ components: [AlertAction]...) -> [AlertAction] {
            components.flatMap { $0 }
        }
        
        public static func buildArray(_ components: [[AlertAction]]) -> [AlertAction] {
            components.flatMap { $0 }
        }
    }
}

public struct AlertAction: Identifiable {
    public static func == (lhs: AlertAction, rhs: AlertAction) -> Bool {
        return lhs.id == rhs.id
    }
    
    public var id = UUID()
    public var title: String
    public var role: ButtonRole?
    public var action: () -> () = {}
    
    public init(
        id: UUID = UUID(),
        title: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void = {}
    ) {
        self.id = id
        self.title = title
        self.role = role
        self.action = action
    }
}
