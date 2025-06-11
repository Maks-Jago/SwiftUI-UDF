@testable import UDF
import XCTest

final class NotificationActionsBuilderTests: XCTestCase {
    func test_WhenVoid_ActionGroupShouldBeEmpty() {
        let content = NotificationContent("", message: "") {
            ()
        }

        XCTAssertTrue(content.actions.isEmpty, "A notification should have no action when there is some Void in the builder")
    }

    func test_NotificationButton() {
        let content = NotificationContent("", message: "") {
            NotificationButton.cancel("Cancel")
        }

        XCTAssertEqual(content.actions.count, 1)
    }
}
