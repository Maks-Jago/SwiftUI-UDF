
import Foundation

public struct DebugOnlyActionFilter: ActionFilter {
    public init() {}

    public func include(action: LoggingAction) -> Bool {
        #if DEBUG
            return true
        #else
            return false
        #endif
    }
}

public extension ActionFilter where Self == DebugOnlyActionFilter {
    static var debugOnly: ActionFilter { DebugOnlyActionFilter() }
}
