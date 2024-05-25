
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

public extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: TimeInterval) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
