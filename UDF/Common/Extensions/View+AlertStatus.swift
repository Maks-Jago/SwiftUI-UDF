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
            localAlert = alertStatus

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

        return content
            .modifier(
                AlertTypeModifier(
                    isAlertPresented: $localAlert.willSet({ (newValue, oldValue) in
                        guard newValue != oldValue else {
                            return
                        }

                        if let newValue = newValue {
                            alertStatus = newValue
                        } else if oldValue?.status != .dismissed {
                            alertToDissmiss = localAlert
                            alertStatus = .dismissed
                        }
                    }).isPresented(),
                    type: {
                        if case let .presented(alertStyle) = localAlert?.status {
                            return alertStyle.type
                        } else {
                            return AlertBuilder.AlertStyle.AlertType.message(text: { "" })
                        }
                    }
                )
            )
    }
}

private struct AlertTypeModifier: ViewModifier {

    var isAlertPresented: Binding<Bool>
    var type: () -> AlertBuilder.AlertStyle.AlertType

    @ViewBuilder
    public func body(content: Content) -> some View {
        switch type() {
        case .validationError(let text):
            textAlert(content: content, text: text)
        case .success(let text):
            textAlert(content: content, text: text)
        case .failure(let text):
            textAlert(content: content, text: text)
        case .message(let text):
            textAlert(content: content, text: text)
        case .messageTitle(let title, let text):
            textAlert(content: content, title: title, text: text)
        case .custom(let title, let text, let actions):
            actionsAlert(content: content, title: title, text: text, actions: actions)
        }
    }

    func textAlert(content: Content, title: () -> String = { "" }, text: () -> String) -> some View {
        content.alert(title(), isPresented: isAlertPresented, actions: {
            Button(NSLocalizedString("Ok", comment: "Ok"), action: {})
        }, message: {
            Text(text())
        })
    }

    func actionsAlert(content: Content, title: () -> String = { "" }, text: () -> String, actions: () -> [AlertAction] ) -> some View {
        content.alert(title(), isPresented: isAlertPresented, actions: {
            ForEach(actions(), id: \.id) { action in
                Button(action.title, role: action.role, action: action.action)
            }
        }, message: {
            Text(text())
        })
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
