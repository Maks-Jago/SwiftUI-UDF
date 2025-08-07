import Testing
import Foundation
import UDFSwiftTesting

@Suite struct PerformanceCalibrationTest {
    @Test func performanceCalibrationDemo() async {
        printPerformanceInfo()
        
        let baseTimeout: TimeInterval = 0.3
        let adjustedTimeout = PerformanceCalibrator.shared.adjustedTimeout(baseTimeout)
    }
}
