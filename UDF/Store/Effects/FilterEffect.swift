
import Foundation
import Combine

public extension Effects {

    struct Filter<A: Action>: Effectable {
        public var upstream: AnyPublisher<any Action, Never>

        public init<E: Effectable>(_ effect: E, _ isInclude: @escaping (A) -> Bool) {
            upstream = Publishers.Filter(upstream: effect) { anyAction -> Bool in
                guard let action = anyAction as? A else {
                    preconditionFailure("anyAction.value type must be as A type")
                }

                return isInclude(action)
            }
            .eraseToAnyPublisher()
        }
    }
}
