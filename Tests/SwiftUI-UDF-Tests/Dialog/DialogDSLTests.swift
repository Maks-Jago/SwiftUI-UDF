//===--- DialogDSLTests.swift ----------------------------------------------===//
//
// This source file is part of the UDF open source project
//
// Copyright (c) 2026 You are launched
// Licensed under Apache License v2.0
//
// See https://opensource.org/licenses/Apache-2.0 for license information
//
//===----------------------------------------------------------------------===//

import SwiftUI
@testable import UDF
import Testing

// MARK: - DSL Tests
@MainActor
extension DialogTests {

    @Test("AlertDialog builder creates correct payload and applies properties")
    func alertBuilderAppliesPropertiesCorrectly() {
        let alert = AlertDialog {
            DialogTitle("My AlertDialog Title")
            DialogMessage("An error occurred during the process.")
            DialogButton(title: "Retry", action: {})
            DialogButton(title: "Cancel", role: .cancel, action: {})
        }

        #expect(alert.title == "My AlertDialog Title")
        #expect(alert.message == "An error occurred during the process.")
        #expect(alert.actions.count == 2)
        
        if case .alert = alert.style {
            #expect(true, "Correctly resolved as alert style")
        } else {
            Issue.record("Expected alert style")
        }
        
        if let retryAction = alert.actions.first as? DialogButton {
            #expect(retryAction.title == "Retry")
        } else {
            Issue.record("Expected DialogButton as first action")
        }
    }

    @Test("Multiple instances of the same component type resolve to the last one")
    func componentOverwriteResolvesToLatest() {
        let alert = AlertDialog {
            DialogTitle("First Title")
            DialogMessage("First Message")
            
            DialogTitle("Second Title")
            DialogMessage("Second Message")
            
            DialogButton(title: "OK", action: {})
        }

        #expect(alert.title == "Second Title", "The last provided title should override previous ones")
        #expect(alert.message == "Second Message", "The last provided message should override previous ones")
        #expect(alert.actions.count == 1, "There should be only one action defined")
    }

    @Test("All supplied buttons are preserved correctly")
    func multipleActionsAreAppendedCorrectly() {
        let alert = AlertDialog {
            DialogButton(title: "Button 1", action: {})
            DialogButton(title: "Button 2", action: {})
            DialogButton(title: "Button 3", action: {})
        }
        
        #expect(alert.actions.count == 3)
        if alert.actions.count == 3 {
            #expect((alert.actions[0] as? DialogButton)?.title == "Button 1")
            #expect((alert.actions[1] as? DialogButton)?.title == "Button 2")
            #expect((alert.actions[2] as? DialogButton)?.title == "Button 3")
        }
    }

    @Test("Optional components are handled appropriately")
    func optionalComponentsHandling() {
        let includeMessage = false
        let includeCancelButton = true
        
        let alert = AlertDialog {
            DialogTitle("Optional Test")
            if includeMessage {
                DialogMessage("This should not be included")
            }
            if includeCancelButton {
                DialogButton(title: "Cancel", action: {})
            }
        }
        
        #expect(alert.title == "Optional Test")
        #expect(alert.message == nil, "Message should be nil since the condition is false")
        #expect(alert.actions.count == 1, "Cancel button should be included")
        if let button = alert.actions.first as? DialogButton {
            #expect(button.title == "Cancel")
        }
    }

    @Test("Toast builder handles configuration, custom icons, and custom views correctly")
    func toastBuilderAppliesPropertiesCorrectly() {
        let config = ToastConfiguration(
            theme: .vibrant,
            position: .center,
            defaultDuration: 5.0
        )
        let toast = Toast(config: config) {
            DialogMessage("Toast success")
            DialogIcon { Image(systemName: "star.fill") }
            DialogView {
                Text("Custom embedded content")
            }
            DialogButton(title: "Undo", action: {})
        }

        #expect(toast.message == "Toast success")
        #expect(toast.actions.count == 1)
        
        if case .toast(let resolvedConfig) = toast.style {
            #expect(resolvedConfig.position == .center)
            #expect(resolvedConfig.theme == .vibrant)
            #expect(resolvedConfig.defaultDuration == 5.0)
        } else {
            Issue.record("Expected toast style configuration")
        }
        
        let iconView = toast.getIconView(theme: ToastTheme.vibrant)
        #expect(iconView != nil, "An icon view should have been successfully packaged.")
        
        let customContent = toast.getCustomContentView()
        #expect(customContent != nil, "A custom content view should have been successfully packaged.")
    }

