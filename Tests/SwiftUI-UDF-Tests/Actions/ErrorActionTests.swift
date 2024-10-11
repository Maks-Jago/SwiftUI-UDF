@testable import UDF
import XCTest

final class ErrorActionTests: XCTestCase {
    func test_WhenErrorHasCustomCode_ErrorCodeEqualCustomCode() {
        let error = Actions.Error(error: "Some error", id: "flow_id", code: 101)
        XCTAssertEqual(error.code, 101)
        XCTAssertEqual(error.error, error.errorDescription)
    }

    func test_WhenErrorDoesntHaveCustomCode_ErrorCodeShouldBeGeneratedFromHashCode() {
        let errorMessage = "Some error"
        let error = Actions.Error(error: errorMessage, id: "flow_id")
        XCTAssertEqual(error.code, errorMessage.hashValue)

        let errorMessage2 = "Some error 2"
        let error2 = Actions.Error(error: errorMessage2, id: "flow_id")
        XCTAssertEqual(error2.code, errorMessage2.hashValue)
        XCTAssertNotEqual(error.code, error2.code)
    }
}
