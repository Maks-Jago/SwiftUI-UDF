
import Foundation

public protocol ObservableMiddleware<State>: Middleware {
    @ScopeBuilder func scope(for state: State) -> Scope
    func observe(state: State)
}

public typealias BaseObservableMiddleware<State: AppReducer> = BaseMiddleware<State> & ObservableMiddleware & EnvironmentMiddleware
