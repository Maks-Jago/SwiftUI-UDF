
import UDFCore
import Foundation

public extension Middleware {
    init(store: any Store) {
        let queueLabel = String(describing: Self.self)
        self.init(store: store, queue: DispatchQueue(label: queueLabel))
    }
}

public extension Middleware where Self: EnvironmentMiddleware {
    init(store: any Store) {
        self.init(store: store, environment: Self.buildLiveEnvironment(for: store))
    }

    init(store: any Store, queue: DispatchQueue) {
        self.init(store: store, environment: Self.buildLiveEnvironment(for: store), queue: queue)
    }

    init(store: any Store, environment: Environment) {
        let queueLabel = String(describing: Self.self)
        self.init(store: store, environment: environment, queue: DispatchQueue(label: queueLabel))
    }

    init(store: any Store, environment: Environment, queue: DispatchQueue) {
        self.init(store: store, queue: queue)
        self.environment = environment
    }
}
