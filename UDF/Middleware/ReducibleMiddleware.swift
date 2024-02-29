
import UDFCore

public protocol ReducibleMiddleware: _ReducibleMiddleware {}

public typealias BaseReducibleMiddleware<State: AppReducer> = XMiddleware<State> & ReducibleMiddleware & EnvironmentMiddleware
