
import Foundation

@resultBuilder
public enum AlertActionsBuilder {
    public static func buildEither(first component: [any AlertAction]) -> [any AlertAction] {
        component
    }

    public static func buildEither(second component: [any AlertAction]) -> [any AlertAction] {
        component
    }

    public static func buildOptional(_ component: [any AlertAction]?) -> [any AlertAction] {
        component ?? []
    }

    public static func buildExpression(_ expression: some AlertAction) -> [any AlertAction] {
        [expression]
    }

    public static func buildExpression(_ expression: ()) -> [any AlertAction] {
        []
    }

    static func buildLimitedAvailability(_ components: [any AlertAction]) -> [any AlertAction] {
        components
    }

    public static func buildBlock(_ components: [any AlertAction]...) -> [any AlertAction] {
        components.flatMap { $0 }
    }

    public static func buildArray(_ components: [[any AlertAction]]) -> [any AlertAction] {
        components.flatMap { $0 }
    }
}
