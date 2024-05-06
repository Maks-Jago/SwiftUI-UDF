
import Foundation
import SwiftUI

public struct AlertAction: Identifiable {
    public static func == (lhs: AlertAction, rhs: AlertAction) -> Bool {
        return lhs.id == rhs.id
    }

    public var id: AnyHashable
    public var title: String
    public var role: ButtonRole?
    public var action: () -> ()

    public init<ID: Hashable>(
        id: ID,
        title: String,
        action: @escaping () -> Void = {}
    ) {
        self.id = AnyHashable(id)
        self.title = title
        self.action = action
    }

    public init(
        title: String,
        action: @escaping () -> Void = {}
    ) {
        self.id = AnyHashable(UUID())
        self.title = title
        self.action = action
    }

    public func role(_ role: ButtonRole) -> Self {
        var newAction = self
        newAction.role = role
        return newAction
    }
}

public extension AlertAction {
    static func `default`(_ title: String, action: @escaping () -> Void = {}) -> AlertAction {
        AlertAction(title: title, action: action)
    }

    @available(*, deprecated, message: "use `default` with String instead of Text")
    static func `default`(_ text: Text, action: @escaping () -> Void = {}) -> AlertAction {
        AlertAction(title: text.content ?? "", action: action)
    }

    static func cancel(_ title: String, action: @escaping () -> Void = {}) -> AlertAction {
        AlertAction(title: title, action: action)
            .role(.cancel)
    }

    @available(*, deprecated, message: "use `cancel` with String instead of Text")
    static func cancel(_ text: Text, action: @escaping () -> Void = {}) -> AlertAction {
        AlertAction(title: text.content ?? "", action: action)
            .role(.cancel)
    }

    static func destructive(_ title: String, action: @escaping () -> Void = {}) -> AlertAction {
        AlertAction(title: title, action: action)
            .role(.destructive)
    }

    @available(*, deprecated, message: "use `destructive` with String instead of Text")
    static func destructive(_ text: Text, action: @escaping () -> Void = {}) -> AlertAction {
        AlertAction(title: text.content ?? "", action: action)
            .role(.destructive)
    }
}
