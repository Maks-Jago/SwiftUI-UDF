
import UDFCore
import Foundation

public extension XCTestStore {
    func subscribe<M: Middleware>(_ middlewareType: M.Type) async where M.State == State, M: EnvironmentMiddleware {
        await self.subscribe { store in
            middlewareType.init(store: store, environment: M.buildTestEnvironment(for: store))
        }
    }

    func subscribe<M: Middleware>(_ middlewareType: M.Type, environment: M.Environment) async where M.State == State, M: EnvironmentMiddleware {
        await self.subscribe { store in
            middlewareType.init(store: store, environment: environment)
        }
    }
}
