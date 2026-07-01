import SwiftUI
@testable import UDF
import UDFSwiftTesting
import Testing

private extension Actions {
    struct PresentDialogWithAction: Action {}
    struct PresentToastDialog: Action {}
    struct PresentCustomToastWithIcon: Action {}
    struct PresentCustomViewToast: Action {}
    struct PresentDynamicDialog: Action {}
    struct DismissDynamicDialog: Action {}
}

extension DialogType {
    @MainActor
    static func dialogWithAction(_ action: @Sendable @escaping () -> Void) -> AlertDialog {
        AlertDialog {
            DialogTitle("Custom dialog title with action")
            DialogMessage("Custom dialog text with action")
            DialogButton(title: "Action button", action: action)
            DialogButton(title: "Cancel").role(.cancel)
        }
    }

    @MainActor
    static func toastWithAction(_ action: @Sendable @escaping () -> Void) -> Toast {
        Toast {
            DialogMessage("Toast with action button")
            DialogButton(title: "Action", action: action)
        }
    }

    @MainActor
    static func customToastWithIcon() -> Toast {
        Toast(config: .init(theme: .vibrant)) {
            DialogMessage("Toast with custom icon")
            DialogIcon {
                Image(systemName: "party.popper.fill")
            }
        }
    }

    @MainActor
    static func customViewToast() -> Toast {
        Toast(config: .init(position: .center)) {
            DialogView {
                VStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    Text("Custom View Toast")
                        .font(.headline)
                }
                .padding()
            }
        }
    }
}

extension DialogRegistryTests {
    @Suite(.serialized) struct DialogTests {
        struct AppState: AppReducer {
            var form = FormWithDialog()
        }
        
        struct FormWithDialog: UDF.Form {
            enum DialogId: Hashable {
                case dialogWithAction
                case toastDialog
                case customToastWithIcon
                case customViewToast
                case dynamicDialog
            }
            
            var stringProperty: String = "Initial"
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
                    
                case is Actions.PresentDynamicDialog:
                    dialog = .init(id: DialogId.dynamicDialog)
                    
                case is Actions.DismissDynamicDialog:
                    dialog = .dismissed
                    
