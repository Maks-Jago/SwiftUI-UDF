
import Foundation
import os

public final class XCTestGroup {
    nonisolated(unsafe) static var shared = XCTestGroup()
    private var group: OSAllocatedUnfairLock<DispatchGroup> = .init(initialState: DispatchGroup())

    public func enter(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if ProcessInfo.processInfo.xcTest {
            group.withLock { group in
                group.enter()
            }
        }
    }

    public func leave(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if ProcessInfo.processInfo.xcTest {
            group.withLock { group in
                group.leave()
            }
        }
    }

    public func wait(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if ProcessInfo.processInfo.xcTest {
            _ = group.withLock { $0 }.wait(timeout: .now() + 4)
        }
    }
}
