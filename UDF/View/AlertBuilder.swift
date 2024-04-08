import Foundation
import SwiftUI

public enum AlertBuilder {

    public struct AlertStatus: Equatable {
        public static var dismissed: Self { get { .init() }}

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

        public enum Status: Equatable {
            case presented(AlertStyle)
            case presentedWithStyle(TheAlertStyle)
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

        public init(error: String?) {
            if let error = error, error.isEmpty == false {
                self = .init(style: .init(failure: error))
            } else {
                self = .init()
            }
        }

        public init(message: String?) {
            if let message = message, message.isEmpty == false {
                self = .init(style: .init(message: message))
            } else {
                self = .init()
            }
        }

        public init(title: String, message: String?) {
            if let message = message, message.isEmpty == false {
                self = .init(style: .init(title: title, message: message))
            } else {
                self = .init()
            }
        }

        public init() {
            id = UUID()
            status = .dismissed
        }

        public init(style: AlertStyle) {
            id = style.id
            status = .presented(style)
        }
        
        public init(theStyle: TheAlertStyle) {
            id = UUID()
            status = .presentedWithStyle(theStyle)
        }

        public init<AlertId: Hashable>(id: AlertId) {
            if let builder = AlertBuilder.alertBuilders[id] {
                self = .init(style: builder())
            } else {
                self = .dismissed
            }
        }
    }
    
    public struct TheAlertStyle {
        public var alertType: TheAlertType = .none
        public var title: String = ""
        public var body: String = ""
        
        public enum TheAlertType {
            case none
            case title
            case error
            //            func alert<A>(LocalizedStringKey, isPresented: Binding<Bool>, actions: () -> A) -> some View
            //            Presents an alert when a given condition is true, using a localized string key for the title.
            case message
            //            func alert<A, M>(LocalizedStringKey, isPresented: Binding<Bool>, actions: () -> A, message: () -> M) -> some View
            //            Presents an alert with a message when a given condition is true, using a localized string key for a title.
            case data
            //            func alert<A, M, T>(Text, isPresented: Binding<Bool>, presenting: T?, actions: (T) -> A, message: (T) -> M) -> some View
            //            Presents an alert with a message using the given data to produce the alert’s content and a text view for a title.
        }

        public init() {}
        
        public init(alertType: TheAlertType, title: String, body: String) {
            self.alertType = alertType
            self.title = title
            self.body = body
        }
    }

    public struct AlertStyle: Equatable {
        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }

        public var id: UUID
        var type: AlertType

        enum AlertType {
            case validationError(text: () -> String)
            case success(text: () -> String)
            case failure(text: () -> String)
            case message(text: () -> String)
            case messageTitle(title: () -> String, message: () -> String)
            case custom(title: () -> String, text: () -> String, primaryButton: Alert.Button, secondaryButton: Alert.Button)
            case customDismiss(title: () -> String, text: () -> String, dismissButton: Alert.Button)
        }

        public init(validationError text: String) {
            self.init(validationError: { text })
        }

        public init(validationError text: @escaping () -> String) {
            id = UUID()
            type = .validationError(text: text)
        }

        public init(failure text: String) {
            self.init(failure: { text })
        }

        public init(failure text: @escaping () -> String) {
            id = UUID()
            type = .failure(text: text)
        }

        public init(success text: String) {
            self.init(success: { text })
        }

        public init(success text: @escaping () -> String) {
            id = UUID()
            type = .success(text: text)
        }

        public init(message text: String) {
            self.init(message: { text })
        }

        public init(message text: @escaping () -> String) {
            id = UUID()
            type = .message(text: text)
        }

        public init(title: String, message: String) {
            self.init(title: { title }, message: { message })
        }

        public init(title: @escaping () -> String, message: @escaping () -> String) {
            id = UUID()
            type = .messageTitle(title: title, message: message)
        }

        public init(title: String, text: String, primaryButton: Alert.Button, secondaryButton: Alert.Button) {
            self.init(title: { title }, text: { text }, primaryButton: primaryButton, secondaryButton: secondaryButton)
        }

        public init(title: @escaping () -> String, text: @escaping () -> String, primaryButton: Alert.Button, secondaryButton: Alert.Button) {
            id = UUID()
            type = .custom(title: title, text: text, primaryButton: primaryButton, secondaryButton: secondaryButton)
        }

        public init(title: String, text: String, dismissButton: Alert.Button) {
            self.init(title: { title }, text: { text }, dismissButton: dismissButton)
        }

        public init(title: @escaping () -> String, text: @escaping () -> String, dismissButton: Alert.Button) {
            id = UUID()
            type = .customDismiss(title: title, text: text, dismissButton: dismissButton)
        }
    }

    public static func buildAlert(for style: AlertStyle) -> Alert {
        switch style.type {
        case .validationError(let text):
            return alert(title: NSLocalizedString("Incorrect input", comment: "Validation error"), text: text())

        case .success(let text):
            return alert(title: NSLocalizedString("Success", comment: "Success"), text: text())

        case .failure(let text):
            return alert(title: NSLocalizedString("Error", comment: "Error"), text: text())

        case .message(let text):
            return alert(title: "", text: text())

        case .messageTitle(let title, let text):
            return alert(title: title(), text: text())

        case let .customDismiss(title, text, dismissButton):
            return alert(title: title(), text: text(), dismissButton: dismissButton)

        case let .custom(title, text, primaryButton, secondaryButton):
            return alert(title: title(), text: text(), primaryButton: primaryButton, secondaryButton: secondaryButton)
        }
    }

    typealias AlertBuilderBlock = () -> AlertStyle

    static var alertBuilders: [AnyHashable: AlertBuilderBlock] = [:]

    public static func registerAlert<AlertId: Hashable>(by id: AlertId, _ builder: @escaping () -> AlertStyle) {
        alertBuilders[AnyHashable(id)] = builder
    }
}

// MARK: - Identifiable
extension AlertBuilder.AlertStatus: Identifiable {}

// MARK: - Alerts
private extension AlertBuilder {
    static func alert(title: String, text: String) -> Alert {
        .init(title: Text(title), message: Text(text), dismissButton: .default(Text(NSLocalizedString("Ok", comment: "Ok"))))
    }

    static func alert(title: String, text: String, primaryButton: Alert.Button, secondaryButton: Alert.Button) -> Alert {
        .init(title: Text(title), message: Text(text), primaryButton: primaryButton, secondaryButton: secondaryButton)
    }

    static func alert(title: String, text: String, dismissButton: Alert.Button) -> Alert {
        .init(title: Text(title), message: Text(text), dismissButton: dismissButton)
    }
}
