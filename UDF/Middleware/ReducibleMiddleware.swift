
import UDFCore

public protocol ReducibleMiddleware: _ReducibleMiddleware {}

public typealias BaseReducibleMiddleware<State: AppReducer> = BaseMiddleware<State> & ReducibleMiddleware & EnvironmentMiddleware
