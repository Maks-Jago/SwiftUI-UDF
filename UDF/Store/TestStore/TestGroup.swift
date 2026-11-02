import Foundation
import os

/// Tracks in-flight dispatched actions for a `TestStore` so tests can wait until all of them,
/// and any effects they trigger, have finished running.
///
/// Each `TestStore` gets its own `TestGroup` instance, keyed by the store's identity. Every call
/// to `enter()` marks the start of an operation; a matching `leave()` marks its completion.
/// `wait(additionalSleepFor:)` blocks until the counts balance out (or a timeout is reached).
public final class TestGroup: @unchecked Sendable {
    private var counters: OSAllocatedUnfairLock<(inCount: Int, outCount: Int)> = .init(initialState: (0, 0))
    private nonisolated(unsafe) static var shared = TestGroup()
    private static let isRunningTests = ProcessInfo.processInfo.isRunningTests

    static func instance(for store: any Store) -> TestGroup {
        guard isRunningTests else {
            return .shared
        }

        let key = "\(ObjectIdentifier(store))"
        return instanceFor(key: key)
    }

    static func instanceFor(key: String) -> TestGroup {
        guard isRunningTests else {
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
        guard isRunningTests else {
            return "ignore"
        }

        return "\(ObjectIdentifier(store))"
    }

    /// Marks the start of an operation, incrementing the pending-operation count that
    /// `wait(additionalSleepFor:)` watches.
    ///
    /// - Parameters:
    ///   - fileName: The name of the file where the operation starts. Defaults to the caller's file.
    ///   - functionName: The name of the function where the operation starts. Defaults to the caller's function.
    ///   - lineNumber: The line number where the operation starts. Defaults to the caller's line.
    public func enter(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if TestGroup.isRunningTests {
            counters.withLock { counters in
                counters.inCount &+= 1
//                print("TestGroup.enter (counters.inCount: \(counters.inCount), counters.outCount: \(counters.outCount)): \(fileName) \(functionName) \(lineNumber)")
            }
        }
    }

    static func enter(
        for store: any Store,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> String {
        guard isRunningTests else {
            return "ignore"
        }

        instance(for: store).enter(fileName: fileName, functionName: functionName, lineNumber: lineNumber)
        return instanceKey(store)
    }

    /// Marks the completion of an operation previously started with `enter(fileName:functionName:lineNumber:)`.
    ///
    /// - Parameters:
    ///   - fileName: The name of the file where the operation completes. Defaults to the caller's file.
    ///   - functionName: The name of the function where the operation completes. Defaults to the caller's function.
    ///   - lineNumber: The line number where the operation completes. Defaults to the caller's line.
    public func leave(
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if TestGroup.isRunningTests {
            counters.withLock { counters in
                counters.outCount &+= 1
//                print("TestGroup.leave (counters.inCount: \(counters.inCount), counters.outCount: \(counters.outCount)): \(fileName) \(functionName) \(lineNumber)")
            }
        }
    }

    /// Blocks the current thread until every entered operation has a matching `leave()` call,
    /// or a 4-second timeout elapses.
    ///
    /// - Parameters:
    ///   - additionalSleepFor: An extra delay, in seconds, to wait after the counts balance out. Defaults to `0`.
    ///   - fileName: The name of the file calling wait. Defaults to the caller's file.
    ///   - functionName: The name of the function calling wait. Defaults to the caller's function.
    ///   - lineNumber: The line number calling wait. Defaults to the caller's line.
    public func wait(
        additionalSleepFor: TimeInterval = 0,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        if TestGroup.isRunningTests {
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
//            let results = counters.withLock { $0 }
//            print("TestGroup.wait (counters.inCount: \(results.inCount), counters.outCount: \(results.outCount)): \(fileName) \(functionName) \(lineNumber)")
        }
    }
}