    @Test("ConfirmationDialog builder handles payload correctly")
    func confirmationDialogBuilderAppliesPropertiesCorrectly() {
        let config = ConfirmationDialogConfiguration()
        let confirmation = ConfirmationDialog(config: config) {
            DialogTitle("Erase all content?")
            DialogMessage("This operation cannot be reversed.")
            DialogButton(title: "Erase", role: .destructive, action: {})
            DialogButton(title: "Go Back", role: .cancel, action: {})
        }

        #expect(confirmation.title == "Erase all content?")
        #expect(confirmation.message == "This operation cannot be reversed.")
        #expect(confirmation.actions.count == 2)
        
        if case .confirmationDialog = confirmation.style {
            #expect(true, "Style correctly resolved to confirmationDialog")
        } else {
            Issue.record("Expected confirmationDialog style")
        }
    }

    @Test("DialogRegistration works dynamically with the new DSL")
    func dynamicDialogRegistrationUsesDSL() {
        let id = 123
        
        Dialog.register(id: id) {
            AlertDialog {
                DialogTitle("Dynamic Registry AlertDialog")
                DialogButton(title: "Dismiss", action: {})
            }
        }
        
        let retrieved = _DialogRegistry.get(id: id)
        #expect(retrieved != nil)
        #expect(retrieved?.title == "Dynamic Registry AlertDialog")
        #expect(retrieved?.actions.count == 1)
        
        if let dialog = retrieved {
            if case .alert = dialog.style {
                #expect(true)
            } else {
                Issue.record("Expected matched retrieved style alert")
            }
        }
    }

    @Test("Empty builder produces a valid but empty payload")
    func emptyBuilderProducesEmptyPayload() {
        let alert = AlertDialog { }
        
        #expect(alert.title == "")
        #expect(alert.message == nil)
        #expect(alert.actions.isEmpty)
        
        if case .alert = alert.style {
            #expect(true)
        } else {
            Issue.record("Expected alert style")
        }
    }
    
    @Test(
        "If/Else control flow correctly executes buildEither",
        arguments: [true, false]
    )
    func ifElseControlFlowBuildEither(isError: Bool) {
        let errorTitle = "Error Occurred"
        let errorMessage = "Something broke."
        
        let successTitle = "Success"
        let successMessage = "Everything is fine."
        
        let alert = AlertDialog {
            if isError {
                DialogTitle(errorTitle)
                DialogMessage(errorMessage)
            } else {
                DialogTitle(successTitle)
                DialogMessage(successMessage)
            }
            DialogButton(title: "Acknowledge", action: {})
        }
        
        #expect(alert.title == (isError ? errorTitle : successTitle))
        #expect(alert.message == (isError ? errorMessage : successMessage))
        #expect(alert.actions.count == 1)
    }
    
    @Test("For-loops correctly execute buildArray and unpack dynamically created components")
    func forLoopBuildArray() {
        let dynamicButtons = ["Option 1", "Option 2", "Option 3"]
        
        let alert = AlertDialog {
            DialogTitle("Choose an Option")
            for buttonTitle in dynamicButtons {
                DialogButton(title: buttonTitle, action: {})
            }
            DialogButton(title: "Cancel", role: .cancel, action: {})
        }
        
        #expect(alert.title == "Choose an Option")
        #expect(alert.actions.count == 4)
        
        for (index, title) in dynamicButtons.enumerated() {
            #expect((alert.actions[index] as? DialogButton)?.title == title)
        }

        #expect((alert.actions[3] as? DialogButton)?.title == "Cancel")
    }

