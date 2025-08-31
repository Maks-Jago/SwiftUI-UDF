
@testable import UDF
import Testing

@Suite struct AlertActionBuilderTests {
    @Test func whenVoid_ActionGroupShouldBeEmpty() {
        let style = AlertBuilder.AlertStyle(title: "", text: "") {
            ()
        }
        
        let alertType = style.type
        
        switch alertType {
        case let .customActions(_, _, actions):
            #expect(actions().isEmpty, "An Alert should have no action when there is some Void in the builder")
            
        default:
            Issue.record("Alert type should be custom")
        }
    }
    
    @Test func alertButton() {
        let style = AlertBuilder.AlertStyle(title: "", text: "") {
            AlertButton.cancel("Cancel")
        }
        
        let alertType = style.type
        
        switch alertType {
        case let .customActions(_, _, actions):
            #expect(actions().count == 1)
            
        default:
            Issue.record("Alert type should be custom")
        }
    }
}
