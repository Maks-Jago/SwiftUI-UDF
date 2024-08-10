
import Foundation
import SwiftUI

public struct AlertTextField: AlertAction {
    public var title: String
    public var text: Binding<String>
    public var textInputAutocapitalization: TextInputAutocapitalization? = nil
    public var submitLabel: SubmitLabel = .done

    @StateObject private var debouncer: UserInputDebouncer<String>

    public static func == (lhs: AlertTextField, rhs: AlertTextField) -> Bool {
        lhs.title == rhs.title
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }

    public init(title: String, text: Binding<String>) {
        self.title = title
        self.text = text

        self._debouncer = .init(wrappedValue: .init(defaultValue: text.wrappedValue))
    }

    public var body: some View {
        TextField(title, text: $debouncer.value)
            .textInputAutocapitalization(textInputAutocapitalization)
            .submitLabel(submitLabel)
            .onReceive(debouncer.$debouncedValue.dropFirst()) { value in
                self.text.wrappedValue = value
            }
            .onChange(of: text.wrappedValue) { newValue in
                if debouncer.value.isEmpty, !newValue.isEmpty {
                    debouncer.value = newValue
                }
            }
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
