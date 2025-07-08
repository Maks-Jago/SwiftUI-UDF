import SwiftUI
@testable import UDF
import XCTest

private extension Actions {
    struct PresentDialogWithAction: Action {}
    struct PresentToastDialog: Action {}
    struct PresentCustomToastWithIcon: Action {}
    struct PresentCustomViewToast: Action {}
}

extension DialogType {
    static func dialogWithAction(_ action: @escaping () -> Void) -> DialogCustomType<EmptyView, EmptyView> {
        DialogCustomType.custom(
            content: DialogContent(
                title: "Custom dialog title with action",
                message: "Custom dialog text with action", actions: {
                    DialogButton(title: "Action button", action: action)
                    DialogButton(title: "Cancel")
                        .role(.cancel)
                }
            ),
            style: .alert
        )
    }
    
    static func toastWithAction(_ action: @escaping () -> Void) -> DialogCustomType<EmptyView, EmptyView> {
        DialogCustomType.custom(
            content: DialogContent(
                title: "Toast dialog",
                message: "Toast with action button",
                actions: {
                    DialogButton(title: "Action", action: action)
                }
            ),
            style: .toast()
        )
    }
    
    static func customToastWithIcon() -> DialogCustomType<Image, EmptyView> {
        DialogCustomType.custom(
            content: DialogContent(
                title: "Custom Toast",
                message: "Toast with custom icon",
                iconImage: Image(systemName: "party.popper.fill"),
                actions: {}
            ),
            style: .toast(.vibrant)
        )
    }
    
