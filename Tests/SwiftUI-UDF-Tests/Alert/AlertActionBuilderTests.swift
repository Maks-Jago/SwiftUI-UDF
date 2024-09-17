
import XCTest
@testable import UDF

final class AlertActionBuilderTests: XCTestCase {
    func test_WhenVoid_ActionGroupShouldBeEmpty() {
        let style = AlertBuilder.AlertStyle.init(title: "", text: "") {
            ()
        }

        let alertType = style.type

        switch alertType {
        case .customActions(_, _, let actions):
            XCTAssertTrue(actions().isEmpty, "An Alert should have no action when there is some Void in the builder")

        default:
            XCTFail("Alert type should be custom")
        }
    }

    func test_AlertButton() {
        let style = AlertBuilder.AlertStyle.init(title: "", text: "") {
            AlertButton.cancel("Cancel")
        }

        let alertType = style.type

        switch alertType {
        case .customActions(_, _, let actions):
            XCTAssertEqual(actions().count, 1)

        default:
            XCTFail("Alert type should be custom")
        }
    }
}
