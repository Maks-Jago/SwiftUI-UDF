//
//  ReducerReference.swift
//  
//
//  Created by Max Kuznetsov on 13.09.2021.
//

import Foundation
import SwiftUI

@dynamicMemberLookup
public class ReducerReference<AppState: AppReducer, Reducer: Reducible> {
    private(set) var reducer: Reducer

    var dispatcher: (any Action) -> Void

    public var projectedValue: Reducer {
        get { self.reducer }
        set { self.reducer = newValue }
    }

    init(reducer: Reducer, dispatcher: @escaping (any Action) -> Void) {
        self.reducer = reducer
        self.dispatcher = dispatcher
    }

    public subscript<R: Reducible>(dynamicMember keyPath: KeyPath<Reducer, R>) -> ReducerReference<AppState, R> {
        .init(reducer: reducer[keyPath: keyPath], dispatcher: dispatcher)
    }

    public subscript<C: BindableContainer, R: Reducible>(dynamicMember keyPath: WritableKeyPath<Reducer, BindableReducer<C, R>>) -> BindableReducerReference<AppState, C, R> {
        BindableReducerReference(reducer: reducer[keyPath: keyPath], dispatcher: dispatcher)
    }

    public subscript<R: Reducible>(dynamicMember keyPath: KeyPath<Reducer, R>) -> ReducerScope<R> {
        ReducerScope(reducer: reducer[keyPath: keyPath])
    }
}

extension ReducerReference where Reducer: Form {

    public subscript<T: Equatable>(dynamicMember keyPath: WritableKeyPath<Reducer, T>) -> Binding<T> {
        Binding(
            get: { self.reducer[keyPath: keyPath] },
            set: { value in
                self.dispatcher(Actions.UpdateFormField(keyPath: keyPath, value: value))
            }
        )
    }
}
