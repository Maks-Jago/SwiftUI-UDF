
import Foundation
import Combine

public extension Effects {

    struct Delay: Effectable {
        public var upstream: AnyPublisher<any Action, Never>

        public init<E: Effectable>(_ effect: E, _ duration: TimeInterval, queue: DispatchQueue) {
            upstream = effect
                .delay(for: .seconds(duration), scheduler: queue)
                .eraseToAnyPublisher()
        }
    }
}
