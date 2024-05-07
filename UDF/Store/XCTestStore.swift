
import UDFCore
import Foundation

public extension XCTestStore {
    func subscribe<M: Middleware<State>>(_ middlewareType: M.Type) async where M.State == State, M: EnvironmentMiddleware {
        await self.subscribe { store in
            middlewareType.init(store: store, environment: M.buildTestEnvironment(for: store))
        }
    }

    func subscribe<M: Middleware<State>>(_ middlewareType: M.Type, environment: M.Environment) async where M.State == State, M: EnvironmentMiddleware {
        await self.subscribe { store in
            middlewareType.init(store: store, environment: environment)
        }
    }
}

public extension XCTestStore {

    func subscribe(@MiddlewareBuilder<State> build: (_ store: any Store<State>) -> [MiddlewareWrapper<State>]) async {
        await self.subscribe(buildMiddlewares: { store in
            build(store).map { wrapper in
                wrapper.instance ?? middleware(store: store, type: wrapper.type)
            }
        })
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
        type.init(store: store, environment: type.buildTestEnvironment(for: store))
    }
}
