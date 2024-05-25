import Foundation

public protocol WrappedReducer: Reducing {
    var reducer: Reducing { get set }
}

extension WrappedReducer {
    mutating public func reduce(_ action: some Action) {
        _ = RuntimeReducing.reduce(action, reducer: &reducer)
    }
}
