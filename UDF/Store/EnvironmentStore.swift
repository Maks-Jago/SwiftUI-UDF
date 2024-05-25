
import Foundation
import SwiftUI
@preconcurrency import Combine

public final class EnvironmentStore<State: AppReducer> {

    @SourceOfTruth public private(set) var state: State

    private var store: InternalStore<State>
    private var cancelation: Cancellable? = nil
    private let subscribersCoordinator: SubscribersCoordinator<StateSubscriber<State>> = SubscribersCoordinator()
    private let storeQueue: DispatchQueue = .init(label: "EnvironmentStore")

    public init(initial state: State, loggers: [ActionLogger]) throws {
        var mutableState = state
        mutableState.initialSetup()

        let store = try InternalStore(initial: mutableState, loggers: loggers)
        self.store = store
        self._state = .init(wrappedValue: mutableState, store: store)

        sinkSubject()
        GlobalValue.set(self)
    }

    public convenience init(initial state: State, logger: ActionLogger) throws {
        try self.init(initial: state, loggers: [logger])
    }

    public func dispatch(
        _ action: some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) {
        storeQueue.async { [weak self] in
            self?.store.dispatch(action, priority: priority, fileName: fileName, functionName: functionName, lineNumber: lineNumber)
        }
    }

    public func bind(
        _ action: some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> Command {
        return {
            self.dispatch(
                action,
                priority: priority,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }

    public func bind<T>(
        _ action: @escaping (T) -> some Action,
        priority: ActionPriority = .default,
        fileName: String = #file,
        functionName: String = #function,
        lineNumber: Int = #line
    ) -> CommandWith<T> {
        return { value in
            self.dispatch(
                action(value),
                priority: priority,
                fileName: fileName,
                functionName: functionName,
                lineNumber: lineNumber
            )
        }
    }

    private func sinkSubject() {
        self.cancelation = store.subject
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] (newState, oldState, animation) in
                self.state = newState

                Task(priority: .high) {
                    let subscribers = await subscribersCoordinator.allSubscibers()
                    await MainActor.run {
                        subscribers.forEach { subscriber in
                            subscriber(oldState, newState, animation)
                        }
                    }
                }
            }
    }
}

// MARK: - State Subscribers
extension EnvironmentStore {
    func add(statePublisher: @escaping StateSubscriber<State>) -> String {
        let key = UUID().uuidString

        Task(priority: .high) {
            await subscribersCoordinator.add(subscriber: statePublisher, for: key)
        }

        return key
    }

    func removePublisher(forKey key: String) {
        Task(priority: .high) {
            await subscribersCoordinator.removeSubscriber(forKey: key)
        }
    }
}

//MARK: - Global
extension EnvironmentStore {
    class var global: EnvironmentStore<State> {
        GlobalValue.value(for: EnvironmentStore<State>.self)
    }
}

// MARK: - Subscribe Methods
public extension EnvironmentStore {

    func subscribe<M: Middleware<State>>(_ middlewareType: M.Type) async where M.State == State, M: EnvironmentMiddleware {
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

    func subscribe<M: Middleware<State>>(_ middlewareType: M.Type) async where M.State == State {
        await self.subscribe { store in
            middlewareType.init(store: store)
        }
    }

    func subscribe<M: Middleware<State>>(_ middlewareType: M.Type, environment: M.Environment) async where M.State == State, M: EnvironmentMiddleware {
        await self.subscribe { store in
            middlewareType.init(store: store, environment: environment)
        }
    }

    func subscribe<M: Middleware<State>>(_ middlewareType: M.Type, on queue: DispatchQueue) async where M.State == State, M: EnvironmentMiddleware {
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

    func subscribe<M: Middleware<State>>(_ middlewareType: M.Type, on queue: DispatchQueue) async where M.State == State {
        await self.subscribe { store in
            middlewareType.init(store: store, queue: queue)
        }
    }

    func subscribe<M: Middleware<State>>(_ middlewareType: M.Type, environment: M.Environment, on queue: DispatchQueue) async where M.State == State, M: EnvironmentMiddleware {
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

    func subscribeAsync(@MiddlewareBuilder<State> build: @escaping (_ store: any Store<State>) -> [MiddlewareWrapper<State>]) {
        Task(priority: .userInitiated) {
            await self.store.subscribe(
                build(store).map { wrapper in
                    wrapper.instance ?? self.middleware(store: store, type: wrapper.type)
                }
            )
        }
    }

    func subscribe(@MiddlewareBuilder<State> build: @escaping (_ store: any Store<State>) -> [MiddlewareWrapper<State>]) async {
        await self.store.subscribe(
            build(store).map { wrapper in
                wrapper.instance ?? self.middleware(store: store, type: wrapper.type)
            }
        )
    }

    private func middleware<M: Middleware<State>>(store: any Store<State>, type: M.Type) -> any Middleware<State> where M.State == State {
        switch type {
        case let envMiddlewareType as any MiddlewareWithEnvironment<State>.Type:
            envMiddleware(store: store, type: envMiddlewareType)
        default:
            type.init(store: store)
        }
    }

    private func envMiddleware<M: MiddlewareWithEnvironment<State>>(store: any Store<State>, type: M.Type) -> any Middleware<State> where M.State == State {
        if ProcessInfo.processInfo.xcTest {
            type.init(store: store, environment: type.buildTestEnvironment(for: store))
        } else {
            type.init(store: store, environment: type.buildLiveEnvironment(for: store))
        }
    }
}
