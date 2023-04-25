
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

