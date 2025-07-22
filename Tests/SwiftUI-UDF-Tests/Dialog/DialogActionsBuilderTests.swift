@testable import UDF
import Testing
import SwiftUI

@Suite struct DialogActionsBuilderTests {
    
    // MARK: - Basic Builder Tests
    @Test func WhenVoid_ActionGroupShouldBeEmpty() {
        let content = DialogContent(title: "", message: "") {
            ()
        }

        #expect(content.actions.isEmpty, "A dialog should have no action when there is some Void in the builder")
    }

    @Test
    @MainActor
    func DialogButton() {
        let content = DialogContent(title: "", message: "", actions: {
            UDF.DialogButton.cancel("Cancel")
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
    func MultipleDialogButtons() {
        let content = DialogContent(title: "Test", message: "Multiple buttons", actions: {
            UDF.DialogButton.default("OK")
            UDF.DialogButton.cancel("Cancel")
            UDF.DialogButton.destructive("Delete")
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
    func DialogTextField() {
        @State var testText = ""
        
        let content = DialogContent("Input Required") {
            UDF.DialogTextField(title: "Enter name", text: $testText)
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
    func MixedButtonsAndTextFields() {
        @State var name = ""
        @State var email = ""
        
        let content = DialogContent("User Registration") {
            UDF.DialogTextField(title: "Name", text: $name)
            UDF.DialogTextField(title: "Email", text: $email)
            UDF.DialogButton.default("Register")
            UDF.DialogButton.cancel("Cancel")
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
    func ConditionalActions() {
        let showCancel = true
        let showDelete = false
        
        let content = DialogContent("Conditional Actions") {
            UDF.DialogButton.default("OK")
            
            if showCancel {
                UDF.DialogButton.cancel("Cancel")
            }
            
            if showDelete {
                UDF.DialogButton.destructive("Delete")
            }
        }
        
        #expect(content.actions.count == 2) // OK + Cancel
        
        let buttons = content.actions.compactMap { $0 as? DialogButton }
        #expect(buttons[0].title == "OK")
        #expect(buttons[1].title == "Cancel")
    }
    
    @Test
    @MainActor
    func ConditionalActionsWhenFalse() {
        let showOptionalActions = false
        
        let content = DialogContent("Basic Action") {
            UDF.DialogButton.default("OK")
            
            if showOptionalActions {
                UDF.DialogButton.cancel("Cancel")
                UDF.DialogButton.destructive("Delete")
            }
        }
        
        #expect(content.actions.count == 1)
        
        if let button = content.actions.first as? DialogButton {
            #expect(button.title == "OK")
        }
    }
    
    // MARK: - Complex Action Scenarios
    @Test func ActionWithCustomAction() {
        var actionExecuted = false
        
        let content = DialogContent("Action Test") {
            UDF.DialogButton(title: "Custom Action") {
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
    func ButtonModifiers() {
        let content = DialogContent("Modified Button") {
            UDF.DialogButton(title: "Disabled Button")
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
    @Test func EmptyBuilder() {
        let content = DialogContent("Empty actions") {
            // Empty builder should work
        }
        
        #expect(content.actions.isEmpty)
        #expect(!content.hasActions)
    }
    
    @Test func ActionEquality() {
        let button1 = UDF.DialogButton.cancel("Cancel")
        let button2 = UDF.DialogButton.cancel("Cancel")
        
        // Buttons with same properties should be equal
        #expect(button1 == button2)
        
        let button3 = UDF.DialogButton.default("Cancel")
        #expect(button1 != button3) // Different roles
    }
}
