
import Foundation

public protocol Mergeable {
    func merging(_ newValue: Self) -> Self

    func filled(from value: Self, mutate: (_ filled: inout Self, _ old: Self) -> Void) -> Self
}
