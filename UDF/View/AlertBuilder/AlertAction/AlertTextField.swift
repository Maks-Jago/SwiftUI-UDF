
import Foundation
import SwiftUI

public struct AlertTextField: AlertAction {
    public var id: AnyHashable
    public var title: String
    public var text: Binding<String>
    public var textInputAutocapitalization: TextInputAutocapitalization? = nil
    public var submitLabel: SubmitLabel = .done

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
    }

    public init<ID: Hashable>(id: ID, title: String, text: Binding<String>) {
        self.id = AnyHashable(id)
        self.title = title
        self.text = text
    }

    public init(
        title: String,
        text: Binding<String>
    ) {
        self.init(id: UUID(), title: title, text: text)
    }

    public var body: some View {
        TextField(title, text: text)
            .textInputAutocapitalization(textInputAutocapitalization)
            .submitLabel(submitLabel)
            .id(id)
    }
}

// MARK: - Modifiers
public extension AlertTextField {

    mutating func textInputAutocapitalization(_ textInputAutocapitalization: TextInputAutocapitalization?) -> Self {
        mutate { field in
            field.textInputAutocapitalization = textInputAutocapitalization
        }
    }

    mutating func submitLabel(_ submitLabel: SubmitLabel) -> Self {
        mutate { field in
            field.submitLabel = submitLabel
        }
    }
}
