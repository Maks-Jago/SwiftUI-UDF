
import UDF
import XCTest

public extension XCTestCase {
    func expectation(description: String, sleep: TimeInterval) async {
        let exp = expectation(description: description)

        Task {
            try await Task.sleep(seconds: sleep)
            exp.fulfill()
        }

        await waitForExpectations(timeout: sleep + 1)
    }
}