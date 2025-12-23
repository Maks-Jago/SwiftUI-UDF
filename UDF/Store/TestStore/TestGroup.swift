import Foundation
import os

public final class TestGroup: @unchecked Sendable {
    private var counters: OSAllocatedUnfairLock<(inCount: Int, outCount: Int)> = .init(initialState: (0, 0))
    private nonisolated(unsafe) static var shared = TestGroup()

    static func instance(for store: any Store) -> TestGroup {
        if !ProcessInfo.processInfo.isRunningTests {
            return .shared
        }

        let key = "\(ObjectIdentifier(store))"
        return instanceFor(key: key)
    }

    static func instanceFor(key: String) -> TestGroup {
        if !ProcessInfo.processInfo.isRunningTests {
            return .shared
        }

        let existing: TestGroup? = GlobalValue.optionalValue(forKey: key)
        if let group = existing {
            return group
        }
        let newGroup = TestGroup()
        GlobalValue.set(value: newGroup, for: key)
        return newGroup
    }

    static func instanceKey(_ store: any Store) -> String {
        "\(ObjectIdentifier(store))"
    }

    public func enter(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if ProcessInfo.processInfo.isRunningTests {
            counters.withLock { counters in
                counters.inCount &+= 1
                print("TestGroup.enter (counters.inCount: \(counters.inCount), counters.outCount: \(counters.outCount)): \(fileName) \(functionName) \(lineNumber)")
            }
        }
    }

    static func enter(
        for store: any Store,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> String {
        instance(for: store).enter(fileName: fileName, functionName: functionName, lineNumber: lineNumber)
        return instanceKey(store)
    }

    public func leave(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if ProcessInfo.processInfo.isRunningTests {
            counters.withLock { counters in
                counters.outCount &+= 1
                print("TestGroup.leave (counters.inCount: \(counters.inCount), counters.outCount: \(counters.outCount)): \(fileName) \(functionName) \(lineNumber)")
            }
        }
    }

    public func wait(
        additionalSleepFor: TimeInterval = 0,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if ProcessInfo.processInfo.isRunningTests {
            // Snapshot the number of entered operations at the time of waiting
            let deadline = DispatchTime.now() + .seconds(4)

            while true {
                let snapshotIn: Int = counters.withLock { $0.inCount }
                let currentOut = counters.withLock { $0.outCount }

                if currentOut >= snapshotIn { break }
                if DispatchTime.now() >= deadline { break }
                // Sleep briefly to avoid busy-waiting; this is test-only code
                Thread.sleep(forTimeInterval: 0.001)
            }
            if additionalSleepFor > 0 {
                Thread.sleep(forTimeInterval: additionalSleepFor)
            }
            //tmp
            let results = counters.withLock { $0 }
            print("TestGroup.wait (counters.inCount: \(results.inCount), counters.outCount: \(results.outCount)): \(fileName) \(functionName) \(lineNumber)")
        }
    }
}

