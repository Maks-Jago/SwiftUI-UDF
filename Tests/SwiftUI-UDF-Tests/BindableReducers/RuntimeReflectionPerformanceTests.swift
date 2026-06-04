@testable import UDF
import Testing
import Foundation
import SwiftUI
import Runtime

struct PerfComponent: Component {
    struct Props {}
    var props = Props()
    var body: some View { Text("perf") }
}

@Suite struct RuntimeReflectionPerformanceTests {
    
    @Test func testPerformanceAppState100() async {
        let store = EnvironmentStore(initial: AppState_100(), loggers: [])
        
        let clock = ContinuousClock()
        let duration = clock.measure {
            for _ in 0..<1000 {
                _ = ConnectedContainer<PerfComponent, AppState_100>.getBoundReducer(
                    with: store,
                    for: PerfContainer_100_99.self
                )
            }
        }
        
        let ms = Double(duration.components.attoseconds) / 1e15 + Double(duration.components.seconds) * 1000.0
        print("--- Benchmark Results (100 Entries) ---")
        print("Total Duration (1000 lookups): \(ms) ms")
        print("Average Duration per lookup: \(ms / 1000.0) ms")
    }

    @Test func testPerformanceAppState500() async {
        let store = EnvironmentStore(initial: AppState_500(), loggers: [])
        
        let clock = ContinuousClock()
        let duration = clock.measure {
            for _ in 0..<1000 {
                _ = ConnectedContainer<PerfComponent, AppState_500>.getBoundReducer(
                    with: store,
                    for: PerfContainer_500_499.self
                )
            }
        }
        
        let ms = Double(duration.components.attoseconds) / 1e15 + Double(duration.components.seconds) * 1000.0
        print("--- Benchmark Results (500 Entries) ---")
        print("Total Duration (1000 lookups): \(ms) ms")
        print("Average Duration per lookup: \(ms / 1000.0) ms")
    }

    @Test func testPerformanceAppState1000() async {
        let store = EnvironmentStore(initial: AppState_1000(), loggers: [])
        
        let clock = ContinuousClock()
        let duration = clock.measure {
            for _ in 0..<1000 {
                _ = ConnectedContainer<PerfComponent, AppState_1000>.getBoundReducer(
                    with: store,
                    for: PerfContainer_1000_999.self
                )
            }
        }
        
        let ms = Double(duration.components.attoseconds) / 1e15 + Double(duration.components.seconds) * 1000.0
        print("--- Benchmark Results (1000 Entries) ---")
        print("Total Duration (1000 lookups): \(ms) ms")
        print("Average Duration per lookup: \(ms / 1000.0) ms")
    }
}
