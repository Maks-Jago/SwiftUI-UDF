
import UDFCore
import Foundation

public protocol EnvironmentMiddleware {
    associatedtype Environment
    associatedtype State: AppReducer

    var environment: Environment! { get set }

    init(store: any Store, environment: Environment)
    init(store: any Store, environment: Environment, queue: DispatchQueue)

    static func buildLiveEnvironment(for store: any Store) -> Environment
    static func buildTestEnvironment(for store: any Store) -> Environment
}

public extension EnvironmentMiddleware where Environment == Void {

    static func buildLiveEnvironment(for store: any Store) -> Environment { () }
    static func buildTestEnvironment(for store: any Store) -> Environment { () }
}
