import Foundation

public typealias BaseConcurrencyReducibleMiddleware<State: AppReducer> = BaseMiddleware<State> & ReducibleMiddleware & EnvironmentMiddleware
