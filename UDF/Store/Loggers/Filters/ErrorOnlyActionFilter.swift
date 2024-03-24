
import Foundation

public struct ErrorOnlyActionFilter: ActionFilter {
    public func include(action: LoggingAction) -> Bool {
        action.value is Actions.Error
    }
}

public extension ActionFilter where Self == ErrorOnlyActionFilter {
    static var errorOnly: ActionFilter { ErrorOnlyActionFilter() }
}