    @Test("DialogTextField is supported as a valid action in the DSL component builder")
    func dialogTextFieldSupport() throws {
        let textBinding = Binding.constant("")
        
        let alert = AlertDialog {
            DialogTitle("Enter Details")
            DialogTextField(title: "Username", text: textBinding)
            DialogButton(title: "Submit", action: {})
        }
        
        #expect(alert.actions.count == 2)
        
        let firstAction = alert.actions.first
        #expect(firstAction is DialogTextField)
        
        let textField = try #require(firstAction as? DialogTextField)
        #expect(textField.title == "Username")
    }
    
    // MARK: - Dialog Protocol Conformance
    @Test("Dialog category is always .custom for DSL types")
    func dialogCategoryIsAlwaysCustom() {
        let alert = AlertDialog {
            DialogTitle("Title")
        }
        let toast = Toast {
            DialogMessage("msg")
        }
        let confirmation = ConfirmationDialog {
            DialogTitle("Title")
        }
        
        #expect(alert.category == .custom)
        #expect(toast.category == .custom)
        #expect(confirmation.category == .custom)
    }
    
    @Test("AlertDialog without icon or custom view returns nil for view accessors")
    func alertReturnsNilForIconAndCustomContent() {
        let alert = AlertDialog {
            DialogTitle("Plain AlertDialog")
            DialogMessage("No icon here")
        }
        
        #expect(alert.getIconView(theme: ToastTheme.vibrant) == nil)
        #expect(alert.getCustomContentView() == nil)
    }
    
    @Test("Two identical alerts are equal, two different alerts are not")
    func dialogEquatableConformance() {
        let alert1 = AlertDialog {
            DialogTitle("Same")
            DialogMessage("Message")
            DialogButton(title: "OK", action: {})
        }
        let alert2 = AlertDialog {
            DialogTitle("Same")
            DialogMessage("Message")
            DialogButton(title: "OK", action: {})
        }
        let alert3 = AlertDialog {
            DialogTitle("Different")
        }
        
        #expect(alert1 == alert2)
        #expect(alert1 != alert3)
    }
    
    @Test("Equal alerts produce the same hash, different alerts produce different hashes")
    func dialogHashableConformance() {
        let alert1 = AlertDialog {
            DialogTitle("Title")
            DialogMessage("Msg")
        }
        let alert2 = AlertDialog {
            DialogTitle("Title")
            DialogMessage("Msg")
        }
        let alert3 = AlertDialog {
            DialogTitle("Other")
        }
        
        #expect(alert1.hashValue == alert2.hashValue)
        #expect(alert1.hashValue != alert3.hashValue)
    }
    
    @Test("IsEquatable correctly compares same and different Dialog types")
    func dialogIsEquatableConformance() {
        let alert = AlertDialog {
            DialogTitle("Title")
        }
        let sameAlertDialog = AlertDialog {
            DialogTitle("Title")
        }
        let toast = Toast {
            DialogMessage("msg")
        }
        
        #expect(alert.isEqual(sameAlertDialog))
        #expect(!alert.isEqual(toast))
    }
    
    // MARK: - DialogStatus Integration
    
    @Test("DSL AlertDialog can be stored and retrieved via DialogStatus using the registry")
    func dialogStatusIntegrationWithDSLAlertDialog() {
        let id = 999
        
        Dialog.register(id: id) {
            AlertDialog {
                DialogTitle("Status AlertDialog")
                DialogMessage("Integration test")
                DialogButton(title: "Got It", action: {})
            }
        }

        let status = DialogStatus(id: id)

        guard case .presented(let dialog) = status.status else {
            Issue.record("Expected presented dialog")
            return
        }

        #expect(dialog.title == "Status AlertDialog")
        #expect(dialog.message == "Integration test")
        #expect(dialog.actions.count == 1)

        guard case .alert = dialog.style else {
            Issue.record("Expected alert style")
            return
        }
    }
    
