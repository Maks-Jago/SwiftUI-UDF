
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
    
    @available(iOS 16.0.0, macOS 13.0.0, *)
    func subscribeAsync(@MiddlewareBuilder<State> _ builder: (_ store: any Store<State>) -> [MiddlewareWrapper<State>]) async {
        if ProcessInfo.processInfo.xcTest {
            await self.subscribe { store in
                builder(store).map {
                    $0.instance ?? middleware(store: store, type: $0.type, isInTestEnvironment: true)
                }
            }
        } else {
            await self.subscribe { store in
                builder(store).map {
                    $0.instance ?? middleware(store: store, type: $0.type)
                }
            }
        }
    }
    
    func middleware<M: Middleware<State>>(store: any Store<State>, type: M.Type, isInTestEnvironment: Bool = false) -> M where M.State == State, M: EnvironmentMiddleware {
        if isInTestEnvironment {
            type.init(store: store, environment: type.buildTestEnvironment(for: store))
        } else {
            type.init(store: store, environment: type.buildLiveEnvironment(for: store))
        }
    }
}
