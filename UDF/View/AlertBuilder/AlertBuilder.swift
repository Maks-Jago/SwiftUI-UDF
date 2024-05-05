
import Foundation
import SwiftUI

public enum AlertBuilder {

    public struct AlertStatus: Equatable, Identifiable {
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

        public init<AlertId: Hashable>(id: AlertId) {
            if let builder = AlertBuilder.alertBuilders[id] {
                self = .init(style: builder())
            } else {
                self = .dismissed
            }
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
            case custom(title: () -> String, text: () -> String, actions: () -> [AlertAction])
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

        public init(title: String, text: String, @AlertActionsBuilder actions: @escaping () -> [AlertAction]) {
            self.init(title: { title }, text: { text }, actions: actions)
        }

        public init(title: @escaping () -> String, text: @escaping () -> String, @AlertActionsBuilder actions: @escaping () -> [AlertAction]) {
            id = UUID()
            type = .custom(title: title, text: text, actions: actions)
        }
    }

    typealias AlertBuilderBlock = () -> AlertStyle

    static var alertBuilders: [AnyHashable: AlertBuilderBlock] = [:]

    public static func registerAlert<AlertId: Hashable>(by id: AlertId, _ builder: @escaping () -> AlertStyle) {
        alertBuilders[AnyHashable(id)] = builder
    }
}