    static func customViewToast() -> DialogTypeProtocol {
        DialogCustomType.custom(
            content: DialogContent {
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

final class DialogTests: XCTestCase {
    struct AppState: AppReducer {
        var form = FormWithDialog()
    }
    
    struct FormWithDialog: UDF.Form {
        enum DialogId: Hashable {
            case dialogWithAction
            case toastDialog
            case customToastWithIcon
            case customViewToast
        }
        
        var dialog: DialogStatus = .dismissed
        
        nonisolated mutating func reduce(_ action: some Action) {
            switch action {
            case is Actions.PresentDialogWithAction:
                dialog = .init(id: DialogId.dialogWithAction)
                
            case is Actions.PresentToastDialog:
                dialog = .init(id: DialogId.toastDialog)
                
            case is Actions.PresentCustomToastWithIcon:
                dialog = .init(id: DialogId.customToastWithIcon)
                
            case is Actions.PresentCustomViewToast:
                dialog = .init(id: DialogId.customViewToast)
                
            default:
                break
            }
        }
    }
    
    override func setUp() {
        super.setUp()
        DialogRegistry.clearAll()
    }
    
    func test_WhendialogRegistered_dialogCanBePresentedById() async {
        let store = await XCTestStore(initial: AppState())
        var status = await store.state.form.dialog.status
        XCTAssertEqual(status, .dismissed)
        
        DialogRegistry.register(id: FormWithDialog.DialogId.dialogWithAction) {
            DialogType.dialogWithAction {
                print("Custom dialog action")
            }
        }
        
        await store.dispatch(Actions.PresentDialogWithAction())
        status = await store.state.form.dialog.status
        
        XCTAssertNotEqual(status, .dismissed)
        
        if case .presented(let dialogType) = status {
            XCTAssertEqual(dialogType.style, .alert)
        } else {
            XCTFail("Expected presented dialog")
        }
    }
    
    func test_BasicdialogInitializers() {
        // Test success dialog
        let successdialog = DialogStatus(success: "Operation completed")
        XCTAssertNotEqual(successdialog.status, .dismissed)
        
        if case .presented(let dialogType) = successdialog.status {
            XCTAssertEqual(dialogType.category, .success)
            XCTAssertEqual(dialogType.style, .alert) // Default style
        } else {
            XCTFail("Expected presented dialog")
        }
        
        // Test error dialog
        let errordialog = DialogStatus(error: "Something went wrong")
        XCTAssertNotEqual(errordialog.status, .dismissed)
        
        if case .presented(let dialogType) = errordialog.status {
            XCTAssertEqual(dialogType.category, .error)
        } else {
            XCTFail("Expected presented dialog")
        }
        
        // Test warning dialog
        let warningdialog = DialogStatus(warning: "Storage almost full")
        XCTAssertNotEqual(warningdialog.status, .dismissed)
        
        // Test info dialog
        let infodialog = DialogStatus(info: "3 new messages")
        XCTAssertNotEqual(infodialog.status, .dismissed)
    }
    
    func test_dialogWithToastStyle() {
        // Test dialog with toast style
        let toastdialog = DialogStatus(
            success: "Toast success message",
            style: .toast()
        )
        
        XCTAssertNotEqual(toastdialog.status, .dismissed)
        
        if case .presented(let dialogType) = toastdialog.status {
            if case .toast = dialogType.style {
                XCTAssertTrue(true, "Correct toast style")
            } else {
                XCTFail("Expected toast style dialog")
            }
        } else {
            XCTFail("Expected presented dialog")
        }
    }
    
    // MARK: - Toast-Specific Tests
    
    func test_WhenToastRegistered_ToastCanBePresentedById() async {
        let store = await XCTestStore(initial: AppState())
        var status = await store.state.form.dialog.status
        XCTAssertEqual(status, .dismissed)
        
        DialogRegistry.register(id: FormWithDialog.DialogId.toastDialog) {
            DialogType.toastWithAction {
                print("Toast action executed")
            }
        }
        
        await store.dispatch(Actions.PresentToastDialog())
        status = await store.state.form.dialog.status
        
        XCTAssertNotEqual(status, .dismissed)
        
        // Verify it's a toast style
        if case .presented(let dialogType) = status {
            if case .toast = dialogType.style {
                XCTAssertTrue(true, "Correct toast style")
            } else {
                XCTFail("Expected toast style dialog")
            }
        } else {
            XCTFail("Expected presented dialog")
        }
    }
    
    func test_CustomToastWithIcon() async {
        let store = await XCTestStore(initial: AppState())
        
        DialogRegistry.register(id: FormWithDialog.DialogId.customToastWithIcon) {
            DialogType.customToastWithIcon()
        }
        
        await store.dispatch(Actions.PresentCustomToastWithIcon())
        let status = await store.state.form.dialog.status
        
        XCTAssertNotEqual(status, .dismissed)
        
        // Verify it's a toast with custom icon
        if case .presented(let dialogType) = status,
           case DialogCustomType<Image, EmptyView>.custom(let content, let style) = dialogType {

            // Check style is toast
            if case .toast(let config) = style {
                XCTAssertEqual(config.theme, .vibrant)
            } else {
                XCTFail("Expected toast style")
            }
            
            // Check custom icon
            XCTAssertTrue(content.hasIcon)
//            XCTAssertEqual(content.icon, .systemImage("party.popper.fill"))
            
        } else {
            XCTFail("Expected custom dialog with content")
        }
    }
    
    func test_CustomViewToast() async {
        let store = await XCTestStore(initial: AppState())
        
        DialogRegistry.register(id: FormWithDialog.DialogId.customViewToast) {
            DialogType.customViewToast()
        }
        
        await store.dispatch(Actions.PresentCustomViewToast())
        let status = await store.state.form.dialog.status
        
        XCTAssertNotEqual(status, .dismissed)
        
        // Verify it's a toast with custom view
        if case .presented(let dialogType) = status {
//           case .custom(let content, let style) = dialogType  {

            // Check style is toast
            if case .toast(let config) = dialogType.style {
                XCTAssertEqual(config.position, .center)
            } else {
                XCTFail("Expected toast style")
            }
            
            // Check custom view
            XCTAssertFalse(dialogType is DialogType)
//            XCTAssertNotNil(content.customView)
            
        } else {
            XCTFail("Expected custom dialog with custom view")
        }
    }
    
    func test_ToastConfiguration() {
        let customConfig = ToastConfiguration(
            theme: .vibrant,
            position: .bottom,
            defaultDuration: 3.0
        )
        
        let dialog = DialogStatus(
            error: "Toast with custom config",
            style: .toast(customConfig)
        )
        
        if case .presented(let dialogType) = dialog.status,
           let toastConfig = dialogType.toastConfiguration {
            XCTAssertEqual(toastConfig.theme, .vibrant)
            XCTAssertEqual(toastConfig.position, .bottom)
            XCTAssertEqual(toastConfig.defaultDuration, 3.0)
        } else {
            XCTFail("Expected toast with configuration")
        }
    }
    
    // MARK: - Complex Content Tests
    
    func test_CustomDialogWithContent() {
        let dialog = DialogStatus(style: .alert) {
            DialogContent(title: "Custom Title", message: "Custom message", actions: {
                DialogButton.destructive("Delete") {
                    print("Delete action")
                }
                DialogButton.cancel("Cancel")
            })
        }
        
        XCTAssertNotEqual(dialog.status, .dismissed)

        if case .presented(let dialogType) = dialog.status {
            XCTAssertEqual(dialogType.title, "Custom Title")
            XCTAssertEqual(dialogType.message, "Custom message")
            XCTAssertFalse(dialogType.actions.isEmpty)
            XCTAssertEqual(dialogType.actions.count, 2)
        } else {
            XCTFail("Expected custom dialog")
        }
    }
    
    func test_ToastWithContentAndActions() {
        let dialog = DialogStatus(style: .toast()) {
            DialogContent(title: "Toast Title", message: "Toast message", actions: {
                DialogButton.default("Action") {
                    print("Toast action")
                }
            })
        }
        
        if case .presented(let dialogType) = dialog.status {
            if case .toast = dialogType.style {
                XCTAssertTrue(true, "Correct toast style")
            } else {
                XCTFail("Expected toast style")
            }
            
//            if case .custom(let content, _) = dialogType {
            XCTAssertFalse(dialogType.actions.isEmpty)
            XCTAssertEqual(dialogType.actions.count, 1)
//            } else {
//                XCTFail("Expected custom content")
//            }
        } else {
            XCTFail("Expected presented dialog")
        }
    }
    
    // MARK: - Dismissed State Tests
    
    func test_DismissedState() {
        let dismissedDialog = DialogStatus.dismissed
        XCTAssertEqual(dismissedDialog.status, .dismissed)
        
        let emptyDialog = DialogStatus()
        XCTAssertEqual(emptyDialog.status, .dismissed)
        
        // Test with nil/empty strings
        let nilErrorDialog = DialogStatus(error: nil)
        XCTAssertEqual(nilErrorDialog.status, .dismissed)
        
        let emptySuccessDialog = DialogStatus(success: "")
        XCTAssertEqual(emptySuccessDialog.status, .dismissed)
    }
    
    // MARK: - Registry Tests
    
    func test_RegistryBehavior() {
        let testId = "test-dialog"
        
        // Test unregistered ID returns dismissed
        let unregisteredDialog = DialogStatus(id: testId)
        XCTAssertEqual(unregisteredDialog.status, .dismissed)
        
        // Register and test
        DialogRegistry.register(id: testId) {
            DialogType.success(message: "Registered dialog", style: .toast())
        }
        
        let registeredDialog = DialogStatus(id: testId)
        XCTAssertNotEqual(registeredDialog.status, .dismissed)
        
        if case .presented(let dialogType) = registeredDialog.status {
            XCTAssertEqual(dialogType.category, .success)
        } else {
            XCTFail("Expected presented dialog from registry")
        }
    }
}
