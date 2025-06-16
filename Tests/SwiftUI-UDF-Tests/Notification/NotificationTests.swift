import SwiftUI
@testable import UDF
import XCTest

private extension Actions {
    struct PresentNotificationWithAction: Action {}
    struct PresentToastNotification: Action {}
    struct PresentCustomToastWithIcon: Action {}
    struct PresentCustomViewToast: Action {}
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
    
    static func toastWithAction(_ action: @escaping () -> Void) -> Self {
        .custom(
            content: NotificationContent(
                "Toast notification",
                message: "Toast with action button"
            ) {
                NotificationButton(title: "Action", action: action)
            },
            style: .toast()
        )
    }
    
    static func customToastWithIcon() -> Self {
        .custom(
            content: NotificationContent(
                "Custom Toast",
                message: "Toast with custom icon",
                icon: .systemImage("party.popper.fill")
            ),
            style: .toast(.vibrant)
        )
    }
    
    static func customViewToast() -> Self {
        .custom(
            content: NotificationContent {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("Custom View Toast")
                        .font(.headline)
                }
                .padding()
            },
            style: .toast(.center)
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
            case toastNotification
            case customToastWithIcon
            case customViewToast
        }
        
        var notification: NotificationState = .dismissed
        
        nonisolated mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.PresentNotificationWithAction:
                notification = .init(id: NotificationId.notificationWithAction)
                
            case is Actions.PresentToastNotification:
                notification = .init(id: NotificationId.toastNotification)
                
            case is Actions.PresentCustomToastWithIcon:
                notification = .init(id: NotificationId.customToastWithIcon)
                
            case is Actions.PresentCustomViewToast:
                notification = .init(id: NotificationId.customViewToast)
                
