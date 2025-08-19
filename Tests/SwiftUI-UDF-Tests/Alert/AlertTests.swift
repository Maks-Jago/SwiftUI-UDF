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

@Suite struct AlertTests {
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
        let store = await TestStore(initial: AppState())
        #expect(await store.state.form.alert.status == .dismissed)
        
        AlertBuilder.registerAlert(by: FormWithAlert.AlertId.alertWithAction) {
            .alertWithAction {
                print("Custom alert action")
            }
        }
        
        await store.dispatch(Actions.PresentAlertWithAction())
        // Sometimes fails. Ping to the channel if reproduce once
        let success = await waitForAsyncCondition(timeout: 10) { await store.state.form.alert.status != .dismissed }
        #expect(success)
    }
}