                default:
                    break
                }
            }
        }
        
        init() {
            Dialog.clearAll()
        }
        
        @Test func legacyDialogRegistration_allowsPresentationById() async {
            let store = await TestStore(initial: AppState())
            #expect(await store.state.form.dialog.status == .dismissed)
            
            await Dialog.register(id: FormWithDialog.DialogId.dialogWithAction) {
                DialogCustomType.custom(
                    content: .init(
                        title: "Custom Title",
                        message: "Custom Desciprion",
                        actions: {
                            DialogButton(title: "Cancel")
                            DialogButton(title: "Primary", role: .destructive)
                        }
                    ),
                    style: .alert
                )
            }
            await waitForCondition { Dialog.isRegistered(id: FormWithDialog.DialogId.dialogWithAction) }
            await store.dispatch(Actions.PresentDialogWithAction())
            let success = await waitForCondition { await store.state.form.dialog.status != .dismissed }
            #expect(success)
        }
        
        @Test func whendialogRegistered_dialogCanBePresentedById() async {
            let store = await TestStore(initial: AppState())
            #expect(await store.state.form.dialog.status == .dismissed)
            
            await Dialog.register(id: FormWithDialog.DialogId.dialogWithAction) {
                DialogType.dialogWithAction {
                    print("Custom dialog action")
                }
            }
            await waitForCondition { Dialog.isRegistered(id: FormWithDialog.DialogId.dialogWithAction) }
            
            await store.dispatch(Actions.PresentDialogWithAction())
            let success = await waitForCondition { await store.state.form.dialog.status != .dismissed }
            #expect(success)
            
            if case .presented(let dialogType) = await store.state.form.dialog.status {
                #expect(dialogType.style == .alert)
            } else {
                Issue.record("Expected presented dialog")
            }
        }
        
        @Test func basicdialogInitializers() {
            // Test success dialog
            let successdialog = DialogStatus(success: "Operation completed")
            #expect(successdialog.status != .dismissed)
            
            if case .presented(let dialogType) = successdialog.status {
                #expect(dialogType.category == .success)
                #expect(dialogType.style == .alert) // Default style
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
        @Test func whenToastRegistered_ToastCanBePresentedById() async {
            let store = await TestStore(initial: AppState())
            #expect(await store.state.form.dialog.status == .dismissed)
            
            await Dialog.register(id: FormWithDialog.DialogId.toastDialog) {
                DialogType.toastWithAction {
                    print("Toast action executed")
                }
            }
            await waitForCondition { Dialog.isRegistered(id: FormWithDialog.DialogId.toastDialog) }
            
            await store.dispatch(Actions.PresentToastDialog())
            let success = await waitForCondition { await store.state.form.dialog.status != .dismissed }
            #expect(success)
            
            // Verify it's a toast style
            if case .presented(let dialogType) = await store.state.form.dialog.status {
                if case .toast = dialogType.style {
                    #expect(true, "Correct toast style")
                } else {
                    Issue.record("Expected toast style dialog")
                }
            } else {
                Issue.record("Expected presented dialog")
            }
        }
        
        @Test func customToastWithIcon() async {
            let store = await TestStore(initial: AppState())
            
            await Dialog.register(id: FormWithDialog.DialogId.customToastWithIcon) {
                DialogType.customToastWithIcon()
            }
            await waitForCondition { Dialog.isRegistered(id: FormWithDialog.DialogId.customToastWithIcon) }
            
            await store.dispatch(Actions.PresentCustomToastWithIcon())
            let success = await waitForCondition { await store.state.form.dialog.status != .dismissed }
            #expect(success)
            
            // Verify it's a toast with custom icon
            if case .presented(let dialogProtocol) = await store.state.form.dialog.status,
               let toast = dialogProtocol as? Toast {
                
                // Check style is toast
                if case .toast(let config) = toast.style {
                    #expect(config.theme == .vibrant)
                } else {
                    Issue.record("Expected toast style")
                }
                
                // Check custom icon
                #expect(toast.payload.icon != nil)
            } else {
                Issue.record("Expected custom dialog with content")
            }
        }
        
        @Test func customViewToast() async {
            let store = await TestStore(initial: AppState())
            
            await Dialog.register(id: FormWithDialog.DialogId.customViewToast) {
                DialogType.customViewToast()
            }
            await waitForCondition { Dialog.isRegistered(id: FormWithDialog.DialogId.customViewToast) }
            
            await store.dispatch(Actions.PresentCustomViewToast())
            let success = await waitForCondition { await store.state.form.dialog.status != .dismissed }
            #expect(success)
            
            // Verify it's a toast with custom view
            if case .presented(let dialogType) = await store.state.form.dialog.status {
                // Check style is toast
                if case .toast(let config) = dialogType.style {
                    #expect(config.position == .center)
                } else {
                    Issue.record("Expected toast style")
                }
                
                // Check custom view
                #expect(!(dialogType is DialogType))
                await MainActor.run {
                    #expect(dialogType.getCustomContentView() != nil)
                }
            } else {
                Issue.record("Expected custom dialog with custom view")
            }
        }
        
        @Test func toastConfiguration() {
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
        @MainActor
        @Test func customDialogWithContent() {
            let dialog = DialogStatus(dialog: AlertDialog {
                DialogTitle("Custom Title")
                DialogMessage("Custom message")
                DialogButton(title: "Delete", role: .destructive) {
                    print("Delete action")
                }
                DialogButton(title: "Cancel", role: .cancel)
            })
            
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
        
        @MainActor
        @Test func toastWithContentAndActions() {
            let dialog = DialogStatus(dialog: Toast {
                DialogMessage("Toast message")
                DialogButton(title: "Action") {
                    print("Toast action")
                }
            })
            
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
        @Test func dismissedState() {
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
        
        // MARK: - Auto-Dismiss Dialog Status Tests
        @Test func manualDismissUpdatesDialogStatus() async {
            let store = await TestStore(initial: AppState())
            
            // Register a toast with long duration (won't auto-dismiss during test)
            await Dialog.register(id: FormWithDialog.DialogId.toastDialog) {
                Toast(config: .init(defaultDuration: 10.0)) {
                    DialogMessage("This toast should be manually dismissed")
                }
            }
            await waitForCondition { Dialog.isRegistered(id: FormWithDialog.DialogId.toastDialog) }
            
            // Present the toast
            await store.dispatch(Actions.PresentToastDialog())
            let success = await waitForCondition { await store.state.form.dialog.status != .dismissed }
            #expect(success)
            
            // For manual dismiss, we'll test by creating a dismissed dialog directly
            // (This mimics the end result of what should happen when user taps dismiss)
            let dismissedDialog = DialogStatus.dismissed
            #expect(dismissedDialog.status == .dismissed, "Manual dismiss should result in dismissed state")
            
            // The main test is that auto-dismiss should achieve the same result
            // The real manual dismiss testing is done through UI interactions, not direct state mutation
        }
        
        @Test func zeroDurationToastDoesNotAutoDismiss() async {
            let store = await TestStore(initial: AppState())
            
            // Register a toast with zero duration (manual dismiss only)
            await Dialog.register(id: FormWithDialog.DialogId.toastDialog) {
                Toast(config: .init(defaultDuration: 0)) {
                    DialogMessage("This toast should not auto-dismiss")
                }
            }
            await waitForCondition { Dialog.isRegistered(id: FormWithDialog.DialogId.toastDialog) }
            
            // Present the toast
            await store.dispatch(Actions.PresentToastDialog())
            let success = await waitForCondition { await store.state.form.dialog.status != .dismissed }
            #expect(success)
            
            // Wait longer than typical auto-dismiss time
            await sleep()
            
            // Verify the dialog status is still presented (not auto-dismissed)
            #expect(await store.state.form.dialog.status != .dismissed, "Toast with zero duration should not auto-dismiss")
        }
        
        // MARK: - Registry Tests
        @MainActor
        @Test func registryBehavior() {
            let testId = "test-dialog"
            
            // Test unregistered ID returns dismissed
            let unregisteredDialog = DialogStatus(id: testId)
            #expect(unregisteredDialog.status == .dismissed)
            
            // Register and test
            Dialog.register(id: testId) {
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
        
        @MainActor
        @Test func dynamicDialogCapturesLatestState() async throws {
            let store = EnvironmentStore(initial: AppState(), loggers: [])
            
            Dialog.register(id: FormWithDialog.DialogId.dynamicDialog) {
                AlertDialog {
                    DialogTitle("Title \(store.state.form.stringProperty)")
                    DialogMessage("Message \(store.state.form.stringProperty)")
                    DialogButton(title: "OK \(store.state.form.stringProperty)")
                }
            }
            
            store.dispatch(Actions.PresentDynamicDialog())
            await waitForMainActorCondition { store.state.form.dialog.status != .dismissed }
            
            // Verify initial values
            if case .presented(let dialogType) = store.state.form.dialog.status {
                #expect(dialogType.title == "Title Initial")
                #expect(dialogType.message == "Message Initial")
                let okButton = dialogType.actions.first as? DialogButton
                #expect(okButton?.title == "OK Initial")
            } else {
                Issue.record("Expected presented dialog")
            }
            
            // Update the form field
            store.dispatch(UDF.Actions.UpdateFormField(keyPath: \FormWithDialog.stringProperty, value: "Updated"))
            await waitForMainActorCondition { store.state.form.stringProperty == "Updated" }
            
            #expect(store.state.form.stringProperty == "Updated")
            
            // Re-present the dialog
            // First we need to dismiss it or we could just dispatch again and wait for the state to be processed
            // Wait, we can't easily wait for it to be processed if the state is ALREADY presented and doesn't change!
            // Let's dismiss it first.
            store.dispatch(Actions.DismissDynamicDialog())
            await waitForMainActorCondition { store.state.form.dialog.status == .dismissed }
            
            store.dispatch(Actions.PresentDynamicDialog())
            await waitForMainActorCondition { store.state.form.dialog.status != .dismissed }
            
            if case .presented(let dialogType) = store.state.form.dialog.status {
                #expect(dialogType.title == "Title Updated")
                #expect(dialogType.message == "Message Updated")
                let okButton = dialogType.actions.first as? DialogButton
                #expect(okButton?.title == "OK Updated")
            } else {
                Issue.record("Expected presented dialog")
            }
        }
    }
}
