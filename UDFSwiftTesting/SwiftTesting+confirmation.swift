
import Testing
import Foundation

public func sleep(_ seconds: TimeInterval = 0.3) async {
    let nanoseconds = UInt64(seconds * 1_000_000_000)
    try? await Task.sleep(nanoseconds: nanoseconds)
}

/// Waits for a sync condition to become true with timeout (general purpose)
/// - Returns: true if condition was met, false if timeout occurred
public func waitForCondition(timeout: TimeInterval = 5, condition: @escaping () -> Bool) async -> Bool {
    let startTime = CFAbsoluteTimeGetCurrent()

    while !condition() {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        if elapsed >= timeout {
            return false
        }

        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
    }
    
    return true
}

/// Waits for an async condition to become true with timeout (supports cross-actor access)
/// - Returns: true if condition was met, false if timeout occurred
public func waitForAsyncCondition(timeout: TimeInterval = 5, condition: @escaping () async -> Bool) async -> Bool {
    let startTime = CFAbsoluteTimeGetCurrent()

    while !(await condition()) {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        if elapsed >= timeout {
            return false
        }

        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
    }
    
    return true
}

/// Waits for a MainActor condition to become true with timeout (UI/MainActor isolated)
/// - Returns: true if condition was met, false if timeout occurred
@MainActor
public func waitForMainActorCondition(timeout: TimeInterval = 5, condition: @escaping () -> Bool) async -> Bool {
    let startTime = CFAbsoluteTimeGetCurrent()

    while !condition() {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        if elapsed >= timeout {
            return false
        }

        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
    }
    
    return true
}

/// Waits for a throwing condition to become true with timeout (supports #require)
/// - Returns: true if condition was met, false if timeout occurred
public func waitForThrowingCondition(timeout: TimeInterval = 5, condition: @escaping () throws -> Bool) async -> Bool {
    let startTime = CFAbsoluteTimeGetCurrent()

    while true {
        do {
            if try condition() {
                return true
            }
        } catch {
            // Continue waiting if condition throws
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        if elapsed >= timeout {
            return false
        }

        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
    }
}
