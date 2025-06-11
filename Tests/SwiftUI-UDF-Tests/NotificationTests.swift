import SwiftUI
@testable import UDF
import XCTest

private extension Actions {
    struct PresentNotificationWithAction: Action {}
}

extension NotificationType {
    static func notificationWithAction(_ action: @escaping () -> Void) -> Self {
        .custom(
            content: NotificationContent(
                "Custom notification title with action",
                message: "Custom notification text with action"
            ) {
                NotificationButton(title: "Action button", action: action)
                NotificationButton(title: "Cancel")
                    .role(.cancel)
            },
            style: .alert
        )
    }
}

final class NotificationTests: XCTestCase {
    struct AppState: AppReducer {
        var form = FormWithNotification()
    }
    
    struct FormWithNotification: UDF.Form {
        enum NotificationId: Hashable {
            case notificationWithAction
        }
        
        var notification: NotificationState = .dismissed
        
        nonisolated mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.PresentNotificationWithAction:
                notification = .init(id: NotificationId.notificationWithAction)
                
            default:
                break
            }
        }
    }
    
    func test_WhenNotificationRegistered_NotificationCanBePresentedById() async {
        let store = await XCTestStore(initial: AppState())
        var status = await store.state.form.notification.status
        XCTAssertEqual(status, .dismissed)
        
        NotificationRegistry.register(id: FormWithNotification.NotificationId.notificationWithAction) {
            .notificationWithAction {
                print("Custom notification action")
            }
        }
        
        await store.dispatch(Actions.PresentNotificationWithAction())
        status = await store.state.form.notification.status
        
        XCTAssertNotEqual(status, .dismissed)
    }
}
