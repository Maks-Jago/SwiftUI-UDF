import Foundation

public typealias BaseConcurrencyObservableMiddleware<State: AppReducer> = BaseMiddleware<State> & ObservableMiddleware & EnvironmentMiddleware
