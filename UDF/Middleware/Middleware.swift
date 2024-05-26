
import Foundation

public protocol Middleware<State> {
    associatedtype State: AppReducer

    var store: any Store<State> { get }
    var queue: DispatchQueue { get set }

    init(store: some Store<State>)
    init(store: some Store<State>, queue: DispatchQueue)

    func status(for state: State) -> MiddlewareStatus

    @discardableResult
    func cancel<Id: Hashable>(by cancelation: Id) -> Bool
    func cancelAll()
}

public extension Middleware {
    init(store: some Store<State>) {
        let queueLabel = String(describing: Self.self)
        self.init(store: store, queue: DispatchQueue(label: queueLabel))
    }
}

public extension Middleware where Self: EnvironmentMiddleware {
    init(store: some Store<State>) {
        self.init(store: store, environment: Self.buildLiveEnvironment(for: store))
    }

    init(store: some Store<State>, queue: DispatchQueue) {
        self.init(store: store, environment: Self.buildLiveEnvironment(for: store), queue: queue)
    }

    init(store: some Store<State>, environment: Environment) {
        let queueLabel = String(describing: Self.self)
        self.init(store: store, environment: environment, queue: DispatchQueue(label: queueLabel))
    }

    init(store: some Store<State>, environment: Environment, queue: DispatchQueue) {
        self.init(store: store, queue: queue)
        self.environment = environment
    }
}

typealias MiddlewareWithEnvironment<State> = Middleware<State> & EnvironmentMiddleware<State>
