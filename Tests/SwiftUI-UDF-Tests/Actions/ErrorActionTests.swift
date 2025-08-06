@testable import UDF
import Testing

@Suite struct ErrorActionTests {
    @Test func whenErrorHasCustomCode_ErrorCodeEqualCustomCode() {
        let error = Actions.Error(error: "Some error", id: "flow_id", code: 101)
        #expect(error.code == 101)
        #expect(error.error == error.errorDescription)
    }

    @Test func whenErrorDoesntHaveCustomCode_ErrorCodeShouldBeGeneratedFromHashCode() {
        let errorMessage = "Some error"
        let error = Actions.Error(error: errorMessage, id: "flow_id")
        #expect(error.code == errorMessage.hashValue)

        let errorMessage2 = "Some error 2"
        let error2 = Actions.Error(error: errorMessage2, id: "flow_id")
        #expect(error2.code == errorMessage2.hashValue)
        #expect(error.code != error2.code)
    }
}
