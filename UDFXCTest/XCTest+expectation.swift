
import UDF
import XCTest

public extension XCTestCase {
    func fulfill(description: String, sleep: TimeInterval) async {
        let exp = expectation(description: description)

        Task {
            try await Task.sleep(seconds: sleep)
            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: sleep + 1)
    }
}
