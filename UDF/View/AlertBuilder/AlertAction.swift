
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

    func role(_ role: ButtonRole) -> Self {
        var newAction = self
        newAction.role = role
        return self
    }
}
