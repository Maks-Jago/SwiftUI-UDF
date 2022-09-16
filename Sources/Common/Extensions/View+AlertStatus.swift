import Foundation
import SwiftUI

public extension View {
    func alert(status: Binding<AlertBuilder.AlertStatus>) -> some View {
        let binding: Binding<AlertBuilder.AlertStatus?> = Binding(
            get: { status.wrappedValue.status == .dismissed ? nil : status.wrappedValue },
            set: { newValue in
                if let newValue = newValue {
                    status.wrappedValue = newValue
                } else {
                    status.wrappedValue.status = .dismissed
                }
            }
        )

        return self.alert(item: binding) { alertStatus in
            switch alertStatus.status {
            case .presented(let alertStyle):
                return AlertBuilder.buildAlert(for: alertStyle)

            default:
                return Alert(title: Text(""))
            }
        }
    }
}
