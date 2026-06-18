
import Testing
import Foundation
import Combine

public func sleep(for seconds: TimeInterval = 0.3) async {
    let nanoseconds = UInt64(seconds * 1_000_000_000)
    try? await Task.sleep(nanoseconds: nanoseconds)
}

/// Core timeout polling implementation used by all waitForCondition variants.
///
/// This function provides the shared timeout and polling logic, continuously checking
/// a condition until it succeeds or the timeout is reached.
///
/// - Parameters:
///   - timeout: Maximum time to wait for the condition (in seconds).
///   - pollInterval: Time between condition checks (in nanoseconds).
///   - conditionCheck: The condition to evaluate, returning a result when successful or nil to continue polling.
/// - Returns: The result from conditionCheck if successful, nil if timeout occurs.
private func waitForConditionCore<T>(
    timeout: TimeInterval,
    conditionCheck: () async throws -> T?
) async -> T? {
    let startTime = CFAbsoluteTimeGetCurrent()

    while true {
        do {
            if let result = try await conditionCheck() {
                return result
            }
        } catch {
            // Continue waiting if condition throws
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        if elapsed >= timeout {
            return nil
        }

        try? await Task.sleep(nanoseconds: 10_000_000)
    }
}

/// Waits for a synchronous condition to become true within the specified timeout.
///
/// - Parameters:
///   - timeout: Maximum time to wait (defaults to 5 seconds).
///   - condition: The condition to check repeatedly.
/// - Returns: `true` if condition was met, `false` if timeout occurred.
@discardableResult
public func waitForCondition(
    timeout: TimeInterval = 5,
    condition: @escaping () -> Bool
) async -> Bool {
    await waitForConditionCore(timeout: timeout) {
        condition() ? true : nil
    } != nil
}

/// Waits for an asynchronous condition to become true within the specified timeout.
///
/// - Parameters:
///   - timeout: Maximum time to wait (defaults to 5 seconds).
///   - condition: The async condition to check repeatedly.
/// - Returns: `true` if condition was met, `false` if timeout occurred.
@discardableResult
public func waitForCondition(
    timeout: TimeInterval = 5,
    condition: @escaping () async -> Bool
) async -> Bool {
    await waitForConditionCore(timeout: timeout) {
        await condition() ? true : nil
    } != nil
}

/// Waits for a throwing asynchronous condition to become true within the specified timeout.
///
/// Errors thrown by the condition are caught and polling continues until timeout.
///
/// - Parameters:
///   - timeout: Maximum time to wait (defaults to 5 seconds).
///   - condition: The throwing async condition to check repeatedly.
/// - Returns: `true` if condition was met, `false` if timeout occurred.
public func waitForCondition(
    timeout: TimeInterval = 5,
    condition: @escaping () async throws -> Bool
) async -> Bool {
    await waitForConditionCore(timeout: timeout) {
        try await condition() ? true : nil
    } != nil
}

/// Waits for a MainActor condition to become true with timeout (UI/MainActor isolated)
///
/// This function must be called from the MainActor context and the condition
/// is evaluated on the MainActor.
///
/// - Parameters:
///   - timeout: Maximum time to wait (defaults to 5 seconds).
///   - condition: The condition to check repeatedly.
/// - Returns: `true` if condition was met, `false` if timeout occurred.
@MainActor
@discardableResult
public func waitForMainActorCondition(
    timeout: TimeInterval = 5,
    condition: @escaping () -> Bool
) async -> Bool {
    let startTime = CFAbsoluteTimeGetCurrent()

    while !condition() {
        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        if elapsed >= timeout {
            return false
        }

        try? await Task.sleep(nanoseconds: 10_000_000)
    }

    return true
}

/// Waits for a publisher to emit a value that satisfies the given condition within a timeout.
///
/// - Parameters:
///   - publisher: The Combine publisher to observe.
///   - timeout: Maximum time to wait in seconds (defaults to 5.0).
///   - condition: The predicate that the emitted value must satisfy.
/// - Returns: `true` if a matching value was received, `false` if the timeout occurred first.
@MainActor
@discardableResult
public func waitForPublisherCondition<P: Publisher>(
    _ publisher: P,
    timeout: TimeInterval = 5.0,
    condition: @escaping @MainActor (P.Output) -> Bool
) async -> Bool where P.Failure == Never {
    let values = publisher.values
    
    let loopTask = Task { @MainActor in
        for await value in values {
            if condition(value) {
                return true
            }
        }
        return false
    }
    
    let timeoutTask = Task {
        try? await Task.sleep(for: .seconds(timeout))
        loopTask.cancel()
    }
    
    let result = await loopTask.value
    timeoutTask.cancel()
    return result
}

