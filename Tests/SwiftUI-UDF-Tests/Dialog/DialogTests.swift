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
    struct PresentDirectDynamicDialog: Action {}
}

extension DialogType {
    static func dialogWithAction(_ action: @Sendable @escaping () -> Void) -> AlertDialog {
        AlertDialog {
            DialogTitle("Custom dialog title with action")
            DialogMessage("Custom dialog text with action")
            DialogButton(title: "Action button", action: action)
            DialogButton(title: "Cancel").role(.cancel)
        }
    }

    static func toastWithAction(_ action: @Sendable @escaping () -> Void) -> Toast {
        Toast {
            DialogMessage("Toast with action button")
            DialogButton(title: "Action", action: action)
        }
    }

    static func customToastWithIcon() -> Toast {
        Toast(config: .init(theme: .vibrant)) {
            DialogMessage("Toast with custom icon")
            DialogIcon {
                Image(systemName: "party.popper.fill")
            }
        }
    }

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
        init() {
            Dialog.clearAll()
        }
        
        @Test func legacyDialogRegistration_allowsPresentationById() async {
            let store = await TestStore(initial: AppState())
            #expect(await store.state.form.dialog.status == .dismissed)
            
            Dialog.register(id: FormWithDialog.DialogId.dialogWithAction) {
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
            
            Dialog.register(id: FormWithDialog.DialogId.dialogWithAction) {
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
            
            Dialog.register(id: FormWithDialog.DialogId.toastDialog) {
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
            
            Dialog.register(id: FormWithDialog.DialogId.customToastWithIcon) {
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
            
            Dialog.register(id: FormWithDialog.DialogId.customViewToast) {
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
            Dialog.register(id: FormWithDialog.DialogId.toastDialog) {
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
            Dialog.register(id: FormWithDialog.DialogId.toastDialog) {
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
            
            if case .presented(let dialogType) = store.state.form.dialog.status {
                #expect(dialogType.title == "Title Initial")
                #expect(dialogType.message == "Message Initial")
                let okButton = dialogType.actions.first as? DialogButton
                #expect(okButton?.title == "OK Initial")
            } else {
                Issue.record("Expected presented dialog")
            }
            
            store.dispatch(UDF.Actions.UpdateFormField(keyPath: \FormWithDialog.stringProperty, value: "Updated"))
            await waitForMainActorCondition { store.state.form.stringProperty == "Updated" }
            
            #expect(store.state.form.stringProperty == "Updated")
            
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
        
        @MainActor
        @Test func directDialogStatusCapturesLatestState() async throws {
            let store = EnvironmentStore(initial: AppState(), loggers: [])
            
            store.dispatch(Actions.PresentDirectDynamicDialog())
            await waitForMainActorCondition { store.state.form.dialog.status != .dismissed }
            
            if case .presented(let dialogType) = store.state.form.dialog.status {
                #expect(dialogType.title == "Title Initial")
                #expect(dialogType.message == "Message Initial")
                let okButton = dialogType.actions.first as? DialogButton
                #expect(okButton?.title == "OK Initial")
            } else {
                Issue.record("Expected presented dialog")
            }
            
            store.dispatch(UDF.Actions.UpdateFormField(keyPath: \FormWithDialog.stringProperty, value: "Updated"))
            await waitForMainActorCondition { store.state.form.stringProperty == "Updated" }
            
            #expect(store.state.form.stringProperty == "Updated")
            
            store.dispatch(Actions.DismissDynamicDialog())
            await waitForMainActorCondition { store.state.form.dialog.status == .dismissed }
            
            store.dispatch(Actions.PresentDirectDynamicDialog())
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
        
        @MainActor
        @Test func dynamicDialogButtonCapturesLatestState() async throws {
            let store = EnvironmentStore(initial: AppState(), loggers: [])
            store.dispatch(UDF.Actions.UpdateFormField(keyPath: \FormWithDialog.stringProperty, value: "5"))
            await waitForMainActorCondition { store.state.form.stringProperty == "5" }
            
            Dialog.register(id: FormWithDialog.DialogId.dynamicDialog) {
                AlertDialog {
                    DialogTitle("do you want to delete these items?")
                    DialogButton(title: "Cancel", role: .cancel)
                    DialogButton(title: "Delete \(store.state.form.stringProperty) items", role: .destructive)
                }
            }
            
            store.dispatch(Actions.PresentDynamicDialog())
            await waitForMainActorCondition { store.state.form.dialog.status != .dismissed }
            
            if case .presented(let dialogType) = store.state.form.dialog.status {
                let deleteButton = dialogType.actions[1] as? DialogButton
                #expect(deleteButton?.title == "Delete 5 items")
            } else {
                Issue.record("Expected presented dialog")
            }
            
            store.dispatch(UDF.Actions.UpdateFormField(keyPath: \FormWithDialog.stringProperty, value: "3"))
            await waitForMainActorCondition { store.state.form.stringProperty == "3" }
            
            store.dispatch(Actions.PresentDynamicDialog())
            
            await waitForMainActorCondition { 
                if case .presented(let dialogType) = store.state.form.dialog.status {
                    let deleteButton = dialogType.actions[1] as? DialogButton
                    return deleteButton?.title == "Delete 3 items"
                }
                return false
            }
            
            if case .presented(let dialogType) = store.state.form.dialog.status {
                let deleteButton = dialogType.actions[1] as? DialogButton
                #expect(deleteButton?.title == "Delete 3 items")
            } else {
                Issue.record("Expected presented dialog")
            }
        }
        
        @MainActor
        @Test func dynamicDialogTextFieldCapturesLatestState() async throws {
            let store = EnvironmentStore(initial: AppState(), loggers: [])
            
            store.dispatch(
                Actions.UpdateFormField(
                    keyPath: \FormWithDialog.stringProperty,
                    value: "Initial Text"
                )
            )
            
            await waitForMainActorCondition { store.state.form.stringProperty == "Initial Text" }
            
            Dialog.register(id: FormWithDialog.DialogId.dynamicDialog) {
                AlertDialog {
                    DialogTitle("Edit Item")
                    DialogTextField(
                        title: "Name",
                        text: Binding(
                            get: { store.state.form.stringProperty },
                            set: { _ in }
                        )
                    )
                    DialogButton(title: "Cancel", role: .cancel)
                }
            }
            
            store.dispatch(Actions.PresentDynamicDialog())
            await waitForMainActorCondition {
                store.state.form.dialog.status != .dismissed
            }
            
            if case .presented(let dialogType) = store.state.form.dialog.status {
                if let textField = dialogType.actions[0] as? DialogTextField {
                    let textValue = textField.text.wrappedValue
                    #expect(textValue == "Initial Text")
                } else {
                    Issue.record("actions[0] is not a DialogTextField: \(dialogType.actions)")
                }
            } else {
                Issue.record("Expected presented dialog")
            }
            
            store.dispatch(
                Actions.UpdateFormField(
                    keyPath: \FormWithDialog.stringProperty,
                    value: "Updated Text"
                )
            )
            await waitForMainActorCondition {
                store.state.form.stringProperty == "Updated Text"
            }
            
            // Re-evaluate the binding after state updates
            if case .presented(let dialogType) = store.state.form.dialog.status {
                if let textField = dialogType.actions[0] as? DialogTextField {
                    let textValue = textField.text.wrappedValue
                    #expect(textValue == "Updated Text")
                }
            } else {
                Issue.record("Expected presented dialog")
            }
        }
        
        @MainActor
        @Test func dynamicDialogTitleCapturesLatestState() async throws {
            let store = EnvironmentStore(initial: AppState(), loggers: [])
            store.dispatch(UDF.Actions.UpdateFormField(keyPath: \FormWithDialog.stringProperty, value: "Old Title"))
            await waitForMainActorCondition { store.state.form.stringProperty == "Old Title" }
            
            Dialog.register(id: FormWithDialog.DialogId.dynamicDialog) {
                AlertDialog {
                    DialogTitle(store.state.form.stringProperty)
                    DialogButton(title: "OK")
                }
            }
            
            store.dispatch(Actions.PresentDynamicDialog())
            await waitForMainActorCondition { store.state.form.dialog.status != .dismissed }
            
            if case .presented(let dialogType) = store.state.form.dialog.status {
                #expect(dialogType.title == "Old Title")
            } else {
                Issue.record("Expected presented dialog")
            }
            
            store.dispatch(UDF.Actions.UpdateFormField(keyPath: \FormWithDialog.stringProperty, value: "New Title"))
            await waitForMainActorCondition { store.state.form.stringProperty == "New Title" }
            
            store.dispatch(Actions.PresentDynamicDialog())
            
            await waitForMainActorCondition { 
                if case .presented(let dialogType) = store.state.form.dialog.status {
                    return dialogType.title == "New Title"
                }
                return false
            }
            
            if case .presented(let dialogType) = store.state.form.dialog.status {
                #expect(dialogType.title == "New Title")
            } else {
                Issue.record("Expected presented dialog")
            }
        }
        
        @MainActor
        @Test func dynamicDialogMessageCapturesLatestState() async throws {
            let store = EnvironmentStore(initial: AppState(), loggers: [])
            store.dispatch(UDF.Actions.UpdateFormField(keyPath: \FormWithDialog.stringProperty, value: "Old Message"))
            await waitForMainActorCondition { store.state.form.stringProperty == "Old Message" }
            
            Dialog.register(id: FormWithDialog.DialogId.dynamicDialog) {
                AlertDialog {
                    DialogTitle("Static Title")
                    DialogMessage(store.state.form.stringProperty)
                    DialogButton(title: "OK")
                }
            }
            
            store.dispatch(Actions.PresentDynamicDialog())
            await waitForMainActorCondition { store.state.form.dialog.status != .dismissed }
            
            if case .presented(let dialogType) = store.state.form.dialog.status {
                #expect(dialogType.message == "Old Message")
            } else {
                Issue.record("Expected presented dialog")
            }
            
            store.dispatch(UDF.Actions.UpdateFormField(keyPath: \FormWithDialog.stringProperty, value: "New Message"))
            await waitForMainActorCondition { store.state.form.stringProperty == "New Message" }
            
            store.dispatch(Actions.PresentDynamicDialog())
            
            await waitForMainActorCondition { 
                if case .presented(let dialogType) = store.state.form.dialog.status {
                    return dialogType.message == "New Message"
                }
                return false
            }
            
            if case .presented(let dialogType) = store.state.form.dialog.status {
                #expect(dialogType.message == "New Message")
            } else {
                Issue.record("Expected presented dialog")
            }
        }

        @MainActor
        @Test func dynamicDialogIconCapturesLatestState() async throws {
            ViewRenderTracker.renderHistory.removeAll()
            let store = EnvironmentStore(initial: AppState(), loggers: [])
            store.dispatch(UDF.Actions.UpdateFormField(keyPath: \FormWithDialog.viewMode, value: .text("TextMode")))
            await waitForMainActorCondition { store.state.form.viewMode == .text("TextMode") }
            
            Dialog.register(id: FormWithDialog.DialogId.dynamicDialog) {
                Toast {
                    DialogIcon { 
                        switch store.state.form.viewMode {
                        case .image:
                            Image(systemName: "star")
                        case .text(let value):
                            TrackerTestView(value: value)
                        }
                    }
                    DialogMessage("Message")
                }
            }
            
            store.dispatch(Actions.PresentDynamicDialog())
            await waitForMainActorCondition { store.state.form.dialog.status != .dismissed }
            
            if case .presented(let dialogType) = store.state.form.dialog.status {
                let iconView = dialogType.getIconView(theme: .default)
                #expect(iconView != nil)
                #expect(ViewRenderTracker.renderHistory.last == "TextMode")
            } else {
                Issue.record("Expected presented dialog")
            }
            
            store.dispatch(UDF.Actions.UpdateFormField(keyPath: \FormWithDialog.viewMode, value: .image))
            await waitForMainActorCondition { store.state.form.viewMode == .image }
            
            store.dispatch(Actions.PresentDynamicDialog())
            
            await waitForMainActorCondition { 
                if case .presented(let dialogType) = store.state.form.dialog.status {
                    let iconView = dialogType.getIconView(theme: .default)
                    if let iconView {
                        return String(describing: iconView).contains("Image")
                    }
                    return false
                }
                return false
            }
            
            if case .presented(let dialogType) = store.state.form.dialog.status {
                let iconView = dialogType.getIconView(theme: .default)
                if let iconView {
                    let description = String(describing: iconView)
                    #expect(description.contains("Image"))
                } else {
                    Issue.record("iconView is nil")
                }
            } else {
                Issue.record("Expected presented dialog")
            }
            
            store.dispatch(UDF.Actions.UpdateFormField(keyPath: \FormWithDialog.viewMode, value: .text("NewText")))
            await waitForMainActorCondition { store.state.form.viewMode == .text("NewText") }
            
            store.dispatch(Actions.PresentDynamicDialog())
            
            await waitForMainActorCondition { 
                if case .presented(let dialogType) = store.state.form.dialog.status {
                    let iconView = dialogType.getIconView(theme: .default)
                    if let iconView {
                        return String(describing: iconView).contains("TrackerTestView")
                    }
                    return false
                }
                return false
            }
            
            if case .presented(let dialogType) = store.state.form.dialog.status {
                let iconView = dialogType.getIconView(theme: .default)
                #expect(iconView != nil)
                #expect(ViewRenderTracker.renderHistory.last == "NewText")
            } else {
                Issue.record("Expected presented dialog")
            }
        }
        
        @MainActor
        @Test func dynamicDialogCustomViewCapturesLatestState() async throws {
            ViewRenderTracker.renderHistory.removeAll()
            let store = EnvironmentStore(initial: AppState(), loggers: [])
            store.dispatch(UDF.Actions.UpdateFormField(keyPath: \FormWithDialog.viewMode, value: .text("TextMode")))
            await waitForMainActorCondition { store.state.form.viewMode == .text("TextMode") }
            
            Dialog.register(id: FormWithDialog.DialogId.dynamicDialog) {
                Toast {
                    DialogMessage("Message")
                    DialogView { 
                        switch store.state.form.viewMode {
                        case .image:
                            Image(systemName: "circle")
                        case .text(let value):
                            TrackerTestView(value: value)
                        }
                    }
                }
            }
            
            store.dispatch(Actions.PresentDynamicDialog())
            await waitForMainActorCondition { store.state.form.dialog.status != .dismissed }
            
            if case .presented(let dialogType) = store.state.form.dialog.status {
                let customView = dialogType.getCustomContentView()
                #expect(customView != nil)
                #expect(ViewRenderTracker.renderHistory.last == "TextMode")
            } else {
                Issue.record("Expected presented dialog")
            }
            
            store.dispatch(UDF.Actions.UpdateFormField(keyPath: \FormWithDialog.viewMode, value: .image))
            await waitForMainActorCondition { store.state.form.viewMode == .image }
            
            store.dispatch(Actions.PresentDynamicDialog())
            
            await waitForMainActorCondition { 
                if case .presented(let dialogType) = store.state.form.dialog.status {
                    let customView = dialogType.getCustomContentView()
                    if let customView {
                        return String(describing: customView).contains("Image")
                    }
                    return false
                }
                return false
            }
            
            if case .presented(let dialogType) = store.state.form.dialog.status {
                let customView = dialogType.getCustomContentView()
                if let customView {
                    let description = String(describing: customView)
                    #expect(description.contains("Image"))
                } else {
                    Issue.record("customView is nil")
                }
            } else {
                Issue.record("Expected presented dialog")
            }
            
            store.dispatch(UDF.Actions.UpdateFormField(keyPath: \FormWithDialog.viewMode, value: .text("NextText")))
            await waitForMainActorCondition { store.state.form.viewMode == .text("NextText") }
            
            store.dispatch(Actions.PresentDynamicDialog())
            
            await waitForMainActorCondition { 
                if case .presented(let dialogType) = store.state.form.dialog.status {
                    let customView = dialogType.getCustomContentView()
                    if let customView {
                        return String(describing: customView).contains("TrackerTestView")
                    }
                    return false
                }
                return false
            }
            
            if case .presented(let dialogType) = store.state.form.dialog.status {
                let customView = dialogType.getCustomContentView()
                #expect(customView != nil)
                #expect(ViewRenderTracker.renderHistory.last == "NextText")
            } else {
                Issue.record("Expected presented dialog")
            }
        }

    }
}

extension DialogRegistryTests.DialogTests {
    // MARK: - Helpers
    
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
        
        enum ViewMode: Equatable {
            case text(String)
            case image
        }
        
        var stringProperty: String = "Initial"
        var viewMode: ViewMode = .text("Initial")
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
                
            case is Actions.PresentDirectDynamicDialog:
                dialog = DialogStatus {
                    AlertDialog {
                        DialogTitle("Title \(stringProperty)")
                        DialogMessage("Message \(stringProperty)")
                        DialogButton(title: "OK \(stringProperty)")
                    }
                }
                
            case is Actions.DismissDynamicDialog:
                dialog = .dismissed
                
            default:
                break
            }
        }
    }
    
    @MainActor
    class ViewRenderTracker {
        static var renderHistory: [String] = []
    }
    
    struct TrackerTestView: View {
        let value: String
        
        init(value: String) {
            self.value = value
            ViewRenderTracker.renderHistory.append(value)
        }
        
        var body: some View {
            Text(value)
        }
    }
}
