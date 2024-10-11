
@testable import UDF
import XCTest

final class AlertActionBuilderTests: XCTestCase {
    func test_WhenVoid_ActionGroupShouldBeEmpty() {
        let style = AlertBuilder.AlertStyle(title: "", text: "") {
            ()
        }

        let alertType = style.type

        switch alertType {
        case let .customActions(_, _, actions):
            XCTAssertTrue(actions().isEmpty, "An Alert should have no action when there is some Void in the builder")

        default:
            XCTFail("Alert type should be custom")
        }
    }

    func test_AlertButton() {
        let style = AlertBuilder.AlertStyle(title: "", text: "") {
            AlertButton.cancel("Cancel")
        }

        let alertType = style.type

        switch alertType {
        case let .customActions(_, _, actions):
            XCTAssertEqual(actions().count, 1)

        default:
            XCTFail("Alert type should be custom")
        }
    }
}
