//
//  Form+BasicFormFields.swift
//  
//
//  Created by Max Kuznetsov on 14.09.2021.
//

import Foundation

public extension Form {
    mutating func reduceBasicFormFields(_ action: AnyAction) {
        switch action.value {
        case let action as Actions.UpdateFormField<Self, String>:
            self[keyPath: action.keyPath] = action.value
        case let action as Actions.UpdateFormField<Self, String?>:
            self[keyPath: action.keyPath] = action.value
        case let action as Actions.UpdateFormField<Self, Date>:
            self[keyPath: action.keyPath] = action.value
        case let action as Actions.UpdateFormField<Self, Date?>:
            self[keyPath: action.keyPath] = action.value
        case let action as Actions.UpdateFormField<Self, Int>:
            self[keyPath: action.keyPath] = action.value
        case let action as Actions.UpdateFormField<Self, Int?>:
            self[keyPath: action.keyPath] = action.value
        case let action as Actions.UpdateFormField<Self, Double>:
            self[keyPath: action.keyPath] = action.value
        case let action as Actions.UpdateFormField<Self, Double?>:
            self[keyPath: action.keyPath] = action.value
        case let action as Actions.UpdateFormField<Self, Date>:
            self[keyPath: action.keyPath] = action.value
        case let action as Actions.UpdateFormField<Self, Date?>:
            self[keyPath: action.keyPath] = action.value
        case let action as Actions.UpdateFormField<Self, Bool>:
            self[keyPath: action.keyPath] = action.value
        case let action as Actions.UpdateFormField<Self, Bool?>:
            self[keyPath: action.keyPath] = action.value
        default:
            break
        }
    }
}
