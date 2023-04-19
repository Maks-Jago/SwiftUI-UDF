
import XCTest

extension XCTestCase {
    func expectation(description: String, sleep: TimeInterval) async {
        let exp = expectation(description: description)

        Task {
            try await Task.sleep(seconds: sleep)
            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: sleep + 1)
    }
}
