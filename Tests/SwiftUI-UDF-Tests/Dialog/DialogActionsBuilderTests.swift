@testable import UDF
import XCTest
import SwiftUI

final class DialogActionsBuilderTests: XCTestCase {
    
    // MARK: - Basic Builder Tests
    
    func test_WhenVoid_ActionGroupShouldBeEmpty() {
        let content = DialogContent("", message: "") {
            ()
        }

        XCTAssertTrue(content.actions.isEmpty, "A dialog should have no action when there is some Void in the builder")
    }

    @MainActor
    func test_DialogButton() {
        let content = DialogContent("", message: "") {
            DialogButton.cancel("Cancel")
        }
        
        XCTAssertEqual(content.actions.count, 1)
        
        // Verify the button properties
        if let button = content.actions.first as? DialogButton {
            XCTAssertEqual(button.title, "Cancel")
            XCTAssertEqual(button.role, .cancel)
            XCTAssertFalse(button.disabled)
        } else {
            XCTFail("Expected DialogButton")
        }
    }
    
    @MainActor
    func test_MultipleDialogButtons() {
        let content = DialogContent("Test", message: "Multiple buttons") {
            DialogButton.default("OK")
            DialogButton.cancel("Cancel")
            DialogButton.destructive("Delete")
        }
        
        XCTAssertEqual(content.actions.count, 3)
        
        let buttons = content.actions.compactMap { $0 as? DialogButton }
        XCTAssertEqual(buttons.count, 3)
        
        XCTAssertEqual(buttons[0].title, "OK")
        XCTAssertNil(buttons[0].role)
        
        XCTAssertEqual(buttons[1].title, "Cancel")
        XCTAssertEqual(buttons[1].role, .cancel)
        
        XCTAssertEqual(buttons[2].title, "Delete")
        XCTAssertEqual(buttons[2].role, .destructive)
    }
    
    // MARK: - TextField Tests
    
    @MainActor
    func test_DialogTextField() {
        @State var testText = ""
        
        let content = DialogContent("Input Required") {
            DialogTextField(title: "Enter name", text: $testText)
        }
        
        XCTAssertEqual(content.actions.count, 1)
        
        if let textField = content.actions.first as? DialogTextField {
            XCTAssertEqual(textField.title, "Enter name")
        } else {
            XCTFail("Expected DialogTextField")
        }
    }
    
    @MainActor
    func test_MixedButtonsAndTextFields() {
        @State var name = ""
        @State var email = ""
        
        let content = DialogContent("User Registration") {
            DialogTextField(title: "Name", text: $name)
            DialogTextField(title: "Email", text: $email)
            DialogButton.default("Register")
            DialogButton.cancel("Cancel")
        }
        
        XCTAssertEqual(content.actions.count, 4)
        
        let textFields = content.actions.compactMap { $0 as? DialogTextField }
        let buttons = content.actions.compactMap { $0 as? DialogButton }
        
        XCTAssertEqual(textFields.count, 2)
        XCTAssertEqual(buttons.count, 2)
        
        XCTAssertEqual(textFields[0].title, "Name")
        XCTAssertEqual(textFields[1].title, "Email")
        XCTAssertEqual(buttons[0].title, "Register")
        XCTAssertEqual(buttons[1].title, "Cancel")
    }
    
    // MARK: - Conditional Builder Tests
    
    @MainActor
    func test_ConditionalActions() {
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
        
        XCTAssertEqual(content.actions.count, 2) // OK + Cancel
        
        let buttons = content.actions.compactMap { $0 as? DialogButton }
        XCTAssertEqual(buttons[0].title, "OK")
        XCTAssertEqual(buttons[1].title, "Cancel")
    }
    
    @MainActor
    func test_ConditionalActionsWhenFalse() {
        let showOptionalActions = false
        
        let content = DialogContent("Basic Action") {
            DialogButton.default("OK")
            
            if showOptionalActions {
                DialogButton.cancel("Cancel")
                DialogButton.destructive("Delete")
            }
        }
        
        XCTAssertEqual(content.actions.count, 1)
        
        if let button = content.actions.first as? DialogButton {
            XCTAssertEqual(button.title, "OK")
        }
    }
    
    // MARK: - Complex Action Scenarios
    
    func test_ActionWithCustomAction() {
        var actionExecuted = false
        
        let content = DialogContent("Action Test") {
            DialogButton(title: "Custom Action") {
                actionExecuted = true
            }
        }
        
        XCTAssertEqual(content.actions.count, 1)
        
        if let button = content.actions.first as? DialogButton {
            // Execute the action
            button.action()
            XCTAssertTrue(actionExecuted)
        } else {
            XCTFail("Expected DialogButton")
        }
    }
    
    @MainActor
    func test_ButtonModifiers() {
        let content = DialogContent("Modified Button") {
            DialogButton(title: "Disabled Button")
                .disabled(true)
                .role(.destructive)
        }
        
        if let button = content.actions.first as? DialogButton {
            XCTAssertTrue(button.disabled)
            XCTAssertEqual(button.role, .destructive)
        } else {
            XCTFail("Expected DialogButton")
        }
    }
    
    // MARK: - Edge Cases
    
    func test_EmptyBuilder() {
        let content = DialogContent("Empty actions") {
            // Empty builder should work
        }
        
        XCTAssertTrue(content.actions.isEmpty)
        XCTAssertFalse(content.hasActions)
    }
    
    func test_ActionEquality() {
        let button1 = DialogButton.cancel("Cancel")
        let button2 = DialogButton.cancel("Cancel")
        
        // Buttons with same properties should be equal
        XCTAssertEqual(button1, button2)
        
        let button3 = DialogButton.default("Cancel")
        XCTAssertNotEqual(button1, button3) // Different roles
    }
}
