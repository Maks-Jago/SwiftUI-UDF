//
//  ReducerReference.swift
//  
//
//  Created by Max Kuznetsov on 13.09.2021.
//

import Foundation
import SwiftUI

@dynamicMemberLookup
public final class ReducerReference<AppState: AppReducer, Reducer: Reducible> {
    private var reducer: Reducer

    private unowned var store: Optional<any Store<AppState>>

    public var projectedValue: Reducer {
        get { self.reducer }
        set { self.reducer = newValue }
    }

    init(reducer: Reducer, store: Optional<any Store<AppState>>) {
        self.reducer = reducer
        self.store = store
    }

    public subscript<R: Reducible>(dynamicMember keyPath: KeyPath<Reducer, R>) -> ReducerReference<AppState, R> {
        .init(reducer: reducer[keyPath: keyPath], store: store)
    }

    public subscript<R: Reducible>(dynamicMember keyPath: KeyPath<Reducer, R>) -> ReducerScope<R> {
        ReducerScope(reducer: reducer[keyPath: keyPath])
    }
}

extension ReducerReference where Reducer: Form {

    public subscript<T: Equatable>(dynamicMember keyPath: WritableKeyPath<Reducer, T>) -> Binding<T> {
        Binding(
            get: { self.reducer[keyPath: keyPath] },
            set: { [store] value in
                store?.dispatch(Actions.UpdateFormField(keyPath: keyPath, value: value), priority: .userInteractive)
            }
        )
    }
}
