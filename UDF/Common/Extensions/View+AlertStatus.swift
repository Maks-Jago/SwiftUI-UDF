import Foundation
import SwiftUI

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
            .alert(item: $localAlert.willSet({ (newValue, oldValue) in
                guard newValue != oldValue else {
                    return
                }

                if let newValue = newValue {
                    alertStatus = newValue
                } else if oldValue?.status != .dismissed {
                    alertToDissmiss = localAlert
                    alertStatus = .dismissed
                }
            })) { alertStatus in
                switch alertStatus.status {
                case .presented(let alertStyle):
                    return AlertBuilder.buildAlert(for: alertStyle)

                default:
                    return Alert(title: Text(""))
                }
            }
    }
}

private struct AlertWrapperModifier: ViewModifier {
    @Binding var alertStatus: AlertBuilder.AlertStatus
    @State private var isPresented: Bool = false
    @State private var style: AlertStyleUpd = .init()
    
    init(alert: Binding<AlertBuilder.AlertStatus>) {
        _alertStatus = alert
        if alert.wrappedValue.status != .dismissed {
            _isPresented = .init(initialValue: true)
            guard case .presentedWithStyle(let stylePresented) = alert.wrappedValue.status else {
                return
            }
            _style = .init(initialValue: stylePresented)
        } else {
            style = .init()
            isPresented = false
        }
    }
    
    public func body(content: Content) -> some View {
        switch (isPresented, alertStatus.status) {
        case (false, .dismissed):
            break
            
        case (true, .dismissed):
            DispatchQueue.main.async {
                isPresented = false
            }
            
        case (false, .presentedWithStyle(let style)):
            if self.style != style {
                DispatchQueue.main.async {
                    isPresented = true
                    self.style = style
                }
            } else {
                DispatchQueue.main.async {
                    alertStatus = .dismissed
                }
            }
            
        case (true, .presentedWithStyle):
            print("DEBUG: Alert presented")
            
        default:
            break
        }
        
        return buildAlert(for: content)
    }
    
    @ViewBuilder
    private func buildAlert(for content: Content) -> some View {
        switch style.alertType {
        case .title:
            content
                .alert(style.title, isPresented: $isPresented, actions: {
                    ForEach(style.actions, id: \.id) { action in
                        Button(action.title, role: action.role, action: action.action)
                    }
                })
        case .message, .error:
            content
                .alert(style.title, isPresented: $isPresented, actions: {
                    ForEach(style.actions, id: \.id) { action in
                        Button(action.title, role: action.role, action: action.action)
                    }
                }, message: {
                    Text(style.message)
                })
        case .none:
            content
                .alert("", isPresented: .constant(false)) {
                    Button("", role: .none, action: {})
                }
        }
    }
}

public extension View {
    @available(*, deprecated, message: "Use alert(statusWrapper: _) instead")
    func alert(status: Binding<AlertBuilder.AlertStatus>) -> some View {
        self.modifier(AlertModifier(alert: status))
    }
    
    func alert(statusWrapper: Binding<AlertBuilder.AlertStatus>) -> some View {
        self.modifier(AlertWrapperModifier(alert: statusWrapper))
    }
}
