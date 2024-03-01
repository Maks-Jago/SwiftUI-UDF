import Foundation

@available(*, deprecated, message: "use BaseReducibleMiddleware instead")
public typealias BaseConcurrencyReducibleMiddleware<State: AppReducer> = BaseMiddleware<State> & ReducibleMiddleware & EnvironmentMiddleware
