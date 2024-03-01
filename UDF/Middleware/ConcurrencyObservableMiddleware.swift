import Foundation

@available(*, deprecated, message: "use BaseObservableMiddleware instead")
public typealias BaseConcurrencyObservableMiddleware<State: AppReducer> = BaseMiddleware<State> & ObservableMiddleware & EnvironmentMiddleware
