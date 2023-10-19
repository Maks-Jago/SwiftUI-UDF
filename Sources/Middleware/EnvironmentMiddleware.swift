
import UDFCore
import Foundation

public protocol EnvironmentMiddleware {
    associatedtype Environment
    associatedtype State: AppReducer

    var environment: Environment! { get set }

    init(store: some Store<State>, environment: Environment)
    init(store: some Store<State>, environment: Environment, queue: DispatchQueue)

    static func buildLiveEnvironment(for store: some Store<State>) -> Environment
    static func buildTestEnvironment(for store: some Store<State>) -> Environment
}

public extension EnvironmentMiddleware where Environment == Void {

    static func buildLiveEnvironment(for store: some Store<State>) -> Environment { () }
    static func buildTestEnvironment(for store: some Store<State>) -> Environment { () }
}

public extension EnvironmentMiddleware {
    init(store: some Store<State>) {
        if ProcessInfo.processInfo.xcTest {
            self.init(store: store, environment: Self.buildTestEnvironment(for: store))
        } else {
            self.init(store: store, environment: Self.buildLiveEnvironment(for: store))
        }
    }

    init(store: some Store<State>, queue: DispatchQueue) {
        if ProcessInfo.processInfo.xcTest {
            self.init(store: store, environment: Self.buildTestEnvironment(for: store), queue: queue)
        } else {
            self.init(store: store, environment: Self.buildLiveEnvironment(for: store), queue: queue)
        }
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


