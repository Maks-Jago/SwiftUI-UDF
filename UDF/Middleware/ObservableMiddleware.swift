
import UDFCore

public protocol ObservableMiddleware: _ObservableMiddleware {}

public typealias BaseObservableMiddleware<State: AppReducer> = BaseMiddleware<State> & ObservableMiddleware & EnvironmentMiddleware & MiddlewareWrapperProtocol
