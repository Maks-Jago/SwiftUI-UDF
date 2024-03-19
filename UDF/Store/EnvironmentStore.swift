
import UDFCore
import Foundation

// MARK: - Subscribe Methods
public extension EnvironmentStore {

    func subscribe<M: Middleware>(_ middlewareType: M.Type) async where M.State == State, M: EnvironmentMiddleware {
        if ProcessInfo.processInfo.xcTest {
            await self.subscribe { store in
                middlewareType.init(store: store, environment: M.buildTestEnvironment(for: store))
            }
        } else {
            await self.subscribe { store in
                middlewareType.init(store: store, environment: M.buildLiveEnvironment(for: store))
            }
        }
    }

    func subscribe<M: Middleware>(_ middlewareType: M.Type) async where M.State == State {
        await self.subscribe { store in
            middlewareType.init(store: store)
        }
    }

    func subscribe<M: Middleware>(_ middlewareType: M.Type, environment: M.Environment) async where M.State == State, M: EnvironmentMiddleware {
        await self.subscribe { store in
            middlewareType.init(store: store, environment: environment)
        }
    }

    func subscribe<M: Middleware>(_ middlewareType: M.Type, on queue: DispatchQueue) async where M.State == State, M: EnvironmentMiddleware {
        if ProcessInfo.processInfo.xcTest {
            await self.subscribe { store in
                middlewareType.init(store: store, environment: M.buildTestEnvironment(for: store), queue: queue)
            }
        } else {
            await self.subscribe { store in
                middlewareType.init(store: store, environment: M.buildLiveEnvironment(for: store), queue: queue)
            }
        }
    }

    func subscribe<M: Middleware>(_ middlewareType: M.Type, on queue: DispatchQueue) async where M.State == State {
        await self.subscribe { store in
            middlewareType.init(store: store, queue: queue)
        }
    }

    func subscribe<M: Middleware>(_ middlewareType: M.Type, environment: M.Environment, on queue: DispatchQueue) async where M.State == State, M: EnvironmentMiddleware {
        await self.subscribe { store in
            middlewareType.init(store: store, environment: environment, queue: queue)
        }
    }

    func subscribeAsync<M>(_ middlewareType: M.Type, onSubscribe: @escaping () -> Void = {}) where M : Middleware, M: EnvironmentMiddleware, State == M.State {
        Task(priority: .userInitiated) {
            await subscribe(middlewareType)
            onSubscribe()
        }
    }

    func subscribeAsync<M>(_ middlewareType: M.Type, onSubscribe: @escaping () -> Void = {}) where M : Middleware, State == M.State {
        Task(priority: .userInitiated) {
            await subscribe(middlewareType)
            onSubscribe()
        }
    }

    func subscribeAsync<M>(_ middlewareType: M.Type, environment: M.Environment, onSubscribe: @escaping () -> Void = {}) where M: Middleware, State == M.State, M: EnvironmentMiddleware {
        Task(priority: .userInitiated) {
            await subscribe(middlewareType, environment: environment)
            onSubscribe()
        }
    }

    func subscribeAsync<M>(_ middlewareType: M.Type, on queue: DispatchQueue, onSubscribe: @escaping () -> Void = {}) where M: Middleware, State == M.State, M: EnvironmentMiddleware {
        Task(priority: .userInitiated) {
            await subscribe(middlewareType, on: queue)
            onSubscribe()
        }
    }

    func subscribeAsync<M>(_ middlewareType: M.Type, on queue: DispatchQueue, onSubscribe: @escaping () -> Void = {}) where M: Middleware, State == M.State {
        Task(priority: .userInitiated) {
            await subscribe(middlewareType, on: queue)
            onSubscribe()
        }
    }

    func subscribeAsync<M>(_ middlewareType: M.Type, environment: M.Environment, on queue: DispatchQueue, onSubscribe: @escaping () -> Void = {}) where M: Middleware, State == M.State, M: EnvironmentMiddleware {
        Task(priority: .userInitiated) {
            await subscribe(middlewareType, environment: environment, on: queue)
            onSubscribe()
        }
    }
}
