
import Foundation

final class Weak {
    weak var value: AnyObject?
    init (value: AnyObject) {
        self.value = value
    }
}

extension Array where Element: Weak {
    mutating func reap () {
        self = self.filter { $0.value != nil }
    }
}
