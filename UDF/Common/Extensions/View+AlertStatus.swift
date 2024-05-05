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

        return contentBody(isAlertPresented: isAlertPresented, content: content)
    }

    @ViewBuilder
    public func contentBody(isAlertPresented: Binding<Bool>, content: Content) -> some View {
        let type = if case let .presented(alertStyle) = localAlert?.status {
            alertStyle.type
        } else {
            AlertBuilder.AlertStyle.AlertType.message(text: { "" })
        }

        switch type {
        case .validationError(let text):
            textAlert(isAlertPresented, content: content, text: text)
        case .success(let text):
            textAlert(isAlertPresented, content: content, text: text)
        case .failure(let text):
            textAlert(isAlertPresented, content: content, text: text)
        case .message(let text):
            textAlert(isAlertPresented, content: content, text: text)
        case .messageTitle(let title, let text):
            textAlert(isAlertPresented, content: content, title: title, text: text)
        case .custom(let title, let text, let actions):
            actionsAlert(isAlertPresented, content: content, title: title, text: text, actions: actions)
        }
    }

    func textAlert(_ isAlertPresented: Binding<Bool>, content: Content, title: () -> String = { "" }, text: () -> String) -> some View {
        content.alert(title(), isPresented: isAlertPresented, actions: {
            Button(NSLocalizedString("Ok", comment: "Ok"), action: {})
        }, message: {
            Text(text())
        })
    }

    func actionsAlert(_ isAlertPresented: Binding<Bool>, content: Content, title: () -> String = { "" }, text: () -> String, actions: () -> [AlertAction] ) -> some View {
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
}
