
import Foundation
import SwiftUI

public struct AlertTextField: AlertAction {
    public var title: String
    public var text: Binding<String>
    public var textInputAutocapitalization: TextInputAutocapitalization? = nil
    public var submitLabel: SubmitLabel = .done

    public static func == (lhs: AlertTextField, rhs: AlertTextField) -> Bool {
        lhs.title == rhs.title
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }

    public init(title: String, text: Binding<String>) {
        self.title = title
        self.text = text
    }

    public var body: some View {
        TextField(title, text: text)
            .textInputAutocapitalization(textInputAutocapitalization)
            .submitLabel(submitLabel)
            .id(title)
    }
}

// MARK: - Modifiers
public extension AlertTextField {

    func textInputAutocapitalization(_ textInputAutocapitalization: TextInputAutocapitalization?) -> Self {
        mutate { field in
            field.textInputAutocapitalization = textInputAutocapitalization
        }
    }

    func submitLabel(_ submitLabel: SubmitLabel) -> Self {
        mutate { field in
            field.submitLabel = submitLabel
        }
    }
}
