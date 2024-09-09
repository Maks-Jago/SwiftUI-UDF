//
//  BindableReducerReference.swift
//
//
//  Created by Max Kuznetsov on 09.09.2024.
//

import Foundation

public final class BindableReducerReference<AppState: AppReducer, BindedContainer: BindableContainer, Reducer: Reducible>: ReducerReference<AppState, BindableReducer<BindedContainer, Reducer>> {

    override init(reducer: BindableReducer<BindedContainer, Reducer>, dispatcher: @escaping (any Action) -> Void) {
        super.init(reducer: reducer, dispatcher: dispatcher)
    }

    public subscript(_ id: BindedContainer.ID) -> ReducerReference<AppState, Reducer> {
        ReducerReference(reducer: reducer[id] ?? .init()) { [dispatcher] action in
            dispatcher(action.binded(to: BindedContainer.self, by: id))
        }
    }
}
