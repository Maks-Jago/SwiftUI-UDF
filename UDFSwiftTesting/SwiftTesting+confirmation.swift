
import Testing
import Foundation

public func fulfill(description: Comment, sleep: TimeInterval) async {
    _ = await confirmation(description, expectedCount: 1) { renderCompleted in
        Task {
            let nanoseconds = UInt64(sleep * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            renderCompleted()
        }
    }
}