            default:
                break
            }
        }
    }
    
    override func setUp() {
        super.setUp()
        NotificationRegistry.clearAll()
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
        
        if case .presented(let notificationType) = status {
            XCTAssertEqual(notificationType.style, .alert)
        } else {
            XCTFail("Expected presented notification")
        }
    }
    
    func test_BasicNotificationInitializers() {
        // Test success notification
        let successNotification = NotificationState(success: "Operation completed")
        XCTAssertNotEqual(successNotification.status, .dismissed)
        
        if case .presented(let notificationType) = successNotification.status {
            XCTAssertEqual(notificationType.category, .success)
            XCTAssertEqual(notificationType.style, .alert) // Default style
        } else {
            XCTFail("Expected presented notification")
        }
        
        // Test error notification
        let errorNotification = NotificationState(error: "Something went wrong")
        XCTAssertNotEqual(errorNotification.status, .dismissed)
        
        if case .presented(let notificationType) = errorNotification.status {
            XCTAssertEqual(notificationType.category, .error)
        } else {
            XCTFail("Expected presented notification")
        }
        
        // Test warning notification
        let warningNotification = NotificationState(warning: "Storage almost full")
        XCTAssertNotEqual(warningNotification.status, .dismissed)
        
        // Test info notification
        let infoNotification = NotificationState(info: "3 new messages")
        XCTAssertNotEqual(infoNotification.status, .dismissed)
    }
    
    func test_NotificationWithToastStyle() {
        // Test notification with toast style
        let toastNotification = NotificationState(
            success: "Toast success message",
            style: .toast()
        )
        
        XCTAssertNotEqual(toastNotification.status, .dismissed)
        
        if case .presented(let notificationType) = toastNotification.status {
            if case .toast = notificationType.style {
                XCTAssertTrue(true, "Correct toast style")
            } else {
                XCTFail("Expected toast style notification")
            }
        } else {
            XCTFail("Expected presented notification")
        }
    }
    
    // MARK: - Toast-Specific Tests
    
    func test_WhenToastRegistered_ToastCanBePresentedById() async {
        let store = await XCTestStore(initial: AppState())
        var status = await store.state.form.notification.status
        XCTAssertEqual(status, .dismissed)
        
        NotificationRegistry.register(id: FormWithNotification.NotificationId.toastNotification) {
            .toastWithAction {
                print("Toast action executed")
            }
        }
        
        await store.dispatch(Actions.PresentToastNotification())
        status = await store.state.form.notification.status
        
        XCTAssertNotEqual(status, .dismissed)
        
        // Verify it's a toast style
        if case .presented(let notificationType) = status {
            if case .toast = notificationType.style {
                XCTAssertTrue(true, "Correct toast style")
            } else {
                XCTFail("Expected toast style notification")
            }
        } else {
            XCTFail("Expected presented notification")
        }
    }
    
    func test_CustomToastWithIcon() async {
        let store = await XCTestStore(initial: AppState())
        
        NotificationRegistry.register(id: FormWithNotification.NotificationId.customToastWithIcon) {
            .customToastWithIcon()
        }
        
        await store.dispatch(Actions.PresentCustomToastWithIcon())
        let status = await store.state.form.notification.status
        
        XCTAssertNotEqual(status, .dismissed)
        
        // Verify it's a toast with custom icon
        if case .presented(let notificationType) = status,
           case .custom(let content, let style) = notificationType {
            
            // Check style is toast
            if case .toast(let config) = style {
                XCTAssertEqual(config.theme, .vibrant)
            } else {
                XCTFail("Expected toast style")
            }
            
            // Check custom icon
            XCTAssertTrue(content.hasIcon)
            XCTAssertEqual(content.icon, .systemImage("party.popper.fill"))
            
        } else {
            XCTFail("Expected custom notification with content")
        }
    }
    
    func test_CustomViewToast() async {
        let store = await XCTestStore(initial: AppState())
        
        NotificationRegistry.register(id: FormWithNotification.NotificationId.customViewToast) {
            .customViewToast()
        }
        
        await store.dispatch(Actions.PresentCustomViewToast())
        let status = await store.state.form.notification.status
        
        XCTAssertNotEqual(status, .dismissed)
        
        // Verify it's a toast with custom view
        if case .presented(let notificationType) = status,
           case .custom(let content, let style) = notificationType {
            
            // Check style is toast
            if case .toast(let config) = style {
                XCTAssertEqual(config.position, .center)
            } else {
                XCTFail("Expected toast style")
            }
            
            // Check custom view
            XCTAssertTrue(content.hasCustomView)
            XCTAssertNotNil(content.customView)
            
        } else {
            XCTFail("Expected custom notification with custom view")
        }
    }
    
    func test_ToastConfiguration() {
        let customConfig = ToastConfiguration(
            theme: .vibrant,
            position: .bottom,
            defaultDuration: 3.0
        )
        
        let notification = NotificationState(
            error: "Toast with custom config",
            style: .toast(customConfig)
        )
        
        if case .presented(let notificationType) = notification.status,
           let toastConfig = notificationType.toastConfiguration {
            XCTAssertEqual(toastConfig.theme, .vibrant)
            XCTAssertEqual(toastConfig.position, .bottom)
            XCTAssertEqual(toastConfig.defaultDuration, 3.0)
        } else {
            XCTFail("Expected toast with configuration")
        }
    }
    
    // MARK: - Complex Content Tests
    
    func test_CustomNotificationWithContent() {
        let notification = NotificationState { 
            NotificationContent("Custom Title", message: "Custom message") {
                NotificationButton.destructive("Delete") {
                    print("Delete action")
                }
                NotificationButton.cancel("Cancel")
            }
        }
        
        XCTAssertNotEqual(notification.status, .dismissed)
        
        if case .presented(let notificationType) = notification.status,
           case .custom(let content, _) = notificationType {
            XCTAssertEqual(content.title, "Custom Title")
            XCTAssertEqual(content.message, "Custom message")
            XCTAssertTrue(content.hasActions)
            XCTAssertEqual(content.actionCount, 2)
        } else {
            XCTFail("Expected custom notification")
        }
    }
    
    func test_ToastWithContentAndActions() {
        let notification = NotificationState(style: .toast()) {
            NotificationContent("Toast Title", message: "Toast message") {
                NotificationButton.default("Action") {
                    print("Toast action")
                }
            }
        }
        
        if case .presented(let notificationType) = notification.status {
            if case .toast = notificationType.style {
                XCTAssertTrue(true, "Correct toast style")
            } else {
                XCTFail("Expected toast style")
            }
            
            if case .custom(let content, _) = notificationType {
                XCTAssertTrue(content.hasActions)
                XCTAssertEqual(content.actionCount, 1)
            } else {
                XCTFail("Expected custom content")
            }
        } else {
            XCTFail("Expected presented notification")
        }
    }
    
    // MARK: - Dismissed State Tests
    
    func test_DismissedState() {
        let dismissedNotification = NotificationState.dismissed
        XCTAssertEqual(dismissedNotification.status, .dismissed)
        
        let emptyNotification = NotificationState()
        XCTAssertEqual(emptyNotification.status, .dismissed)
        
        // Test with nil/empty strings
        let nilErrorNotification = NotificationState(error: nil)
        XCTAssertEqual(nilErrorNotification.status, .dismissed)
        
        let emptySuccessNotification = NotificationState(success: "")
        XCTAssertEqual(emptySuccessNotification.status, .dismissed)
    }
    
    // MARK: - Registry Tests
    
    func test_RegistryBehavior() {
        let testId = "test-notification"
        
        // Test unregistered ID returns dismissed
        let unregisteredNotification = NotificationState(id: testId)
        XCTAssertEqual(unregisteredNotification.status, .dismissed)
        
        // Register and test
        NotificationRegistry.register(id: testId) {
            .success("Registered notification", style: .toast())
        }
        
        let registeredNotification = NotificationState(id: testId)
        XCTAssertNotEqual(registeredNotification.status, .dismissed)
        
        if case .presented(let notificationType) = registeredNotification.status {
            XCTAssertEqual(notificationType.category, .success)
        } else {
            XCTFail("Expected presented notification from registry")
        }
    }
}
