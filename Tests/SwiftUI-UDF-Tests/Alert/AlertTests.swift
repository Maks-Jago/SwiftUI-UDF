import SwiftUI
@testable import UDF
import UDFSwiftTesting
import Testing

private extension Actions {
    struct PresentAlertWithAction: Action {}
}

extension AlertBuilder.AlertStyle {
    static func alertWithAction(_ action: @Sendable @escaping () -> Void) -> Self {
        .init(title: "Custom alert title with action", text: "Custom alert text with action") {
            AlertButton(title: "Action button", action: action)
            
            AlertButton(title: "Cancel")
                .role(.cancel)
        }
    }
}

@Suite(.serialized) struct AlertTests {
    struct AppState: AppReducer {
        var form = FormWithAlert()
    }
    
    struct FormWithAlert: UDF.Form {
        enum AlertId: Hashable {
            case alertWithAction
        }
        
        var alert: AlertBuilder.AlertStatus = .dismissed
        
        mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.PresentAlertWithAction:
                alert = .init(id: AlertId.alertWithAction)
                
            default:
                break
            }
        }
    }

    @Test
    func whenAlerBuilderRegistered_AlertCanBePresentedById() async {
        let store = EnvironmentStore(initial: AppState(), loggers: [])
        var status = store.state.form.alert.status
        
        #expect(status == .dismissed)
        
        AlertBuilder.registerAlert(by: FormWithAlert.AlertId.alertWithAction) {
            .alertWithAction {
                print("Custom alert action")
            }
        }
        
        store.dispatch(Actions.PresentAlertWithAction())
        await waitForCondition {
            store.state.form.alert.status != .dismissed
        }
        status = store.state.form.alert.status
        
        #expect(status != .dismissed)
    }
}
