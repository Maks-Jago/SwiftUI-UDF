
import Foundation

/// By Default, each `Reducer` can handle all `UpdateFormField` actions automatically!
/// You don't need to reduce it manually.
///

public protocol Form: Reducible {}

extension Form {
    mutating func reduceBasicFormFields(_ action: some Action) {
        switch action {
        case let action as Actions.UpdateFormField<Self>:
            action.assignToForm(&self)

        default:
            break
        }
    }
}
