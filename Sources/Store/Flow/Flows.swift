
import Foundation

public enum Flows {}

public extension Flows {
    struct Id: Hashable, Codable {
        var value: String

        public init(value: String) {
            self.value = value
        }
    }
}

