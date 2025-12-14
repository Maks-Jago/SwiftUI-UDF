import Foundation
import os

public final class TestGroup {
    nonisolated(unsafe) static var shared = TestGroup()
    private var counters: OSAllocatedUnfairLock<(inCount: Int, outCount: Int)> = .init(initialState: (0, 0))

    public func enter(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if ProcessInfo.processInfo.isRunningTests {
            counters.withLock { counters in
                counters.inCount &+= 1
            }
        }
    }

    public func leave(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if ProcessInfo.processInfo.isRunningTests {
            counters.withLock { counters in
                counters.outCount &+= 1
            }
        }
    }

    public func wait(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if ProcessInfo.processInfo.isRunningTests {
            // Snapshot the number of entered operations at the time of waiting
            let snapshotIn: Int = counters.withLock { $0.inCount }
            let deadline = DispatchTime.now() + .seconds(4)

            while true {
                let currentOut = counters.withLock { $0.outCount }
                if currentOut >= snapshotIn { break }
                if DispatchTime.now() >= deadline { break }
                // Sleep briefly to avoid busy-waiting; this is test-only code
                Thread.sleep(forTimeInterval: 0.001)
            }
        }
    }
}
