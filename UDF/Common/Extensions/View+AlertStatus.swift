import Foundation
import SwiftUI

public extension View {
    func alert(status: Binding<AlertBuilder.AlertStatus>) -> some View {
        self.modifier(AlertModifier(alert: status))
    }
}

private struct AlertModifier: ViewModifier {

    @Binding var alertStatus: AlertBuilder.AlertStatus
    @State private var localAlert: AlertBuilder.AlertStatus?
    @State private var alertToDissmiss: AlertBuilder.AlertStatus? = nil

    init(alert: Binding<AlertBuilder.AlertStatus>) {
        _alertStatus = alert
        if alert.wrappedValue.status != .dismissed {
            _localAlert = .init(initialValue: alert.wrappedValue)
        } else {
            localAlert = nil
        }
    }

    public func body(content: Content) -> some View {
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
            ForEach(alertActions(for: type), id: \.id) { action in
                Button(action.title, role: action.role, action: action.action)
            }
        }, message: {
            Text(texts.text())
        })
    }

    func alertActions(for type: AlertBuilder.AlertStyle.AlertType) -> [AlertAction] {
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
            return [AlertAction(id: "default_action", title: NSLocalizedString("Ok", comment: "Ok"))]
        }
    }

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
}


fileprivate extension Binding {
    func willSet(_ willSet: @escaping ((newValue: Value, oldValue: Value)) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                willSet((newValue, self.wrappedValue))
                self.wrappedValue = newValue
            }
        )
    }

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
