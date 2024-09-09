//
//  BindableReducerReference.swift
//
//
//  Created by Max Kuznetsov on 09.09.2024.
//

import Foundation

public final class BindableReducerReference<AppState: AppReducer, BindedContainer: BindableContainer, Reducer: Reducible>: ReducerReference<AppState, BindableReducer<BindedContainer, Reducer>> {

    var bindableId: BindedContainer.ID? = nil

    override init(reducer: BindableReducer<BindedContainer, Reducer>, dispatcher: @escaping (any Action) -> Void) {
        super.init(reducer: reducer, dispatcher: dispatcher)

        self.dispatcher = { [weak self] action in
            if let bindableId = self?.bindableId {
                dispatcher(action.bindable(containerType: BindedContainer.self, id: bindableId))
            } else {
                dispatcher(action)
            }
        }
    }

    public subscript(_ id: BindedContainer.ID) -> ReducerReference<AppState, Reducer> {
        self.bindableId = id
        return ReducerReference(reducer: reducer[id]!, dispatcher: dispatcher)
    }
}
