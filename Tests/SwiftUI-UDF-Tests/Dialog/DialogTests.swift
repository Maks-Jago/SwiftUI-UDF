import SwiftUI
@testable import UDF
import Testing

private extension Actions {
    struct PresentDialogWithAction: Action {}
    struct PresentToastDialog: Action {}
    struct PresentCustomToastWithIcon: Action {}
    struct PresentCustomViewToast: Action {}
}

extension DialogType {
    static func dialogWithAction(_ action: @Sendable @escaping () -> Void) -> DialogCustomType<EmptyView, EmptyView> {
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
    
    static func toastWithAction(_ action: @Sendable @escaping () -> Void) -> DialogCustomType<EmptyView, EmptyView> {
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
    
    static func customViewToast() -> any DialogTypeProtocol {
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

@Suite struct DialogTests {
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
    
    init() {
        DialogRegistry.clearAll()
    }
    
    @Test func WhendialogRegistered_dialogCanBePresentedById() async {
        let store = await XCTestStore(initial: AppState())
        var status = await store.state.form.dialog.status
        #expect(status == .dismissed)
        
        DialogRegistry.register(id: FormWithDialog.DialogId.dialogWithAction) {
            DialogType.dialogWithAction {
                print("Custom dialog action")
            }
        }
        
        await store.dispatch(Actions.PresentDialogWithAction())
        status = await store.state.form.dialog.status
        
        #expect(status != .dismissed)
        
        if case .presented(let dialogType) = status {
            #expect(dialogType.style == .alert)
        } else {
            Issue.record("Expected presented dialog")
        }
    }
    
    @Test func BasicdialogInitializers() {
        // Test success dialog
        let successdialog = DialogStatus(success: "Operation completed")
        #expect(successdialog.status != .dismissed)
        
        if case .presented(let dialogType) = successdialog.status {
            #expect(dialogType.category == .success)
            #expect(dialogType.style == .alert) // Default style // Default style
        } else {
            Issue.record("Expected presented dialog")
        }
        
        // Test error dialog
        let errordialog = DialogStatus(error: "Something went wrong")
        #expect(errordialog.status != .dismissed)
        
        if case .presented(let dialogType) = errordialog.status {
            #expect(dialogType.category == .error)
        } else {
            Issue.record("Expected presented dialog")
        }
        
        // Test warning dialog
        let warningdialog = DialogStatus(warning: "Storage almost full")
        #expect(warningdialog.status != .dismissed)
        
        // Test info dialog
        let infodialog = DialogStatus(info: "3 new messages")
        #expect(infodialog.status != .dismissed)
    }
    
    @Test func dialogWithToastStyle() {
        // Test dialog with toast style
        let toastdialog = DialogStatus(
            success: "Toast success message",
            style: .toast()
        )
        
        #expect(toastdialog.status != .dismissed)
        
        if case .presented(let dialogType) = toastdialog.status {
            if case .toast = dialogType.style {
                #expect(true, "Correct toast style")
            } else {
                Issue.record("Expected toast style dialog")
            }
        } else {
            Issue.record("Expected presented dialog")
        }
    }
    
    // MARK: - Toast-Specific Tests
    
    @Test func WhenToastRegistered_ToastCanBePresentedById() async {
        let store = await XCTestStore(initial: AppState())
        var status = await store.state.form.dialog.status
        #expect(status == .dismissed)
        
        DialogRegistry.register(id: FormWithDialog.DialogId.toastDialog) {
            DialogType.toastWithAction {
                print("Toast action executed")
            }
        }
        
        await store.dispatch(Actions.PresentToastDialog())
        status = await store.state.form.dialog.status
        
        #expect(status != .dismissed)
        
        // Verify it's a toast style
        if case .presented(let dialogType) = status {
            if case .toast = dialogType.style {
                #expect(true, "Correct toast style")
            } else {
                Issue.record("Expected toast style dialog")
            }
        } else {
            Issue.record("Expected presented dialog")
        }
    }
    
    @Test func CustomToastWithIcon() async {
        let store = await XCTestStore(initial: AppState())
        
        DialogRegistry.register(id: FormWithDialog.DialogId.customToastWithIcon) {
            DialogType.customToastWithIcon()
        }
        
        await store.dispatch(Actions.PresentCustomToastWithIcon())
        let status = await store.state.form.dialog.status
        
        #expect(status != .dismissed)
        
        // Verify it's a toast with custom icon
        if case .presented(let dialogType) = status,
           case DialogCustomType<Image, EmptyView>.custom(let content, let style) = dialogType {

            // Check style is toast
            if case .toast(let config) = style {
                #expect(config.theme == .vibrant)
            } else {
                Issue.record("Expected toast style")
            }
            
            // Check custom icon
            #expect(content.hasIcon)
            
        } else {
            Issue.record("Expected custom dialog with content")
        }
    }
    
    @Test func CustomViewToast() async {
        let store = await XCTestStore(initial: AppState())
        
        DialogRegistry.register(id: FormWithDialog.DialogId.customViewToast) {
            DialogType.customViewToast()
        }
        
        await store.dispatch(Actions.PresentCustomViewToast())
        let status = await store.state.form.dialog.status
        
        #expect(status != .dismissed)
        
        // Verify it's a toast with custom view
        if case .presented(let dialogType) = status {
            // Check style is toast
            if case .toast(let config) = dialogType.style {
                #expect(config.position == .center)
            } else {
                Issue.record("Expected toast style")
            }
            
            // Check custom view
            #expect(!(dialogType is DialogType))
            #expect(dialogType.getCustomContentView() != nil)
            
        } else {
            Issue.record("Expected custom dialog with custom view")
        }
    }
    
    @Test func ToastConfiguration() {
        let customConfig = UDF.ToastConfiguration(
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
            #expect(toastConfig.theme == .vibrant)
            #expect(toastConfig.position == .bottom)
            #expect(toastConfig.defaultDuration == 3.0)
        } else {
            Issue.record("Expected toast with configuration")
        }
    }
    
    // MARK: - Complex Content Tests
    
    @Test func CustomDialogWithContent() {
        let dialog = DialogStatus(style: .alert) {
            DialogContent(title: "Custom Title", message: "Custom message", actions: {
                DialogButton.destructive("Delete") {
                    print("Delete action")
                }
                DialogButton.cancel("Cancel")
            })
        }
        
        #expect(dialog.status != .dismissed)

        if case .presented(let dialogType) = dialog.status {
            #expect(dialogType.title == "Custom Title")
            #expect(dialogType.message == "Custom message")
            #expect(!dialogType.actions.isEmpty)
            #expect(dialogType.actions.count == 2)
        } else {
            Issue.record("Expected custom dialog")
        }
    }
    
    @Test func ToastWithContentAndActions() {
        let dialog = DialogStatus(style: .toast()) {
            DialogContent(title: "Toast Title", message: "Toast message", actions: {
                DialogButton.default("Action") {
                    print("Toast action")
                }
            })
        }
        
        if case .presented(let dialogType) = dialog.status {
            if case .toast = dialogType.style {
                #expect(true, "Correct toast style")
            } else {
                Issue.record("Expected toast style")
            }
            
            // Check actions
            #expect(!dialogType.actions.isEmpty)
            #expect(dialogType.actions.count == 1)
        } else {
            Issue.record("Expected presented dialog")
        }
    }
    
    // MARK: - Dismissed State Tests
    
    @Test func DismissedState() {
        let dismissedDialog = DialogStatus.dismissed
        #expect(dismissedDialog.status == .dismissed)
        
        let emptyDialog = DialogStatus()
        #expect(emptyDialog.status == .dismissed)
        
        // Test with nil/empty strings
        let nilErrorDialog = DialogStatus(error: nil)
        #expect(nilErrorDialog.status == .dismissed)
        
        let emptySuccessDialog = DialogStatus(success: "")
        #expect(emptySuccessDialog.status == .dismissed)
    }
    
    // MARK: - Registry Tests
    
    @Test func RegistryBehavior() {
        let testId = "test-dialog"
        
        // Test unregistered ID returns dismissed
        let unregisteredDialog = DialogStatus(id: testId)
        #expect(unregisteredDialog.status == .dismissed)
        
        // Register and test
        DialogRegistry.register(id: testId) {
            DialogType.success(message: "Registered dialog", style: .toast())
        }
        
        let registeredDialog = DialogStatus(id: testId)
        #expect(registeredDialog.status != .dismissed)
        
        if case .presented(let dialogType) = registeredDialog.status {
            #expect(dialogType.category == .success)
        } else {
            Issue.record("Expected presented dialog from registry")
        }
    }
}
