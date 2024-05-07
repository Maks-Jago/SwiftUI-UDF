
import Foundation

@resultBuilder
public enum AlertActionsBuilder {
    public static func buildEither(first component: [AlertAction]) -> [AlertAction] {
        component
    }

    public static func buildEither(second component: [AlertAction]) -> [AlertAction] {
        component
    }

    public static func buildOptional(_ component: [AlertAction]?) -> [AlertAction] {
        component ?? []
    }

    public static func buildExpression(_ expression: AlertAction) -> [AlertAction] {
        [expression]
    }

    public static func buildExpression(_ expression: ()) -> [AlertAction] {
        []
    }

    static func buildLimitedAvailability(_ components: [AlertAction]) -> [AlertAction] {
        components
    }

    public static func buildBlock(_ components: [AlertAction]...) -> [AlertAction] {
        components.flatMap { $0 }
    }

    public static func buildArray(_ components: [[AlertAction]]) -> [AlertAction] {
        components.flatMap { $0 }
    }
}
