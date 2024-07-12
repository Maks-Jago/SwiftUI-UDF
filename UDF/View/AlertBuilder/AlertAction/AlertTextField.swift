
import Foundation
import SwiftUI

public struct AlertTextField: AlertAction, View {
    public var id: AnyHashable
    public var title: String
    public var text: Binding<String>

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
    }

    public init<ID: Hashable>(id: ID, title: String, text: Binding<String>) {
        self.id = AnyHashable(id)
        self.title = title
        self.text = text
    }

    public var body: some View {
        TextField(title, text: text)
            .id(id)
    }
}