    @Test("DSL Toast can be stored and retrieved via DialogStatus using the registry")
    func dialogStatusIntegrationWithDSLToast() {
        let id = 998
        
        Dialog.register(id: id) {
            Toast(config: .init(theme: .vibrant, position: .bottom)) {
                DialogMessage("Saved!")
                DialogIcon { Image(systemName: "checkmark") }
            }
        }
        
        let status = DialogStatus(id: id)

        guard case .presented(let dialog) = status.status else {
            Issue.record("Expected presented dialog")
            return
        }

        #expect(dialog.message == "Saved!")

        guard case .toast(let config) = dialog.style else {
            Issue.record("Expected toast style")
            return
        }

        #expect(config.theme == .vibrant)
        #expect(config.position == .bottom)
    }
    
    @Test("Registering the same ID twice overwrites the previous dialog")
    func registryOverwritesBehavior() {
        let id = 777
        
        Dialog.register(id: id) {
            AlertDialog {
                DialogTitle("First")
            }
        }
        
        #expect(_DialogRegistry.get(id: id)?.title == "First")
        
        Dialog.register(id: id) {
            AlertDialog {
                DialogTitle("Second")
            }
        }
        
        #expect(_DialogRegistry.get(id: id)?.title == "Second")
    }
    
    // MARK: - Direct DialogStatus(dialog:) Init
    
    @Test("DialogStatus can be created directly from an AlertDialog using the closure-based init")
    func dialogStatusDirectInitWithAlertDialog() {
        let status = DialogStatus {
            AlertDialog {
                DialogTitle("Direct Alert")
                DialogMessage("Created without registry")
                DialogButton(title: "OK", action: {})
            }
        }
        
        guard case .presented(let dialog) = status.status else {
            Issue.record("Expected presented dialog")
            return
        }
        
        #expect(dialog.title == "Direct Alert")
        #expect(dialog.message == "Created without registry")
        #expect(dialog.actions.count == 1)
        
        guard case .alert = dialog.style else {
            Issue.record("Expected alert style")
            return
        }
    }
    
    @Test("DialogStatus can be created directly from a Toast using the closure-based init")
    func dialogStatusDirectInitWithToast() {
        let status = DialogStatus {
            Toast(config: .init(theme: .vibrant, position: .bottom)) {
                DialogMessage("Direct Toast")
                DialogIcon { Image(systemName: "checkmark") }
            }
        }
        
        guard case .presented(let dialog) = status.status else {
            Issue.record("Expected presented dialog")
            return
        }
        
        #expect(dialog.message == "Direct Toast")
        
        guard case .toast(let config) = dialog.style else {
            Issue.record("Expected toast style")
            return
        }
        
        #expect(config.theme == .vibrant)
        #expect(config.position == .bottom)
    }
    
    @Test("DialogStatus can be created directly from a ConfirmationDialog using the closure-based init")
    func dialogStatusDirectInitWithConfirmationDialog() {
        let status = DialogStatus {
            ConfirmationDialog {
                DialogTitle("Direct Confirmation")
                DialogMessage("Are you sure?")
                DialogButton(title: "Yes", role: .destructive, action: {})
                DialogButton(title: "No", role: .cancel, action: {})
            }
        }
        
        guard case .presented(let dialog) = status.status else {
            Issue.record("Expected presented dialog")
            return
        }
        
        #expect(dialog.title == "Direct Confirmation")
        #expect(dialog.message == "Are you sure?")
        #expect(dialog.actions.count == 2)
        
        guard case .confirmationDialog = dialog.style else {
            Issue.record("Expected confirmationDialog style")
            return
        }
    }
    
    @Test("UpdateDialogStatus can be initialized with a pre-built DialogProtocol instance")
    func updateDialogStatusWithDialogProtocol() {
        let alert = AlertDialog {
            DialogTitle("Action Alert")
            DialogMessage("From UpdateDialogStatus")
            DialogButton(title: "Dismiss", action: {})
        }
        
        let action = Actions.UpdateDialogStatus(dialog: alert, id: "testAction")
        
        guard case .presented(let dialog) = action.status.status else {
            Issue.record("Expected presented dialog")
            return
        }
        
        #expect(dialog.title == "Action Alert")
        #expect(dialog.message == "From UpdateDialogStatus")
        #expect(dialog.actions.count == 1)
        #expect(action.id == AnyHashable("testAction"))
    }
}
