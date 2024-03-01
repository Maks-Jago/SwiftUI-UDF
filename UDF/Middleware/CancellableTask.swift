import Combine

public protocol CancellableTask {
   func cancel()
}

extension AnyCancellable: CancellableTask {}
extension Task<Void, Never>: CancellableTask {}
