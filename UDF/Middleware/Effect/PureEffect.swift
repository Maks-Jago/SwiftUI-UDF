
import Foundation
import Combine

public protocol PureEffect<Output>: Publisher {
    var upstream: AnyPublisher<Output, Failure> { get }
}

public extension PureEffect {
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        self.upstream.subscribe(subscriber)
    }

    func eraseToEffectable(output: @escaping (Output) -> any Action, failure: @escaping (Failure) -> any Action) -> AnyPublisher<any Action, Never> {
        self
            .map(output)
            .catch { error in
                Just(failure(error))
            }
            .eraseToAnyPublisher()
    }
}

public extension PureEffect where Failure == Never {
    func eraseToEffectable(output: @escaping (Output) -> any Action) -> AnyPublisher<any Action, Never> {
        self
            .map(output)
            .eraseToAnyPublisher()
    }
}

extension AnyPublisher: PureEffect where Output == any Action, Failure == Never {
    public var upstream: AnyPublisher<any Action, Never> {
        self
    }
}

public protocol ErasableToEffect {
    var asEffectable: AnyPublisher<any Action, Never> { get }
}
