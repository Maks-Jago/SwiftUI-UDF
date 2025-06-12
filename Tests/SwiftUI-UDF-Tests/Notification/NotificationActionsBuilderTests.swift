@testable import UDF
import XCTest
import SwiftUI

final class NotificationActionsBuilderTests: XCTestCase {
    
    // MARK: - Basic Builder Tests
    
    func test_WhenVoid_ActionGroupShouldBeEmpty() {
        let content = NotificationContent("", message: "") {
            ()
        }

        XCTAssertTrue(content.actions.isEmpty, "A notification should have no action when there is some Void in the builder")
    }

    @MainActor
    func test_NotificationButton() {
        let content = NotificationContent("", message: "") {
            NotificationButton.cancel("Cancel")
        }
        
        XCTAssertEqual(content.actions.count, 1)
        
        // Verify the button properties
        if let button = content.actions.first as? NotificationButton {
            XCTAssertEqual(button.title, "Cancel")
            XCTAssertEqual(button.role, .cancel)
            XCTAssertFalse(button.disabled)
        } else {
            XCTFail("Expected NotificationButton")
        }
    }
    
    @MainActor
    func test_MultipleNotificationButtons() {
        let content = NotificationContent("Test", message: "Multiple buttons") {
            NotificationButton.default("OK")
            NotificationButton.cancel("Cancel")
            NotificationButton.destructive("Delete")
        }
        
        XCTAssertEqual(content.actions.count, 3)
        
        let buttons = content.actions.compactMap { $0 as? NotificationButton }
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
    func test_NotificationTextField() {
        @State var testText = ""
        
        let content = NotificationContent("Input Required") {
            NotificationTextField(title: "Enter name", text: $testText)
        }
        
        XCTAssertEqual(content.actions.count, 1)
        
        if let textField = content.actions.first as? NotificationTextField {
            XCTAssertEqual(textField.title, "Enter name")
        } else {
            XCTFail("Expected NotificationTextField")
        }
    }
    
    @MainActor
    func test_MixedButtonsAndTextFields() {
        @State var name = ""
        @State var email = ""
        
        let content = NotificationContent("User Registration") {
            NotificationTextField(title: "Name", text: $name)
            NotificationTextField(title: "Email", text: $email)
            NotificationButton.default("Register")
            NotificationButton.cancel("Cancel")
        }
        
        XCTAssertEqual(content.actions.count, 4)
        
        let textFields = content.actions.compactMap { $0 as? NotificationTextField }
        let buttons = content.actions.compactMap { $0 as? NotificationButton }
        
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
        
        let content = NotificationContent("Conditional Actions") {
            NotificationButton.default("OK")
            
            if showCancel {
                NotificationButton.cancel("Cancel")
            }
            
            if showDelete {
                NotificationButton.destructive("Delete")
            }
        }
        
        XCTAssertEqual(content.actions.count, 2) // OK + Cancel
        
        let buttons = content.actions.compactMap { $0 as? NotificationButton }
        XCTAssertEqual(buttons[0].title, "OK")
        XCTAssertEqual(buttons[1].title, "Cancel")
    }
    
    @MainActor
    func test_ConditionalActionsWhenFalse() {
        let showOptionalActions = false
        
        let content = NotificationContent("Basic Action") {
            NotificationButton.default("OK")
            
            if showOptionalActions {
                NotificationButton.cancel("Cancel")
                NotificationButton.destructive("Delete")
            }
        }
        
        XCTAssertEqual(content.actions.count, 1)
        
        if let button = content.actions.first as? NotificationButton {
            XCTAssertEqual(button.title, "OK")
        }
    }
    
    // MARK: - Complex Action Scenarios
    
    func test_ActionWithCustomAction() {
        var actionExecuted = false
        
        let content = NotificationContent("Action Test") {
            NotificationButton(title: "Custom Action") {
                actionExecuted = true
            }
        }
        
        XCTAssertEqual(content.actions.count, 1)
        
        if let button = content.actions.first as? NotificationButton {
            // Execute the action
            button.action()
            XCTAssertTrue(actionExecuted)
        } else {
            XCTFail("Expected NotificationButton")
        }
    }
    
    @MainActor
    func test_ButtonModifiers() {
        let content = NotificationContent("Modified Button") {
            NotificationButton(title: "Disabled Button")
                .disabled(true)
                .role(.destructive)
        }
        
        if let button = content.actions.first as? NotificationButton {
            XCTAssertTrue(button.disabled)
            XCTAssertEqual(button.role, .destructive)
        } else {
            XCTFail("Expected NotificationButton")
        }
    }
    
    // MARK: - Edge Cases
    
    func test_EmptyBuilder() {
        let content = NotificationContent("Empty actions") {
            // Empty builder should work
        }
        
        XCTAssertTrue(content.actions.isEmpty)
        XCTAssertFalse(content.hasActions)
    }
    
    func test_ActionEquality() {
        let button1 = NotificationButton.cancel("Cancel")
        let button2 = NotificationButton.cancel("Cancel")
        
        // Buttons with same properties should be equal
        XCTAssertEqual(button1, button2)
        
        let button3 = NotificationButton.default("Cancel")
        XCTAssertNotEqual(button1, button3) // Different roles
    }
}
