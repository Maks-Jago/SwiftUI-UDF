
import Testing
import Foundation

/// Automatic performance calibrator that adapts timeouts to hardware performance
public struct PerformanceCalibrator: Sendable {
    public static let shared = PerformanceCalibrator()

    private let performanceMultiplier: Double

    private init() {
        // Benchmark system performance with CPU-intensive task
        let start = CFAbsoluteTimeGetCurrent()

        // Simple benchmark: mathematical operations
        var sum = 0
        for i in 0..<100_000 {
            sum += i * i % 1000
        }

        let elapsed = CFAbsoluteTimeGetCurrent() - start

        // Baseline: Typical MacBook performance (~0.01 seconds)
        let baseline = 0.01

        // Calculate actual performance relative to baseline
        let rawMultiplier = elapsed / baseline

        // Scale based on actual performance: fast hardware gets 1.0x, slow hardware gets up to 3.0x
        performanceMultiplier = min(max(rawMultiplier, 1.0), 3.0)

        // Prevent compiler optimization
        _ = sum
    }

    /// Adjusts timeout based on system performance
    public func adjustedTimeout(_ baseTimeout: TimeInterval) -> TimeInterval {
        // Check for manual override via environment variable
        if let multiplierString = ProcessInfo.processInfo.environment["TEST_TIMEOUT_MULTIPLIER"],
           let manualMultiplier = Double(multiplierString) {
            return baseTimeout * manualMultiplier
        }

        return baseTimeout * performanceMultiplier
    }
}

public func fulfill(description: Comment, sleep: TimeInterval) async {
    let adjustedSleep = PerformanceCalibrator.shared.adjustedTimeout(sleep)
    let nanoseconds = UInt64(adjustedSleep * 1_000_000_000)
    try? await Task.sleep(nanoseconds: nanoseconds)
}

/// Precise fulfill function without performance calibration (for delay-sensitive tests)
public func fulfillPrecise(description: Comment, sleep: TimeInterval) async {
    let nanoseconds = UInt64(sleep * 1_000_000_000)
    try? await Task.sleep(nanoseconds: nanoseconds)
}

/// Waits for a condition to become true indefinitely
public func waitForCondition(condition: @escaping () -> Bool) async {
    while !condition() {
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
    }
}

/// Debug function to check performance calibration
public func printPerformanceInfo() {
    let calibrator = PerformanceCalibrator.shared
    let exampleTimeout = 0.3
    let adjustedTimeout = calibrator.adjustedTimeout(exampleTimeout)

    // Show actual benchmark results
    let start = CFAbsoluteTimeGetCurrent()
    var sum = 0
    for i in 0..<100_000 {
        sum += i * i % 1000
    }
    let elapsed = CFAbsoluteTimeGetCurrent() - start
    _ = sum

    print("🔧 Performance Calibration Info:")
    print("   Benchmark time: \(String(format: "%.4f", elapsed))s")
    print("   Baseline: 0.01s")
    print("   Raw multiplier: \(String(format: "%.2f", elapsed / 0.01))x")
    print("   Example: \(exampleTimeout)s → \(String(format: "%.3f", adjustedTimeout))s")
}
