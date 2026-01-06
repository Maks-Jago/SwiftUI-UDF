@testable import UDF
import Testing
import SwiftUI

@Suite struct DialogActionsBuilderTests {

    // MARK: - Basic Builder Tests
    @Test func whenVoid_ActionGroupShouldBeEmpty() {
        let content = DialogContent(title: "", message: "") {
            ()
        }

        #expect(content.actions.isEmpty, "A dialog should have no action when there is some Void in the builder")
    }

    @Test
    @MainActor
    func dialogButton() {
        let content = DialogContent(title: "", message: "", actions: {
            DialogButton.cancel("Cancel")
        })

        #expect(content.actions.count == 1)

        // Verify the button properties
        if let button = content.actions.first as? DialogButton {
            #expect(button.title == "Cancel")
            #expect(button.role == .cancel)
            #expect(!button.disabled)
        } else {
            Issue.record("Expected DialogButton")
        }
    }

    @Test
    @MainActor
    func multipleDialogButtons() {
        let content = DialogContent(title: "Test", message: "Multiple buttons", actions: {
            DialogButton.default("OK")
            DialogButton.cancel("Cancel")
            DialogButton.destructive("Delete")
        })

        #expect(content.actions.count == 3)

        let buttons = content.actions.compactMap { $0 as? DialogButton }
        #expect(buttons.count == 3)

        #expect(buttons[0].title == "OK")
        #expect(buttons[0].role == nil)

        #expect(buttons[1].title == "Cancel")
        #expect(buttons[1].role == .cancel)

        #expect(buttons[2].title == "Delete")
        #expect(buttons[2].role == .destructive)
    }

    // MARK: - TextField Tests
    @Test
    @MainActor
    func dialogTextField() {
        @State var testText = ""

        let content = DialogContent("Input Required") {
            DialogTextField(title: "Enter name", text: $testText)
        }

        #expect(content.actions.count == 1)

        if let textField = content.actions.first as? DialogTextField {
            #expect(textField.title == "Enter name")
        } else {
            Issue.record("Expected DialogTextField")
        }
    }

    @Test
    @MainActor
    func mixedButtonsAndTextFields() {
        @State var name = ""
        @State var email = ""

        let content = DialogContent("User Registration") {
            DialogTextField(title: "Name", text: $name)
            DialogTextField(title: "Email", text: $email)
            DialogButton.default("Register")
            DialogButton.cancel("Cancel")
        }

        #expect(content.actions.count == 4)

        let textFields = content.actions.compactMap { $0 as? DialogTextField }
        let buttons = content.actions.compactMap { $0 as? DialogButton }

        #expect(textFields.count == 2)
        #expect(buttons.count == 2)

        #expect(textFields[0].title == "Name")
        #expect(textFields[1].title == "Email")
        #expect(buttons[0].title == "Register")
        #expect(buttons[1].title == "Cancel")
    }

    // MARK: - Conditional Builder Tests
    @Test
    @MainActor
    func conditionalActions() {
        let showCancel = true
        let showDelete = false

        let content = DialogContent("Conditional Actions") {
            DialogButton.default("OK")

            if showCancel {
                DialogButton.cancel("Cancel")
            }

            if showDelete {
                DialogButton.destructive("Delete")
            }
        }

        #expect(content.actions.count == 2) // OK + Cancel

        let buttons = content.actions.compactMap { $0 as? DialogButton }
        #expect(buttons[0].title == "OK")
        #expect(buttons[1].title == "Cancel")
    }

    @Test
    @MainActor
    func conditionalActionsWhenFalse() {
        let showOptionalActions = false

        let content = DialogContent("Basic Action") {
            DialogButton.default("OK")

            if showOptionalActions {
                DialogButton.cancel("Cancel")
                DialogButton.destructive("Delete")
            }
        }

        #expect(content.actions.count == 1)

        if let button = content.actions.first as? DialogButton {
            #expect(button.title == "OK")
        }
    }

    // MARK: - Complex Action Scenarios
    @Test func actionWithCustomAction() {
        var actionExecuted = false

        let content = DialogContent("Action Test") {
            DialogButton(title: "Custom Action") {
                actionExecuted = true
            }
        }

        #expect(content.actions.count == 1)

        if let button = content.actions.first as? DialogButton {
            // Execute the action
            button.action()
            #expect(actionExecuted)
        } else {
            Issue.record("Expected DialogButton")
        }
    }

    @Test
    @MainActor
    func buttonModifiers() {
        let content = DialogContent("Modified Button") {
            DialogButton(title: "Disabled Button")
                .disabled(true)
                .role(.destructive)
        }

        if let button = content.actions.first as? DialogButton {
            #expect(button.disabled)
            #expect(button.role == .destructive)
        } else {
            Issue.record("Expected DialogButton")
        }
    }

    // MARK: - Edge Cases
    @Test func emptyBuilder() {
        let content = DialogContent("Empty actions") {
            // Empty builder should work
        }

        #expect(content.actions.isEmpty)
        #expect(!content.hasActions)
    }

    @Test func actionEquality() {
        let button1 = DialogButton.cancel("Cancel")
        let button2 = DialogButton.cancel("Cancel")

        // Buttons with same properties should be equal
        #expect(button1 == button2)

        let button3 = DialogButton.default("Cancel")
        #expect(button1 != button3) // Different roles
    }
}
