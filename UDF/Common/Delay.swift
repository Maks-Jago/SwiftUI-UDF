
import Foundation

struct Delay {
    private var value: TimeInterval
    private var fireDate: Date

    init(_ value: TimeInterval) {
        self.value = value
        self.fireDate = Date()
    }

    var delayTime: TimeInterval {
        let diff = Date().timeIntervalSince(fireDate)
        return max(0, value - diff)
    }
}
