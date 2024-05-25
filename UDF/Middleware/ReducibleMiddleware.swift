
import Foundation

public protocol ReducibleMiddleware<State>: Middleware {
    func reduce(_ action: some Action, for state: State)
}

public typealias BaseReducibleMiddleware<State: AppReducer> = BaseMiddleware<State> & ReducibleMiddleware & EnvironmentMiddleware
