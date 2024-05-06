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

    private var isAlertPresented: Binding<Bool> {
        Binding(
            get: {
                switch localAlert?.status {
                case .presented:
                    true
                case .dismissed:
                    false
                case nil:
                    false
                }
            },
            set: { newValue in
                if !newValue {
                    localAlert = .dismissed
                }

            }
        )
    }

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

        return content.alert(texts.title(), isPresented: isAlertPresented, actions: {
            ForEach(alertActions(for: type), id: \.id) { action in
                Button(action.title, role: action.role, action: action.action)
            }
        }, message: {
            Text(texts.text())
        })
    }

    func alertActions(for type: AlertBuilder.AlertStyle.AlertType) -> [AlertAction] {
        switch type {
        case .custom(_, _, let actions):
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
        case .messageTitle(let title, let text):
            return (title, text)
        case .custom(let title, let text, _):
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
}
