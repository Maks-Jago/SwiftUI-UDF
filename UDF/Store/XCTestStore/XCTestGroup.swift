
import Foundation
import os

public final class XCTestGroup {
    static var shared = XCTestGroup()
    #if os(iOS)
        private var group: OSAllocatedUnfairLock<DispatchGroup> = .init(initialState: DispatchGroup())
    #endif

    public func enter(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if ProcessInfo.processInfo.xcTest {
            #if os(iOS)
                group.withLock { group in
                    group.enter()
                }
            #endif
        }
    }

    public func leave(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if ProcessInfo.processInfo.xcTest {
            #if os(iOS)
                group.withLock { group in
                    group.leave()
                }
            #endif
        }
    }

    public func wait(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if ProcessInfo.processInfo.xcTest {
            #if os(iOS)
                _ = group.withLock { $0 }.wait(timeout: .now() + 4)
            #endif
        }
    }
}
