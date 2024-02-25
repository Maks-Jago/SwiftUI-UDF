
import Foundation
import Combine

public enum Effects {}

public protocol Effectable: PureEffect where Output == any Action, Failure == Never {}

// MARK: - Operators
public extension Effectable {

    func filterAction<A: Action>(_ isIncluded: @escaping (A) -> Bool) -> some Effectable  {
        Effects.Filter<A>(self, isIncluded)
    }

    func delay(duration: TimeInterval, queue: DispatchQueue) -> some Effectable {
        Effects.Delay(self, duration, queue: queue)
    }
}
