
import UDFCore

public protocol ObservableMiddleware: _ObservableMiddleware {}

public typealias BaseObservableMiddleware<State: AppReducer> = XMiddleware<State> & ObservableMiddleware & EnvironmentMiddleware
